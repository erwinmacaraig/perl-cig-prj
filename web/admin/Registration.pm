package Registration;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    display_screen
    add_registration
);
@EXPORT_OK = qw(
    display_screen
    add_registration
);

use lib "..","../..";
use DBI;
use CGI qw(param unescape escape);
use strict;
use Defs;
use Utils;
use AdminCommon;
use TTTemplate;
use Data::Dumper;
# use HTML::FillInForm;

sub display_screen{
    my(
        $db,
        $action,
        $target,
    ) = @_;
    
    my $form_action = 'A';
	my $msg = '';

	my $firstname = 'Fred';
	my $surname = 'Scuttle';
	my $gender = '1';
	my $DOB = '29 Jan 1955';
	my $entityID = '35';
	my $personLevel = 'AMATEUR';
	my $sport = 'FOOTBALL';
	my $registrationType = 0; #'REGISTRATION';
	my $ageLevel = 'SENIOR';
	my $personType = 'PLAYER';
   
    my %btn_gender = (
		'1'=>'Male',	
		'2'=>'Female',	
	);

    my %btn_entityID = (
		'1'=>'FIFA',	
		'14'=>'Region',	
		'35'=>'Alands Clubs',	
	);

    my %btn_personType = (
		'PLAYER'=>'Player',	
		'COACH'=>'Coach',	
		'REFEREE'=>'Referee',	
	);
	
    my %btn_personLevel = (
		'AMATEUR'=>'Amateur',	
		'PROFESSIONAL'=>'Professional',	
	);	

    my %btn_sport = (
		'FOOTBALL'=>'Football',	
		'BEACHSOCCER'=>'Beach Soccer',	
		'FUTSAL'=>'Futsal',	
	);	
	
    my %btn_registrationType = (
		'0'=>'Registration',	
		'1'=>'Renewal',	
	);

    my %btn_ageLevel = (
		'SENIOR'=>'Senior',	
		'YOUTH'=>'Youth',	
	);
	
	my $btn_gender = fncRadioBtns($gender,'gender',\%btn_gender);
	my $btn_entityID = fncRadioBtns($entityID,'entityID',\%btn_entityID);
	my $btn_personLevel = fncRadioBtns($personLevel,'personLevel',\%btn_personLevel);
	my $btn_sport = fncRadioBtns($sport,'sport',\%btn_sport);
	my $btn_registrationType = fncRadioBtns($registrationType,'registrationType',\%btn_registrationType);
	my $btn_ageLevel = fncRadioBtns($ageLevel,'ageLevel',\%btn_ageLevel);
	my $btn_personType = fncRadioBtns($personType,'personType',\%btn_personType);
		
	# Create the form
	my $body = '';
	$body = qq[
  	<form action="$target" method="post">
  	<input type="hidden" name="action" value="$form_action">
  	<table>
  	$msg
	<tr>
		<td class="formbg fieldlabel">First Name:</td>
		<td class="formbg"><input type="text" name="firstname" value="$firstname" style="width:100px;"></td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Last Name:</td>
		<td class="formbg"><input type="text" name="surname" value="$surname" style="width:100px;"></td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Gender:</td>
		<td class="formbg">$btn_gender</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Entity:</td>
		<td class="formbg">$btn_entityID</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Type:</td>
		<td class="formbg">$btn_personType</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Level:</td>
		<td class="formbg">$btn_personLevel</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Sport:</td>
		<td class="formbg">$btn_sport</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Registration/Renewal:</td>
		<td class="formbg">$btn_registrationType</td>
	</tr>
	<tr>
		<td class="formbg fieldlabel">Age Level:</td>
		<td class="formbg">$btn_ageLevel</td>
	</tr>
	<tr>
    <td class="formbg" colspan="2" style="text-align:center;">
      <input type="submit" name="submit" value="Register">
    </td>
  </tr>
	</table>
    ];
    
    return '<h1>Add a new Registration</h1><tablecellpadding="5">' . $body . '</table>';
}

