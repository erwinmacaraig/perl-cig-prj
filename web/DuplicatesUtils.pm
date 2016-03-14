package DuplicatesUtils;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(isCheckDupl getDuplFields isPossibleDuplicate);
@EXPORT_OK = qw(isCheckDupl getDuplFields isPossibleDuplicate);

use lib '.', '..';

use strict;
use Reg_common;
use CGI qw(unescape param Vars);
use Utils;



sub isCheckDupl	{
	my($Data)=@_;
    return '' if ($Data->{'ReadOnlyLogin'} and !$Data->{'SystemConfig'}{'ShowDCWhenRO'});
	my $check_dupl='';

	#Duplicates should also be checked for unless specifically disabled
	if (exists $Data->{'SystemConfig'}{'DuplCheck'}) {
        return 'realm' if $Data->{'SystemConfig'}{'DuplCheck'} eq '1'; 
        return ''      if $Data->{'SystemConfig'}{'DuplCheck'} eq '-1'; #Don't check dup; 
	}
	if (exists $Data->{'Permissions'}{'OtherOptions'} and 
        exists $Data->{'Permissions'}{'OtherOptions'}{'DuplCheck'} and 
        $Data->{'Permissions'}{'OtherOptions'}{'DuplCheck'}[0] eq '-1')	{
		    return ''; #Explicitly turned off
	}
	return 'assoc';
}

sub getDuplFields	{
    my($Data)=@_;
    my $duplfields=$Data->{'SystemConfig'}{'DuplicateFields'} 
        || $Data->{'Permissions'}{'OtherOptions'}{'DuplFields'} 
        || 'strLocalSurname|strLocalFirstname|dtDOB';
    my @FieldsToCheck=split /\|/,$duplfields;
    return @FieldsToCheck;
}


sub isPossibleDuplicate {
    my (
        $Data,
        $params,
        $personID,
        $typeofDuplCheck,
    ) = @_;

    my $duplcheck = $typeofDuplCheck || isCheckDupl($Data) || '';
    $personID ||= 0;

    if ($duplcheck) {

        #Check for Duplicates
        my @FieldsToCheck = getDuplFields($Data);
        return ( 1, '' ) if !@FieldsToCheck;

        my $st        = q{};
        my $wherestr  = q{};

        my @where_fields = ();
        my @st_fields = ();

        if ( $personID ) {
            $wherestr .= 'AND tblPerson.intPersonID <> ?';
            push @where_fields, $personID;
        }

        for my $i (@FieldsToCheck) {
            $wherestr .= " AND  $i = ?";
            push @where_fields, $params->{$i};
        }

        $duplcheck = 'realm';
        #if ( $duplcheck eq 'realm' ) {
            $st = qq[
                SELECT tblPerson.intPersonID
                FROM tblPerson
                WHERE  
                    tblPerson.intRealmID = ? 
                    AND tblPerson.strStatus <> ?
                    AND tblPerson.strStatus <> ?
                    AND tblPerson.intSystemStatus <> ?
                    $wherestr
                ORDER BY 
                    tblPerson.intSystemStatus
                LIMIT 1
            ];
            @st_fields = (
                $Data->{'Realm'}, 
                $Defs::PERSON_STATUS_INPROGRESS,
                $Defs::PERSON_STATUS_DUPLICATE,
                $Defs::PERSONSTATUS_DELETED, 
                @where_fields,
            );
        #}
        my $q = $Data->{'db'}->prepare($st);
        $q->execute(@st_fields);
        my $dupl = $q->fetchrow_array;
        $q->finish();
        $dupl ||= 0;
        return $dupl;
    }
    return 0;
}

1;
