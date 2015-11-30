#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(param escape unescape);

use lib '.', '..', "../..","../comp", '../RegoForm', "../dashboard", "../RegoFormBuilder",'../PaymentSplit', "../user", "../Clearances";

use Defs;
use DBI;
use Utils;
use AdminPageGen;
use FormHelpers;
use UserObj;
use EntityObj;
use PlayerPassport;
use SystemConfig;

main();

sub main  {
  my $target='kickpassport.cgi';
  my $returnstr='';
  my $action=param('a') || '';
  my $natnum= param('natnum') || 0;
  my $db=connectDB();
     my %Data = ();
    $Data{'db'} = $db;
    $Data{'Realm'} = 1;
    $Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);


  if($action eq "pp")  {
     $returnstr=rebuildPlayerPassport(\%Data, $target, $natnum);
  }
  else  {
    $returnstr= searchpage($db, $target);
  }
  $returnstr .= qq[<p><a href = "kickpassport.cgi">Return to Passport Admin</a></p>];
  print_adminpageGen($returnstr, "", "");
}


sub searchpage {
  my ($db, $target)=@_;

  my $body = qq[
    <h1>Rebuild a Persons Player Passport - Admin</h1>
  <br>
    <form action="$target" method="POST">
      <input type="hidden" name="a" value="pp">
       National Number: <input type="text" name="natnum" size="20"><br>
       <input type="submit" name="submit" value="R E B U I L D">
    </form>
    ];
  return $body;
}

sub rebuildPlayerPassport {
  my ($Data, $target, $natnum) = @_;
  my $statement="
    SELECT
        intPersonID
    FROM
        tblPerson
    WHERE
        strNationalNum = ?
    LIMIT 1
  ";
  my $query = $Data->{'db'}->prepare($statement);
  $query->execute($natnum);
    my $personID = $query->fetchrow_array() || 0;
    if ($personID)  {
        savePlayerPassport($Data, $personID);
        return "Passport rebuilt";
    }
    else    {
        return "No Person Found";
    }
}
1;
