#!/usr/bin/perl -w

#
# web/admin/admin_product.cgi 2014-11-14
#

use lib "../..","..",".";
use DBI;
use CGI qw(param unescape escape popup_menu);
use Defs;
use Utils;
use strict;
use AdminPageGen;
use AdminCommon;
use EventAdmin;
use FormHelpers;
use HTMLForm;
use TTTemplate;

use Data::Dumper;
use feature qw(say);
main();

sub main	{
# Variables coming in
    my $header = "Content-type: text/html\n\n";
	my $body = "";
	my $title = "$Defs::sitename Association Administration";
	my $action = param('action') || '';
	my $event_name_IN = param('event_name') || '';
	my $eventID=param('eID') || 0;
	my $subBody='';
	my $menu='';
	my $activetab=0;
	my $target="admin_product.cgi";
	my $error='';
	my $db=connectDB();
    if ($action eq "add") {
	    #print $header;
        my %Data = ();
		$Data{'lang'} = '';
		my $meta = {};
		$meta->{'realms'} = getRealms($db, '', '&nbsp;');
	    $meta->{'gendedropdown'} = popup_menu(
					-name => 'gender',
					-class => 'inputbox2',
					-values => [0, $Defs::GENDER_MALE, $Defs::GENDER_FEMALE],
					-labels => {
						0 => 'Any',
						$Defs::GENDER_MALE => $Defs::genderInfo{$Defs::GENDER_MALE},
						$Defs::GENDER_FEMALE => $Defs::genderInfo{$Defs::GENDER_FEMALE},
					},
					-default => $Defs::genderInfo{$Defs::GENDER_NONE} || 0,
				);
		$meta->{'typedropdown'} = popup_menu(
					-name => 'productfamily',
					-class => 'inputbox2',
					-values => ['', 'insurance', 'licence', 'transfer','passes'],
					-labels => {
						'' => 'Any',
						'insurance' => 'Insurance', 'licence' => 'Licence',
						'transfer' => 'Transfer Fee', 'passes' => 'Playing Pass',
					},
					-default => '',
				);
		
		$meta->{'allowmultidropdown'} = popup_menu(
					-name => 'allowmulti',
					-class => 'inputbox2',
					-values => ['0', '1'],
					-labels => {'0' => 'One', '1' => 'Multiple',},
					-default => '0',
				);
		
		$meta->{'perioddropdown'} = getNationalPeriod($db, '', '&nbsp;');
	
        ($subBody,$menu) =  runTemplate(\%Data, $meta, 'admin/product/product_form.templ');
        #($subBody,$menu) = show_add_product_form($db, $target);
    }	
	elsif($action eq "addproduct" || $action eq "editproduct")	{
		my $q = new CGI;
	    my @names = $q->param;
		#print "Content-type: text/html\n\n";
		#foreach my $name (@names) {
		#  say $name.'='.$q->param($name)."<br/>";
		#}
		($subBody,$menu)=handle_product($db, $action);
	}
    elsif($action eq "edit") {
		($subBody,$menu)=show_edit_product_form($db,$action,$target);
	}
	
    elsif( $action eq "list") {
        ($subBody,$menu) = list_products($db);
   }
	else	{
		$subBody=list_products($db);
	}
	$body=qq[<br> <div align="center"><a href="$target?action=add">Create New</a> | <a href="$target?action=list">Product List</a> | <a href="$target">Search</a> </div> $subBody] if $subBody;
	disconnectDB($db) if $db;
	
	
	print_adminpageGen($body, "Admin Products", "");
}


sub display_find_fields {
	my($target, $db)=@_;
  my$realms = getRealms($db);
	my $body = qq[
  <br>
	<form action="$target" method="post">
	<input type="hidden" name="action" value="list">
	<table style="margin-left:auto;margin-right:auto;">
	<tr>
		<td class="formbg fieldlabel">Name:&nbsp;<input type="text" name="event_name" size="50"></td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Realm:&nbsp;$realms</td>
	</tr>
	<tr>
		<td class="formbg"><input type="submit" name="submit" value="S E A R C H"></td>
	</tr>
	</table>
	</form>
	];
  #return $body;
}

sub getRealms {
  my ($db, $value, $init) = @_;
  my $st= qq[ 
    SELECT intRealmID, strRealmName 
    FROM tblRealms 
    ORDER BY strRealmName
  ];
  return getDBdrop_down('realmID',$db,$st,$value,$init) || '';
}

sub getNationalPeriod {
  my ($db, $value, $init) = @_;
  my $st= qq[ 
    SELECT intNationalPeriodID, strNationalPeriodName 
    FROM tblNationalPeriod ORDER BY intNationalPeriodID DESC
  ];
  return getDBdrop_down('period',$db,$st,$value, $init) || '';
}

sub getEntity {
    my ($db, $realmid) = @_;
	my $stmt=qq[
	SELECT intEntityID FROM tblEntity
	WHERE intRealmID = $realmid
	LIMIT 1
	];
	return $db->selectrow_array($stmt);
}

