package RegistrationAllowed;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	isRegoAllowedToSystem
    isRegoAllowedToEntity
);

use strict;
use Utils;
use Log;

sub isRegoAllowedToSystem {
    my($Data, $originLevel, $regNature, $Rego_ref) = @_; 

    $originLevel ||= 0; 
    $regNature ||= '';

    return 0 if (! $originLevel or ! $regNature);
	
    my $st = qq[
		SELECT 
            COUNT(intWFRuleID) as CountRecords
        FROM
            tblWFRule
        WHERE
            intRealmID = ?
            AND intSubRealmID IN (0, ?)
            AND strTaskType = 'APPROVAL'
            AND strWFRuleFor = 'REGO'
            AND intOriginLevel = ?
			AND strRegistrationNature = ?
			AND strPersonType = ?
			AND strPersonLevel = ?
			AND strSport = ?
			AND strAgeLevel = ?		
    ];
	

	my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
        $originLevel,
		$regNature,
		$Rego_ref->{'personType'} || '',
		$Rego_ref->{'personLevel'} || '',
		$Rego_ref->{'sport'} || '',
		$Rego_ref->{'ageLevel'} || '',
	) or query_error($st);
	
    my $count = $q->fetchrow_array() || 0;
    return 1 if $count;
    return 0 if ! $count;

}

sub isRegoAllowedToEntity {

    my($Data, $entityID, $regNature, $Rego_ref) = @_; 

    $entityID ||= 0;
    $regNature ||= '';

    return 0 if (! $entityID or ! $regNature);
	
    my $st = qq[
		SELECT 
            COUNT(intEntityRegistrationAllowedID) as CountRecords
        FROM
            tblEntityRegistrationAllowed
        WHERE
            intRealmID = ?
            AND intSubRealmID IN (0, ?)
		    AND intEntityID = ?
			AND strRegistrationNature = ?
			AND strPersonType = ?
			AND strPersonLevel = ?
			AND strSport = ?
			AND strAgeLevel = ?		
            AND intGender = ?
    ];
	

	my $q = $Data->{'db'}->prepare($st) or query_error($st);
	$q->execute(
        $Data->{'Realm'},
        $Data->{'RealmSubType'},
		$entityID,
		$regNature,
		$Rego_ref->{'personType'} || '',
		$Rego_ref->{'personLevel'} || '',
		$Rego_ref->{'sport'} || '',
		$Rego_ref->{'ageLevel'} || '',
		$Rego_ref->{'gender'}
	) or query_error($st);
	
    my $count = $q->fetchrow_array() || 0;
    return 1 if $count;
    return 0 if ! $count;
}

1;
