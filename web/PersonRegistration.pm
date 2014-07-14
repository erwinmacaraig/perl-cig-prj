package PersonRegistration;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  getRegistrationData
  addRegistration
);

use strict;
use Log;
use WorkFlow;
use Data::Dumper;

sub getRegistrationData	{
	my (
		$Data, 
		$personID,
	)=@_;
	
my $statement = qq[
    SELECT pr.*, e.strLocalName 
    FROM
      tblPersonRegistration_$Data->{'Realm'} AS pr
      INNER JOIN tblEntity e ON pr.intEntityID = e.intEntityID 
      WHERE intPersonID = ?
      AND intCurrent = 1
    ORDER BY
      dtAdded DESC
  ];	

my $db=$Data->{'db'};
my $query = $db->prepare($statement) or query_error($statement);
$query->execute($personID) or query_error($statement);

my @Registration = ();
  
while(my $dref= $query->fetchrow_hashref()) {

	my %single_registration = (
		intEntityID => $dref->{intEntityID},
		strLocalName => $dref->{strLocalName},
		strSubTypeName => $dref->{strSubTypeName},
		strPersonLevel => $dref->{strPersonLevel},
		strPersonType => $dref->{strPersonType},
		strSport => $dref->{strSport},
		dtAdded  => $dref->{dtAdded},
		dtFrom  => $dref->{dtFrom},
		dtTo  => $dref->{dtTo},
	 	);
	push @Registration, \%single_registration;
  }
	
return(\@Registration);
	
}

sub addRegistration {
    my(
        $Data,
        $Reg_ref,
    ) = @_;

  	my $st = '';
	my $q = '';
	my $db=$Data->{'db'};
	
	$st = qq[
   		INSERT INTO tblPersonRegistration_$Data->{'Realm'} (
		intPersonID,
		intRealmID,
		intSubRealmID,
		intEntityID,
		strPersonType,
		strPersonLevel,
		strStatus,
		strSport,
		strRegistrationNature,
		strAgeLevel
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
		?)
		];

  	$q = $db->prepare($st);
  	$q->execute(
  		$Reg_ref->{'personID'},,
  		$Data->{'Realm'},
  		$Data->{'SubRealm'},
  		$Reg_ref->{'entityID'},
  		$Reg_ref->{'personType'},  		
  		$Reg_ref->{'personLevel'},  		
  		'PENDING',
  		$Reg_ref->{'sport'},  		
  		$Reg_ref->{'registrationNature'},
  		$Reg_ref->{'ageLevel'},
  		);
	
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
  	my $personRegistrationID = $q->{mysql_insertid};
  	
  	my $rc = addTasks($Data,$personRegistrationID);
  	
 	return ($personRegistrationID, $rc) ;

}

1;