sub add_registration {
    my(
        $db,
        $action,
        $target,
    ) = @_;

    my $form_action = 'A';
	my $msg = '';

    my $firstname   	 = param('firstname') || '';
    my $surname     	 = param('surname') || '';
    my $gender      	 = param('gender') || '';
    my $DOB         	 = param('DOB') || '';
    my $entityID   	 	 = param('entityID') || '';
    my $personLevel 	 = param('personLevel') || '';
    my $personType  	 = param('personType') || '';
    my $sport       	 = param('sport') || '';
    my $registrationType = param('registrationType') || 0;
    my $ageLevel    	 = param('ageLevel') || '';

  	my $st = '';
	my $q = '';
	
	$st = qq[
   		INSERT INTO tblPerson
		(
        intRealmID,
        intSystemStatus,
		strLocalFirstname,
		strLocalSurname,
		intGender,
		dtDOB
		)
		VALUES
		(1,1,
        ?,
		?,
		?,
		?)
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
  		$firstname,
  		$surname,
  		$gender,
  		$DOB
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
  	my $personID = $q->{mysql_insertid};

	$st = qq[
   		INSERT INTO tblPersonRegistration_1
		(
		intPersonID,
		intRealmID,
		intSubRealmID,
		intEntityID,
		strPersonType,
		strPersonLevel,
		strStatus,
		strSport,
        intRegistrationNature,
		strAgeLevel,
        intNationalPeriodID 
		)
		VALUES
		(?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?,
		?)
		];

  	$q = $db->prepare($st);
  	$q->execute(
  		$personID,
  		1,
  		2,
  		$entityID,
  		$personType,
  		$personLevel,
  		'PENDING',
  		$sport,
  		$registrationType,
  		$ageLevel,
  		0
  		);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
  	my $personRegistrationID = $q->{mysql_insertid};

	# my $body = $personID . '<br>' . $personRegistrationID;

	my $body = fncNewRegistration($db, $personRegistrationID);

 return $body ;

}

sub fncNewRegistration {
 my($db, $personRegistrationID)=@_;
 
   	my $st = '';
	my $q = '';

	$st = qq[
		INSERT INTO tblWFTask (intWFRuleID, intWFRoleID, intWFEntityID, strTaskType, intDocumentTypeID, strTaskStatus, intPersonID, intPersonRegistrationID, intEntityID, intEntityLinksID)
		SELECT r.intWFRuleID, r.intRoleID, r.intEntityID, r.strTaskType, r.intDocumentTypeID, r.strTaskStatus, pr.intPersonID, pr.intPersonRegistrationID, 0, 0
		FROM tblPersonRegistration_1 pr
		INNER JOIN tblWFRule r
		ON pr.intEntityID = r.intEntityID
		AND pr.strPersonLevel = r.strPersonLevel
		AND pr.strAgeLevel = r.strAgeLevel
		AND pr.strSport = r.strSport
		AND pr.intRegistrationNature = r.intRegistrationNature
		AND pr.intNationalPeriodID= r.intNationalPeriodID
		WHERE pr.intPersonRegistrationID = ?;
		];
		
	$q = $db->prepare($st);
  	$q->execute($personRegistrationID);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}			
	$st = qq[
		INSERT INTO tblWFTaskPreReq (intWFTaskID, intWFRuleID, intPreReqWFRuleID)
		SELECT t.intWFTaskID, t.intWFRuleID, rpr.intPreReqWFRuleID 
		FROM tblWFTask t
		INNER JOIN tblWFRulePreReq rpr ON t.intWFRuleID = rpr.intWFRuleID
		WHERE t.intPersonRegistrationID = ?;
		];

  	$q = $db->prepare($st);
  	$q->execute($personRegistrationID);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}

	return('<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;Your registration has been received and you will be notified in due course when it has been approved.<br>
		<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;<a href=approval.cgi>View Approval Tasks</a>') 
}

sub get_name {
 my($string)=@_;
 
 	my $name = $string;

	my %string_name = (
		CLUB => 'Club', 
		SCHOOL => 'School', 
		AMATEUR => 'Amateur', 		
		PROFESSIONAL => 'Professional', 	
 		FOOTBALL => 'Football', 	
 		FUTSAL => 'Futsal', 	
 		BEACH_SOCCER => 'Beach Soccer', 	
 		NEW => 'Registration', 	
 		RENEWAL => 'Renewal', 	
 		JUNIOR => 'Junior',
 		SENIOR => 'Senior',
 		ALL => 'All',
 		VENUE => 'Venue',
 		MEMBER => 'Member'
	);

	if(exists $string_name{$string}) {
		$name =  $string_name{$string} || 0;
	}
	
	return $name;
	
}

sub fncRadioBtns {
   	my ($field_value,$field_name, $button_fin_inst, $separator) = @_;
		
	my $txt = '';
	my $pfx = '';
	my $sfx = '';
	if (!$separator) {
		$separator = '&nbsp;'
	}
	
	#PP How do I get a sorted list?
	my $i = -1;
    foreach my $key (sort { $button_fin_inst->{$a} cmp $button_fin_inst->{$b}} keys %{$button_fin_inst})   {
#    foreach my $key(keys %{$button_fin_inst}) {
       	$i = $i + 1;
        if ($key eq $field_value) { 
            $sfx = ' checked ';
        }
        else {
            $sfx = '';
        }
        $txt = $txt . $pfx . '<input type=radio name="' . $field_name . '" value="' . $key . '"' . $sfx . '>' . $button_fin_inst->{$key};
        $pfx = $separator;
    }
	return $txt;
}




