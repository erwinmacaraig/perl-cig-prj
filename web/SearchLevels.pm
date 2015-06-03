#
# $Header: svn://svn/SWM/trunk/web/SearchLevels.pm 8251 2013-04-08 09:00:53Z rlee $
#

package SearchLevels;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getLevelQueryStuff);
@EXPORT_OK = qw(getLevelQueryStuff);

use strict;
use lib '..';

use Defs;
use Utils;

sub getLevelQueryStuff	{

	my($searchlevel, $searchentity, $Data, $stats, $notmemberteam, $otheroptions)=@_;

	my $clientValues_ref=$Data->{'clientValues'};
	$stats||=0; #if stats is being reported or actual data
	$notmemberteam||=0; #if team/comp tables should be included in member join
	#Setup values for search levels
    my $current_level=$clientValues_ref->{currentLevel};
	my $from_levels='';
	my $where_levels='';
	my $select_levels='';

	if ($searchlevel > $Defs::LEVEL_MEMBER and $searchentity == $Defs::LEVEL_MEMBER) { #Assoc Level and above
        my $PRtablename = "tblPersonRegistration_$Data->{'Realm'}";
		$from_levels.=' INNER JOIN ' if $from_levels;
		$where_levels.=' AND ' if $where_levels;
		$from_levels.=qq[ 
            tblPerson 
            INNER JOIN $PRtablename as PR ON (
                tblPerson.intPersonID=PR.intPersonID 
            ) 
            INNER JOIN tblEntity as E ON (
                E.intEntityID = PR.intEntityID
            ) 
            LEFT JOIN tblEntityTypeRoles as ETR ON (
                ETR.strEntityRoleKey = PR.strPersonEntityRole
            ) 
            LEFT JOIN tblEntity as tblClub ON (
                PR.intEntityID = tblClub.intEntityID
                AND tblClub.intEntityLevel = $Defs::LEVEL_CLUB
            ) 
            LEFT JOIN tblTempEntityStructure as RL ON (
                E.intEntityID = RL.intChildID
                AND RL.intParentLevel = $Defs::LEVEL_REGION
            )
            LEFT JOIN tblEntity as tblRegion ON (
                RL.intParentID = tblRegion.intEntityID
            ) 
        ] ;
        $where_levels.=qq[ 
            tblPerson.strStatus NOT IN ("$Defs::PERSON_STATUS_INPROGRESS", "$Defs::PERSON_STATUS_DELETED") 
            AND PR.strStatus NOT IN ("$Defs::PERSONREGO_STATUS_INPROGRESS", "$Defs::PERSONREGO_STATUS_REJECTED", "$Defs::PERSONREGO_STATUS_DELETED")
            AND PR.strStatus <> ''
            AND tblPerson.strStatus <> ''
        ];
	}

	my $current_where='';
	my $current_from='';
	if($current_level== $Defs::LEVEL_MEMBER)	{
		$current_from=qq[tblPerson];
		$current_where=qq[tblPerson.intPersonID= $clientValues_ref->{personID} ];
	}
	$current_where='AND '.$current_where if $current_where;

	return ( $from_levels, $where_levels, $select_levels, $current_from, $current_where);

}


sub getAccessSQL	{
	my($accesstable, $stats, $Data)=@_;
	my $access_level= $stats ? $Defs::DATA_ACCESS_STATS : $Defs::DATA_ACCESS_READONLY;
	my $pb= exists $Data->{'SystemConfig'}{'ParentBodyAccess'} ? $Data->{'SystemConfig'}{'ParentBodyAccess'} : '';
	my $fname= $pb ne '' ? $pb : "$accesstable.intDataAccess";
	return qq[ AND $fname >= $access_level ];
}
