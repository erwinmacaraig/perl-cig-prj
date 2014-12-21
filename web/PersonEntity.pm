package PersonEntity;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    addPERecord
);
use strict;
use Data::Dumper;
use Person;
use AuditLog;
use Reg_common;

sub addPERecord {
    my($Data, $personID, $entityID, $Reg_ref) = @_;

    $Reg_ref->{'personEntityRole'}= '' if ($Reg_ref->{'personEntityRole'} eq '-');
    $Reg_ref->{'sport'}= '' if ($Reg_ref->{'sport'} eq '-');
    $Reg_ref->{'personLevel'}= '' if ($Reg_ref->{'personLevel'} eq '-');
    
    my $status = $Defs::PERSON_ENTITY_STATUS_ACTIVE;

	my $st = qq[
   		INSERT INTO tblPersonEntity_$Data->{'Realm'} (
            intRealmID,
            intPersonID,
            intEntityID,
            strPEPersonType,
            strPEPersonLevel,
            strPEPersonEntityRole,
            strPEStatus,
            strPESport,
            dtPEFrom,
            dtPETo,
            dtPEAdded,
            dtPELastUpdated
		)
		VALUES
		(
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            NOW(),
            '0000-00-00',
            NOW(),
            NOW()
        )
    ];

  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
  		$Data->{'Realm'},
  		$Reg_ref->{'personID'},
  		$Reg_ref->{'entityID'},
  		$Reg_ref->{'personType'} || '',  		
  		$Reg_ref->{'personLevel'} || '',  		
  		$Reg_ref->{'personEntityRole'} || '',  		
  		$status,  		
  		$Reg_ref->{'sport'} || '',  		
  	);
	
  	auditLog($personRegistrationID, $Data, 'Add Person Entity', 'Person');
}

1;
