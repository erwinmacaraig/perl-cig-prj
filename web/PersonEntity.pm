package PersonEntity;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    addPERecord
    doesOpenPEExist
    closePERecord
    
);
use strict;
use Data::Dumper;
use Person;
use AuditLog;
use Reg_common;

sub closePERecord {
    my($Data, $personID, $entityID, $status, $dtTo, $Reg_ref) = @_;

    my %reg = ();
    if (! $dtTo)    {
        my ($Second, $Minute, $Hour, $Day, $Month, $Year, $WeekDay, $DayOfYear, $IsDST) = localtime(time);
        $Year+=1900;
        $Month++;
        $dtTo = "$Year-$Month-$Day";
    }
    
    $reg{'personType'} = $Reg_ref->{'personType'} || '';
    $reg{'personLevel'} = $Reg_ref->{'personLevel'} || '';
    $reg{'personEntityRole'} = $Reg_ref->{'personEntityRole'} || '';
    $reg{'sport'} = $Reg_ref->{'sport'} || '';
    $reg{'personEntityRole'}= '' if ($Reg_ref->{'personEntityRole'} eq '-');
    $reg{'sport'}= '' if ($Reg_ref->{'sport'} eq '-');
    $reg{'personLevel'}= '' if ($Reg_ref->{'personLevel'} eq '-');

    my $st = qq[
       UPDATE tblPersonEntity_$Data->{'Realm'}
        SET strStatus=?, dtPETo = ?
       WHERE
            intRealmID=?
            AND intPersonID=?
            AND intEntityID=?
            AND strPEPersonType=?
            AND strPEPersonLevel=?
            AND strPEPersonEntityRole=?
            AND strPESport=?
        ORDER BY dtPEFrom DESC
        LIMIT 1
    ];
  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
        $status,
        $dtTo,
        $Data->{'Realm'},
        $personID,
        $entityID,
        $reg{'personType'},
  		$reg{'personLevel'},  		
  		$reg{'personEntityRole'},  		
  		$reg{'sport'},  		
    );
  	auditLog($personID, $Data, $Data->{'lang'}->txt('Close Person Entity'), 'Person');
}

sub doesOpenPEExist {
    my($Data, $personID, $entityID, $Reg_ref) = @_;

    my %reg = ();
    $reg{'personType'} = $Reg_ref->{'personType'} || '';
    $reg{'personLevel'} = $Reg_ref->{'personLevel'} || '';
    $reg{'personEntityRole'} = $Reg_ref->{'personEntityRole'} || '';
    $reg{'sport'} = $Reg_ref->{'sport'} || '';
    $reg{'personEntityRole'}= '' if ($Reg_ref->{'personEntityRole'} eq '-');
    $reg{'sport'}= '' if ($Reg_ref->{'sport'} eq '-');
    $reg{'personLevel'}= '' if ($Reg_ref->{'personLevel'} eq '-');

    my $st = qq[
        SELECT 
            intPersonEntityID
        FROM
            tblPersonEntity_$Data->{'Realm'}
        WHERE
            dtPETo = '0000-00-00'
            AND strPEStatus = ?
            AND intRealmID=?
            AND intPersonID=?
            AND intEntityID=?
            AND strPEPersonType=?
            AND strPEPersonLevel=?
            AND strPEPersonEntityRole=?
            AND strPESport=?
        ORDER BY dtPEFrom DESC
        LIMIT 1
    ];
  	my $q = $Data->{'db'}->prepare($st);
  	$q->execute(
        $Defs::PERSON_ENTITY_STATUS_ACTIVE,
        $Data->{'Realm'},
        $personID,
        $entityID,
        $reg{'personType'},
  		$reg{'personLevel'},  		
  		$reg{'personEntityRole'},  		
  		$reg{'sport'},  		
    );
    my $personEntityID = $q->fetchrow_array() || 0;

    return $personEntityID;

}
    
sub addPERecord {
    my($Data, $personID, $entityID, $Reg_ref) = @_;

    my %reg = ();
    $reg{'personType'} = $Reg_ref->{'personType'} || '';
    $reg{'personLevel'} = $Reg_ref->{'personLevel'} || '';
    $reg{'personEntityRole'} = $Reg_ref->{'personEntityRole'} || '';
    $reg{'sport'} = $Reg_ref->{'sport'} || '';

    $reg{'personEntityRole'}= '' if ($Reg_ref->{'personEntityRole'} eq '-');
    $reg{'sport'}= '' if ($Reg_ref->{'sport'} eq '-');
    $reg{'personLevel'}= '' if ($Reg_ref->{'personLevel'} eq '-');
    
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
  		$personID,
  		$entityID,
  		$reg{'personType'} || '',  		
  		$reg{'personLevel'} || '',  		
  		$reg{'personEntityRole'} || '',  		
  		$status,  		
  		$reg{'sport'} || '',  		
  	);
	
  	auditLog($personID, $Data, $Data->{'lang'}->txt('Add Person Entity'), 'Person');
}

1;