sub handle_product {
  my ($db,$action) = @_;
  
  my @values = ();
  my $productName = param('strname') || '';
  my $realmID = param('realmID') || '';
  #my $defaultAmount = param('defaultamount') || '0';
  #my $strGSTText = param('gsttext') || '';
  #my $productType = param('productfamily') || '';
  #my $productNotes = param('productnotes') || '';
  #my $allowmulti = param('allowmulti') || '';
  my $productActive = param('active_product') || '';
  #my $gender = param('gender') || '0';
  #my $nationality = param('nationality') || '';
  #my $entityID = getEntity($realmID);
  
  push @values, ($productName, $realmID,
		param('defaultamount') || '0',
		param('gsttext') || '',
		param('productfamily') || '',
		param('productnotes') || '',
		param('allowmulti') || '',
		param('gender') || '0',
		param('nationality') || '',
		param('period') || '',
		$productActive ? 0 : 1,
		getEntity($db, $realmID));
  
  return show_add_product_form($db,"ERROR: Missing Data") if (!$productName or !$realmID);
  my $stmt = "";
  my $msg = "";
  if( $action eq "addproduct") {
	$stmt = qq[
    INSERT INTO tblProducts
    (strName, intRealmID, curDefaultAmount, strGSTText, strProductType, strProductNotes,
	 intAllowMultiPurchase, intProductGender, strNationality_IN, intProductNationalPeriodID,
	 intInactive, intEntityID)
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
  ];
  
	$msg = 'New Product Saved.';
  } elsif( $action eq "editproduct") {
	my $pid = param('pid') || 0;
	push @values, $pid;
	$stmt = qq[
    UPDATE tblProducts
    SET strName=?, intRealmID=?, curDefaultAmount=?, strGSTText=?, strProductType=?, strProductNotes=?,
	 intAllowMultiPurchase=?, intProductGender=?, strNationality_IN=?, intProductNationalPeriodID=?,
	 intInactive=?, intEntityID=?
    WHERE intProductID = ?
  ];
	$msg = "Product #$pid has been updated.";
  }

  #say $stmt;
  #say Dumper(\@values);
  my $q = $db->prepare($stmt);
  $q->execute(@values);
  my $prodtID = $q->{mysql_insertid};
  print "Content-type: text/html\n\n";
  print "<script type='text/javascript'>";
  print "window.parent.product.show_status('$msg');";
  print "window.top.location.href='/admin/admin_product.cgi?action=list';";
  print "</script>";  

}

sub show_edit_product_form{
    my ($db, $action) = @_;
	my $pid = param('productid') || 0;
	my %Data = ();
	$Data{'lang'} = '';
	my $meta = {};
	
	my $stmt=qq[
	SELECT p.intProductID, p.strName, p.strProductNotes, p.curDefaultAmount, p.strGSTText,
	intProductGender, p.intRealmID, p.strProductType, p.intAllowMultiPurchase,
	n.strNationalPeriodName, n.intNationalPeriodID
	FROM tblProducts p
	LEFT JOIN tblNationalPeriod n ON p.intProductNationalPeriodID=n.intNationalPeriodID
	WHERE intProductID = $pid
	ORDER BY p.intProductID ASC
	];
	print "Content-type: text/html\n\n";
	#say $stmt;
	my $qry = $db->prepare($stmt);
	$qry->execute;
	my $results = $qry->fetchrow_hashref();
	$qry->finish;
	
	$meta->{pid} = $pid;
	$meta->{strname} = $results->{'strName'};
	$meta->{defaultamount} = $results->{'curDefaultAmount'};
	$meta->{strtaxtext} = $results->{'strGSTText'};
	$meta->{strproductnotes} = $results->{'strProductNotes'};
	$meta->{nationalperiod} = $results->{'strNationalPeriodName'};
	$meta->{nationalperiod} = $results->{'strProductType'};
	
	$meta->{'gendedropdown'} = popup_menu(
					-name => 'gender',
					-class => 'inputbox2',
					-values => [0, $Defs::GENDER_MALE, $Defs::GENDER_FEMALE],
					-labels => {
						0 => 'Any',
						$Defs::GENDER_MALE => $Defs::genderInfo{$Defs::GENDER_MALE},
						$Defs::GENDER_FEMALE => $Defs::genderInfo{$Defs::GENDER_FEMALE},
					},
					-default => $results->{'intProductGender'} || 0,
				);
	
	#$meta->{'realms'} = getDBdrop_down('realmID',$db,$rstmt,$results->{'intRealmID'}, '') || '';
	$meta->{'realms'} = getRealms($db, $results->{'intRealmID'}, '');
	
	$meta->{'typedropdown'} = popup_menu(
					-name => 'productfamily',
					-class => 'inputbox2',
					-values => ['', 'insurance', 'licence', 'transfer','passes'],
					-labels => {
						'' => 'Any',
						'insurance' => 'Insurance', 'licence' => 'Licence',
						'transfer' => 'Transfer Fee', 'passes' => 'Playing Pass',
					},
					-default => $results->{'strProductType'},
				);
	$meta->{'perioddropdown'} = getNationalPeriod($db, $results->{'intNationalPeriodID'}, '');
	
	$meta->{'allowmultidropdown'} = popup_menu(
					-name => 'allowmulti',
					-class => 'inputbox2',
					-values => ['0', '1'],
					-labels => {'0' => 'One', '1' => 'Multiple',},
					-default => $results->{'intAllowMultiPurchase'} ? 0 : 1,
				);
	
	return runTemplate(\%Data, $meta, 'admin/product/product_form.templ');
}

sub list_products{
    my ($db, $pid) = @_;
	my %Data = ();
	$Data{'lang'} = '';
	my $meta = {};
	
	my $stmt=qq[
	SELECT p.intProductID, p.strName, p.strProductNotes, p.curDefaultAmount,
	n.strNationalPeriodName
	FROM tblProducts p
	LEFT JOIN tblNationalPeriod n ON p.intProductNationalPeriodID=n.intNationalPeriodID
	ORDER BY p.intProductID ASC
	];
	#print "Content-type: text/html\n\n";
	#say $stmt;
	my $qry = $db->prepare($stmt);
	$qry->execute;
	my $results = $qry->fetchall_hashref('intProductID');
	$qry->finish;
	
	$meta->{results} = $results;
	#say Dumper($meta);
	
	return runTemplate(\%Data, $meta, 'admin/product/product_list.templ');
}
