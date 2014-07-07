package PersonRegistration;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getRegistrationData);
@EXPORT_OK =qw(getRegistrationData);

use strict;
use Log;
use Data::Dumper;

sub getRegistrationData	{
	my (
		$Data, 
		$personID, 
		$templateData_ref
	)=@_;
	
my $statement = qq[
    SELECT pr.*, e.strLocalName 
    FROM
      tblPersonRegistration_$Data->{'Realm'} AS pr
      INNER JOIN tblEntity e ON pr.intEntityID = e.intEntityID 
      WHERE intPersonID = ?
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
	
$templateData_ref->{'RegistrationInfo'} = \@Registration;	
	
}

1;
