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
#use EventAdmin;
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
	
	my %Data = ();
	$Data{'lang'} = '';
    if ($action eq "add") {
	
        #($subBody,$menu) =  runTemplate(\%Data, $meta, 'admin/product/product_form.templ');
        ($subBody,$menu) = show_add_product_form($db, \%Data);
    }	
	elsif($action eq "addproduct" || $action eq "editproduct")	{
		my $q = new CGI;
	    my @names = $q->param;
		print "Content-type: text/html\n\n";
		#foreach my $name (@names) {
		#  say $name.'='.$q->param($name)."<br/>";
		#}
		($subBody,$menu)=handle_product($db, $action);
	}
    elsif($action eq "edit") {
		($subBody,$menu)=show_edit_product_form($db, \%Data);
	}
	
    elsif( $action eq "list") {
        ($subBody,$menu) = list_products($db, \%Data);
   }
	else	{
		$subBody=list_products($db, \%Data);
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

sub gender_select{
    my ($def_val) = @_;
    return popup_menu(
				-name => 'gender',
				-class => 'inputbox2',
				-values => [0, $Defs::GENDER_MALE, $Defs::GENDER_FEMALE],
				-labels => {
					0 => 'Any',
					$Defs::GENDER_MALE => $Defs::genderInfo{$Defs::GENDER_MALE},
					$Defs::GENDER_FEMALE => $Defs::genderInfo{$Defs::GENDER_FEMALE},
				},
				-default => $def_val || 0,
			);
}
sub prodtype_select{
    my ($def_val) = @_;
    return popup_menu(
					-name => 'productfamily',
					-class => 'inputbox2',
					-values => ['', 'insurance', 'licence', 'transfer','passes'],
					-labels => {
						'' => 'Any',
						'insurance' => 'Insurance', 'licence' => 'Licence',
						'transfer' => 'Transfer Fee', 'passes' => 'Playing Pass',
					},
					-default => $def_val,
				);
}

sub allowmulti_select{
    my ($def_val) = @_;
    return popup_menu(
			   -name => 'allowmulti',
				-class => 'inputbox2',
				-style => 'width:20%',
				-values => ['0', '1'],
				-labels => {'0' => 'One', '1' => 'Multiple',},
				-default => $def_val,
			);
}

sub agelevel_select{
    my ($def_val) = @_;
    return popup_menu(
			-name => 'agelevel',
			-class => 'inputbox2',
			-values => [$Defs::AGE_LEVEL_ALL, $Defs::AGE_LEVEL_ADULT, $Defs::AGE_LEVEL_MINOR],
				
			-default => $def_val,
		);
}

sub personlevel_select{
    my ($def_val) = @_;
    my @personlevel_keys = keys %Defs::personLevel;
	my @personlevel_values = values %Defs::personLevel;
    return popup_menu(
			  -name => 'personlevel',
			  -class => 'inputbox2',
			  -values => [@personlevel_keys],
			  -labels => \%Defs::personLevel,
			  -default => $def_val,
			  );
}

sub role_select{
    my ($def_val) = @_;
    popup_menu(
			-name => 'role',
			-class => 'inputbox2',
			-values => ['1','2','3','4','5','6'],
			-labels => {
				'1' => $Defs::memberTypeName{'1'},
				'2' => $Defs::memberTypeName{'2'},
				'3' => $Defs::memberTypeName{'3'},
				'4' => $Defs::memberTypeName{'4'},
				'5' => $Defs::memberTypeName{'5'},
				'6' => $Defs::memberTypeName{'6'}
			},
			-default => $def_val,
			);
}

sub sports_select{
    my ($def_val) = @_;
    popup_menu(
		-name => 'strSport',
		-class => 'inputbox2',
		-values => [keys \%Defs::sportType],
		-labels => \%Defs::sportType,
		-default => $def_val,
		);
}

sub handle_product {
  my ($db,$action) = @_;
  
  my @values = ();
  my @regvalues = ();
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
  
  push @regvalues, ($realmID,
		param('intOriginLevel') || '0',
		param('strRuleFor') || 'REGO',
		param('intEntityLevel') || '',
		param('strRegistrationNature') || 'NEW',
		uc( $Defs::memberTypeName{ param('role') } ),
		param('personlevel'),
		param('strSport') || '',
		param('agelevel') || '',
		'PRODUCT',
		$prodtID);
  
  say Dumper(@regvalues);
  
  if( $prodtID ) {
	  #
	  $stmt = qq[
	  INSERT INTO tblRegistrationItem
	  (intRealmID, intOriginLevel, strRuleFor, intEntityLevel, strRegistrationNature,
	   strPersonType, strPersonLevel, strSport, strAgeLevel,
	   strItemType, intID)
	  VALUES (?,?,?,?,?,?,?,?,?,?,?)
	];
	say $stmt;
	my $q2 = $db->prepare($stmt);
	$q2->execute(@regvalues);
    my $prodtID = $q2->{mysql_insertid};
  }
  
  print "Content-type: text/html\n\n";
  print "<script type='text/javascript'>";
  print "window.parent.product.show_status('$msg');";
  print "window.top.location.href='/admin/admin_product.cgi?action=list';";
  print "</script>";  

}

sub show_edit_product_form{
    my ($db, %Data) = @_;
	my $pid = param('productid') || 0;
	#my %Data = ();
	#$Data{'lang'} = '';
	my $meta = {};
	
	my $stmt=qq[
	SELECT p.intProductID, p.strName, p.strProductNotes, p.curDefaultAmount, p.strGSTText,
	intProductGender, p.intRealmID, p.strProductType, p.intAllowMultiPurchase,
	n.strNationalPeriodName, n.intNationalPeriodID, p.strNationality_IN,
	r.strPersonType, r.strAgeLevel, r.strPersonLevel, r.strSport
	FROM tblProducts p
	LEFT JOIN tblNationalPeriod n ON p.intProductNationalPeriodID=n.intNationalPeriodID
	LEFT JOIN tblRegistrationItem r ON p.intProductID=r.intID
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
	#$meta->{nationalperiod} = $results->{'strNationalPeriodName'};
	#$meta->{nationalperiod} = $results->{'strProductType'};
	$meta->{strnationality} = $results->{'strNationality_IN'};
	
	$meta->{'gendedropdown'} = gender_select($results->{'intProductGender'} || 0);
	#$meta->{'realms'} = getDBdrop_down('realmID',$db,$rstmt,$results->{'intRealmID'}, '') || '';
	$meta->{'realms'} = getRealms($db, $results->{'intRealmID'}, '');
	$meta->{'typedropdown'} = prodtype_select($results->{'strProductType'});
	
	$meta->{'perioddropdown'} = getNationalPeriod($db, $results->{'intNationalPeriodID'}, '');
	
	$meta->{'allowmultidropdown'} = allowmulti_select($results->{'intAllowMultiPurchase'} ? 0 : 1);
	
	$meta->{'agedropdown'} = agelevel_select($results->{'strAgeLevel'});
	
	$meta->{'roledropdown'} = role_select($results->{'strPersonType'});
	$meta->{'personleveldropdown'} = personlevel_select($results->{'strPersonLevel'});
	$meta->{'sportsdropdown'} = sports_select($results->{'strSport'});
	
	return runTemplate(\%Data, $meta, 'admin/product/product_form.templ');
}

sub show_add_product_form{
  my ($db, %Data) = @_;
  #my %Data = ();
  #$Data{'lang'} = '';
  my $meta = {};
		$meta->{'realms'} = getRealms($db, '', '&nbsp;');
	    $meta->{'gendedropdown'} = gender_select($Defs::genderInfo{$Defs::GENDER_NONE});
		
		$meta->{'typedropdown'} = prodtype_select('');
		
		$meta->{'allowmultidropdown'} = allowmulti_select('0');
		
		$meta->{'agedropdown'} = agelevel_select($Defs::AGE_LEVEL_ADULT);
		
		#print "Content-type: text/html\n\n";
		
		#say Dumper(@personlevel_keys);
		#say Dumper(@personlevel_values);
		$meta->{'personleveldropdown'} = personlevel_select('');
		
		$meta->{'roledropdown'} = role_select('');
		
		$meta->{'sportsdropdown'} = sports_select('');
		
		$meta->{'perioddropdown'} = getNationalPeriod($db, '', '&nbsp;');
	
        return runTemplate(\%Data, $meta, 'admin/product/product_form.templ');
  
}

sub list_products{
    my ($db, %Data, $pid) = @_;
	#my %Data = ();
	#$Data{'lang'} = '';
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
