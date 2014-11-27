#!/usr/bin/perl 
use CGI qw(param escape unescape);

use lib '.','..',"comp",'PaymentSplit','RegoFormBuilder';

use Reg_common;
use PageMain;
use Defs;
use Utils;
use SystemConfig;
use ConfigOptions;
use Lang;
use TTTemplate;
use Payments;
use Data::Dumper;

use strict;

print "Content-type: text/html \n\n";

# get the necessary parameters 

my $client = param('client') || '';
my $regoID = param('rID') || 0;
my $personID = param('pID') || 0;

my $db=connectDB();
my %Data=();
$Data{'db'}=$db;

my %clientValues = getClient($client);
$Data{'clientValues'} = \%clientValues;
( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";

my $sql = qq[SELECT strLocalName, intTransactionID, strLocalName, strName, CONCAT(strLocalFirstname, ' ', strLocalSurname) AS name, strInvoiceNumber, curAmount, intQty FROM tblTransactions INNER JOIN tblProducts ON tblTransactions.intProductID = tblProducts.intProductID INNER JOIN tblInvoice ON tblTransactions.intInvoiceID = tblInvoice.intInvoiceID INNER JOIN tblPersonRegistration_$Data{'Realm'} ON tblTransactions.intPersonRegistrationID = tblPersonRegistration_$Data{'Realm'}.intPersonRegistrationID INNER JOIN tblEntity ON  tblPersonRegistration_$Data{'Realm'}.intEntityID = tblEntity.intEntityID INNER JOIN tblPerson ON tblTransactions.intID = tblPerson.intPersonID WHERE tblTransactions.intPersonRegistrationID = ? AND tblTransactions.intID = ?];

my $sth = $db->prepare($sql); 

$sth->execute($regoID,$personID);

my @transactions = ();
my $name = '';
my $total = 0;
my $invoiceNumber = '';
my $entityName = '';
while(my $dref = $sth->fetchrow_hashref()){
	$name = $dref->{'name'};
	$entityName = $dref->{'strLocalName'},
	$invoiceNumber = $dref->{'strInvoiceNumber'},
	$total = $total + $dref->{'curAmount'},
	push @transactions,$dref;
}
$total = sprintf "%.2f",$total;
my %content = (
	transactions => \@transactions,
	entityName => $entityName,
	person => $name,
	invoicenum => $invoiceNumber,
	amount => $total,
);
my $body = runTemplate(\%Data,\%content,'payment/invoicetemplate.templ');
print $body;


