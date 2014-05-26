#
# $Header: svn://svn/SWM/trunk/web/comp/TeamObj.pm 8705 2013-06-17 23:32:51Z tcourt $
#

package TeamObj;
use BaseAssocObject;
our @ISA =qw(BaseAssocObject);

use strict;

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my %params=@_;


  my $self ={};
  ##bless selfhash to class
  bless $self, $class;

	#Set Defaults
	$self->{'db'}=$params{'db'};
	$self->{'ID'}=$params{'ID'};
	$self->{'assocID'}=$params{'assocID'};
	return undef if !$self->{'db'};
	return undef if !$self->{'assocID'};
	return undef if $self->{'assocID'} !~ /^\d+$/;
	return undef if($self->{'ID'} and $self->{'ID'} !~ /^\d+$/);

  ##return the blessed hash
  return $self;
}

sub load	{
  my $self = shift;

	my $st=qq[
		SELECT * 
		FROM tblTeam
		WHERE intTeamID = ?
	];
	my $q = $self->{'db'}->prepare($st);
   $q->execute($self->{'ID'});
	if($DBI::err)	{
		$self->LogError($DBI::err);
	}
	else	{
		$self->{'DBData'}=$q->fetchrow_hashref();	
	}
}

sub name	{
  my $self = shift;
	return $self->{'DBData'}{'strName'} || '';
}

sub create {
  my $self = shift;
	my($roundData)=@_;
	for my $k (keys %{$roundData})	{
		$self->{'DBData'}{$k}=$roundData->{$k};
	}
	$self->{'ID'}=$self->{'DBData'}{'intTeamID'};
	$self->writeTeam() if !$self->{'DBData'}{'intTeamID'};
}

sub update {
  my $self = shift;
	my($roundData)=@_;
	for my $k (keys %{$roundData})	{
		$self->{'DBData'}{$k}=$roundData->{$k};
	}
	$self->writeTeam();
}
sub TeamInComp {
	my $self = shift;
	my ($season) = @_;
	my $season_add = '';
	if($season){
		$season_add = "AND AC.intNewSeasonID = $season";
	}
	 my $st=qq[
                        SELECT CT.intCompID
                        FROM tblComp_Teams AS CT
                        INNER JOIN tblAssoc_Comp AS AC ON AC.intCompID=CT.intCompID
                        WHERE intTeamID=$self->{'ID'}
                        $season_add
			AND CT.intRecStatus= $Defs::RECSTATUS_ACTIVE
                        AND AC.intRecStatus= $Defs::RECSTATUS_ACTIVE
          ];
   	 my $q=$self->{'db'}->prepare($st);
   	 $q->execute();
    	my ($compID)=$q->fetchrow_array();
	return $compID;
}
sub writeTeam {
  my $self = shift;
	my @values=();
	for my $k (keys %{$self->{'DBData'}})	{
		next if $k eq 'intTeamID';
		push @values, [$k, $self->{'DBData'}{$k}];

	}
	my $st='';
	if($self->ID())	{
		$st=qq[
			UPDATE tblTeam SET 
				strTeamNo = ?,
				intClubID = ?,
				strName = ?,
				strContact = ?,
				strAddress1 = ?,
				strAddress2 = ?,
				strSuburb = ?,
				strPostalCode = ?,
				strState = ?,
				strPhone1 = ?,
				strPhone2 = ?,
				strEmail = ?,
				strExtKey = ?,
				strNickname = ?,
				dtRegistered = ?,
				strCountry = ?,
				dtExpiry = ?,
				strContactTitle = ?,
				strContactTitle2 = ?,
				strContactName2 = ?,
				strContactEmail2 = ?,
				strContactPhone2 = ?,
				strContactTitle3 = ?,
				strContactName3 = ?,
				strContactEmail3 = ?,
				strContactPhone3 = ?,
				intTeamCreatedFrom = ?,
				dtTeamCreatedOnline = ?,
				strTeamCustomStr1 = ?,
				strTeamCustomStr2 = ?,
				strTeamCustomStr3 = ?,
				strTeamCustomStr4 = ?,
				strTeamCustomStr5 = ?,
				strTeamCustomStr6 = ?,
				strTeamCustomStr7 = ?,
				strTeamCustomStr8 = ?,
				strTeamCustomStr9 = ?,
				strTeamCustomStr10 = ?,
				strTeamCustomStr11 = ?,
				strTeamCustomStr12 = ?,
				strTeamCustomStr13 = ?,
				strTeamCustomStr14 = ?,
				strTeamCustomStr15 = ?,
				dblTeamCustomDbl1 = ?,
				dblTeamCustomDbl2 = ?,
				dblTeamCustomDbl3 = ?,
				dblTeamCustomDbl4 = ?,
				dblTeamCustomDbl5 = ?,
				dblTeamCustomDbl6 = ?,
				dblTeamCustomDbl7 = ?,
				dblTeamCustomDbl8 = ?,
				dblTeamCustomDbl9 = ?,
				dblTeamCustomDbl10 = ?,
				dtTeamCustomDt1 = ?,
				dtTeamCustomDt2 = ?,
				dtTeamCustomDt3 = ?,
				dtTeamCustomDt4 = ?,
				dtTeamCustomDt5 = ?,
				intTeamCustomLU1 = ?,
				intTeamCustomLU2 = ?,
				intTeamCustomLU3 = ?,
				intTeamCustomLU4 = ?,
				intTeamCustomLU5 = ?,
				intTeamCustomLU6 = ?,
				intTeamCustomLU7 = ?,
				intTeamCustomLU8 = ?,
				intTeamCustomLU9 = ?,
				intTeamCustomLU10 = ?,
				intTeamCustomBool1 = ?,
				intTeamCustomBool2 = ?,
				intTeamCustomBool3 = ?,
				intTeamCustomBool4 = ?,
				intTeamCustomBool5 = ?,
				strWebURL = ?,
				strUniformTopColour = ?,
				strUniformBottomColour = ?,
				strUniformNumber = ?,
				strAltUniformTopColour = ?,
				strAltUniformBottomColour = ?,
				strAltUniformNumber = ?,
				strTeamNotes = ?,
				strLadderName = ?,
				intVenue1ID = ?,
				intVenue2ID = ?,
				intVenue3ID = ?,
				dtStartTime1 = ?,
				dtStartTime2 = ?,
				dtStartTime3 = ?
			WHERE intTeamID = ?
				AND intAssocID = ?
		];
		my $q = $self->{'db'}->prepare($st);
		$q->execute(
			$self->{'DBData'}{'strTeamNo'},
			$self->{'DBData'}{'intClubID'},
			$self->{'DBData'}{'strName'},
			$self->{'DBData'}{'strContact'},
			$self->{'DBData'}{'strAddress1'},
			$self->{'DBData'}{'strAddress2'},
			$self->{'DBData'}{'strSuburb'},
			$self->{'DBData'}{'strPostalCode'},
			$self->{'DBData'}{'strState'},
			$self->{'DBData'}{'strPhone1'},
			$self->{'DBData'}{'strPhone2'},
			$self->{'DBData'}{'strEmail'},
			$self->{'DBData'}{'strExtKey'},
			$self->{'DBData'}{'strNickname'},
			$self->{'DBData'}{'dtRegistered'},
			$self->{'DBData'}{'strCountry'},
			$self->{'DBData'}{'dtExpiry'},
			$self->{'DBData'}{'strContactTitle'},
			$self->{'DBData'}{'strContactTitle2'},
			$self->{'DBData'}{'strContactName2'},
			$self->{'DBData'}{'strContactEmail2'},
			$self->{'DBData'}{'strContactPhone2'},
			$self->{'DBData'}{'strContactTitle3'},
			$self->{'DBData'}{'strContactName3'},
			$self->{'DBData'}{'strContactEmail3'},
			$self->{'DBData'}{'strContactPhone3'},
			$self->{'DBData'}{'intTeamCreatedFrom'},
			$self->{'DBData'}{'dtTeamCreatedOnline'},
			$self->{'DBData'}{'strTeamCustomStr1'},
			$self->{'DBData'}{'strTeamCustomStr2'},
			$self->{'DBData'}{'strTeamCustomStr3'},
			$self->{'DBData'}{'strTeamCustomStr4'},
			$self->{'DBData'}{'strTeamCustomStr5'},
			$self->{'DBData'}{'strTeamCustomStr6'},
			$self->{'DBData'}{'strTeamCustomStr7'},
			$self->{'DBData'}{'strTeamCustomStr8'},
			$self->{'DBData'}{'strTeamCustomStr9'},
			$self->{'DBData'}{'strTeamCustomStr10'},
			$self->{'DBData'}{'strTeamCustomStr11'},
			$self->{'DBData'}{'strTeamCustomStr12'},
			$self->{'DBData'}{'strTeamCustomStr13'},
			$self->{'DBData'}{'strTeamCustomStr14'},
			$self->{'DBData'}{'strTeamCustomStr15'},
			$self->{'DBData'}{'dblTeamCustomDbl1'},
			$self->{'DBData'}{'dblTeamCustomDbl2'},
			$self->{'DBData'}{'dblTeamCustomDbl3'},
			$self->{'DBData'}{'dblTeamCustomDbl4'},
			$self->{'DBData'}{'dblTeamCustomDbl5'},
			$self->{'DBData'}{'dblTeamCustomDbl6'},
			$self->{'DBData'}{'dblTeamCustomDbl7'},
			$self->{'DBData'}{'dblTeamCustomDbl8'},
			$self->{'DBData'}{'dblTeamCustomDbl9'},
			$self->{'DBData'}{'dblTeamCustomDbl10'},
			$self->{'DBData'}{'dtTeamCustomDt1'},
			$self->{'DBData'}{'dtTeamCustomDt2'},
			$self->{'DBData'}{'dtTeamCustomDt3'},
			$self->{'DBData'}{'dtTeamCustomDt4'},
			$self->{'DBData'}{'dtTeamCustomDt5'},
			$self->{'DBData'}{'intTeamCustomLU1'},
			$self->{'DBData'}{'intTeamCustomLU2'},
			$self->{'DBData'}{'intTeamCustomLU3'},
			$self->{'DBData'}{'intTeamCustomLU4'},
			$self->{'DBData'}{'intTeamCustomLU5'},
			$self->{'DBData'}{'intTeamCustomLU6'},
			$self->{'DBData'}{'intTeamCustomLU7'},
			$self->{'DBData'}{'intTeamCustomLU8'},
			$self->{'DBData'}{'intTeamCustomLU9'},
			$self->{'DBData'}{'intTeamCustomLU10'},
			$self->{'DBData'}{'intTeamCustomBool1'},
			$self->{'DBData'}{'intTeamCustomBool2'},
			$self->{'DBData'}{'intTeamCustomBool3'},
			$self->{'DBData'}{'intTeamCustomBool4'},
			$self->{'DBData'}{'intTeamCustomBool5'},
			$self->{'DBData'}{'strWebURL'},
			$self->{'DBData'}{'strUniformTopColour'},
			$self->{'DBData'}{'strUniformBottomColour'},
			$self->{'DBData'}{'strUniformNumber'},
			$self->{'DBData'}{'strAltUniformTopColour'},
			$self->{'DBData'}{'strAltUniformBottomColour'},
			$self->{'DBData'}{'strAltUniformNumber'},
			$self->{'DBData'}{'strTeamNotes'},
			$self->{'DBData'}{'strLadderName'},
			$self->{'DBData'}{'intVenue1ID'},
			$self->{'DBData'}{'intVenue2ID'},
			$self->{'DBData'}{'intVenue3ID'},
			$self->{'DBData'}{'dtStartTime1'},
			$self->{'DBData'}{'dtStartTime2'},
			$self->{'DBData'}{'dtStartTime3'},
			$self->ID(),
			$self->assocID()
		);	
	}
	else	{
		$st=qq[
			INSERT INTO tblTeam (
				intAssocID, 
				strTeamNo, 
				intClubID, 
				strName, 
				strContact, 
				strAddress1, 
				strAddress2, 
				strSuburb, 
				strPostalCode, 
				strState, 
				strPhone1, 
				strPhone2, 
				strEmail, 
				strExtKey, 
				strNickname, 
				dtRegistered, 
				strCountry, 
				dtExpiry, 
				strContactTitle, 
				strContactTitle2, 
				strContactName2, 
				strContactEmail2, 
				strContactPhone2, 
				strContactTitle3, 
				strContactName3, 
				strContactEmail3, 
				strContactPhone3, 
				intTeamCreatedFrom, 
				dtTeamCreatedOnline, 
				strTeamCustomStr1, 
				strTeamCustomStr2, 
				strTeamCustomStr3, 
				strTeamCustomStr4, 
				strTeamCustomStr5, 
				strTeamCustomStr6, 
				strTeamCustomStr7, 
				strTeamCustomStr8, 
				strTeamCustomStr9, 
				strTeamCustomStr10, 
				strTeamCustomStr11, 
				strTeamCustomStr12, 
				strTeamCustomStr13, 
				strTeamCustomStr14, 
				strTeamCustomStr15, 
				dblTeamCustomDbl1, 
				dblTeamCustomDbl2, 
				dblTeamCustomDbl3, 
				dblTeamCustomDbl4, 
				dblTeamCustomDbl5, 
				dblTeamCustomDbl6, 
				dblTeamCustomDbl7, 
				dblTeamCustomDbl8, 
				dblTeamCustomDbl9, 
				dblTeamCustomDbl10, 
				dtTeamCustomDt1, 
				dtTeamCustomDt2, 
				dtTeamCustomDt3, 
				dtTeamCustomDt4, 
				dtTeamCustomDt5, 
				intTeamCustomLU1, 
				intTeamCustomLU2, 
				intTeamCustomLU3, 
				intTeamCustomLU4, 
				intTeamCustomLU5, 
				intTeamCustomLU6, 
				intTeamCustomLU7, 
				intTeamCustomLU8, 
				intTeamCustomLU9, 
				intTeamCustomLU10, 
				intTeamCustomBool1, 
				intTeamCustomBool2, 
				intTeamCustomBool3, 
				intTeamCustomBool4, 
				intTeamCustomBool5, 
				strWebURL, 
				strUniformTopColour, 
				strUniformBottomColour, 
				strUniformNumber, 
				strAltUniformTopColour, 
				strAltUniformBottomColour, 
				strAltUniformNumber, 
				strTeamNotes, 
				strLadderName, 
				intVenue1ID, 
				intVenue2ID, 
				intVenue3ID,
				dtStartTime1,
				dtStartTime2,
				dtStartTime3
			)
			VALUES (
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?,
				?
			)
		];
		my $q = $self->{'db'}->prepare($st);
		$q->execute(
			$self->assocID(),
			$self->{'DBData'}{'strTeamNo'},
			$self->{'DBData'}{'intClubID'},
			$self->{'DBData'}{'strName'},
			$self->{'DBData'}{'strContact'},
			$self->{'DBData'}{'strAddress1'},
			$self->{'DBData'}{'strAddress2'},
			$self->{'DBData'}{'strSuburb'},
			$self->{'DBData'}{'strPostalCode'},
			$self->{'DBData'}{'strState'},
			$self->{'DBData'}{'strPhone1'},
			$self->{'DBData'}{'strPhone2'},
			$self->{'DBData'}{'strEmail'},
			$self->{'DBData'}{'strExtKey'},
			$self->{'DBData'}{'strNickname'},
			$self->{'DBData'}{'dtRegistered'},
			$self->{'DBData'}{'strCountry'},
			$self->{'DBData'}{'dtExpiry'},
			$self->{'DBData'}{'strContactTitle'},
			$self->{'DBData'}{'strContactTitle2'},
			$self->{'DBData'}{'strContactName2'},
			$self->{'DBData'}{'strContactEmail2'},
			$self->{'DBData'}{'strContactPhone2'},
			$self->{'DBData'}{'strContactTitle3'},
			$self->{'DBData'}{'strContactName3'},
			$self->{'DBData'}{'strContactEmail3'},
			$self->{'DBData'}{'strContactPhone3'},
			$self->{'DBData'}{'intTeamCreatedFrom'},
			$self->{'DBData'}{'dtTeamCreatedOnline'},
			$self->{'DBData'}{'strTeamCustomStr1'},
			$self->{'DBData'}{'strTeamCustomStr2'},
			$self->{'DBData'}{'strTeamCustomStr3'},
			$self->{'DBData'}{'strTeamCustomStr4'},
			$self->{'DBData'}{'strTeamCustomStr5'},
			$self->{'DBData'}{'strTeamCustomStr6'},
			$self->{'DBData'}{'strTeamCustomStr7'},
			$self->{'DBData'}{'strTeamCustomStr8'},
			$self->{'DBData'}{'strTeamCustomStr9'},
			$self->{'DBData'}{'strTeamCustomStr10'},
			$self->{'DBData'}{'strTeamCustomStr11'},
			$self->{'DBData'}{'strTeamCustomStr12'},
			$self->{'DBData'}{'strTeamCustomStr13'},
			$self->{'DBData'}{'strTeamCustomStr14'},
			$self->{'DBData'}{'strTeamCustomStr15'},
			$self->{'DBData'}{'dblTeamCustomDbl1'},
			$self->{'DBData'}{'dblTeamCustomDbl2'},
			$self->{'DBData'}{'dblTeamCustomDbl3'},
			$self->{'DBData'}{'dblTeamCustomDbl4'},
			$self->{'DBData'}{'dblTeamCustomDbl5'},
			$self->{'DBData'}{'dblTeamCustomDbl6'},
			$self->{'DBData'}{'dblTeamCustomDbl7'},
			$self->{'DBData'}{'dblTeamCustomDbl8'},
			$self->{'DBData'}{'dblTeamCustomDbl9'},
			$self->{'DBData'}{'dblTeamCustomDbl10'},
			$self->{'DBData'}{'dtTeamCustomDt1'},
			$self->{'DBData'}{'dtTeamCustomDt2'},
			$self->{'DBData'}{'dtTeamCustomDt3'},
			$self->{'DBData'}{'dtTeamCustomDt4'},
			$self->{'DBData'}{'dtTeamCustomDt5'},
			$self->{'DBData'}{'intTeamCustomLU1'},
			$self->{'DBData'}{'intTeamCustomLU2'},
			$self->{'DBData'}{'intTeamCustomLU3'},
			$self->{'DBData'}{'intTeamCustomLU4'},
			$self->{'DBData'}{'intTeamCustomLU5'},
			$self->{'DBData'}{'intTeamCustomLU6'},
			$self->{'DBData'}{'intTeamCustomLU7'},
			$self->{'DBData'}{'intTeamCustomLU8'},
			$self->{'DBData'}{'intTeamCustomLU9'},
			$self->{'DBData'}{'intTeamCustomLU10'},
			$self->{'DBData'}{'intTeamCustomBool1'},
			$self->{'DBData'}{'intTeamCustomBool2'},
			$self->{'DBData'}{'intTeamCustomBool3'},
			$self->{'DBData'}{'intTeamCustomBool4'},
			$self->{'DBData'}{'intTeamCustomBool5'},
			$self->{'DBData'}{'strWebURL'},
			$self->{'DBData'}{'strUniformTopColour'},
			$self->{'DBData'}{'strUniformBottomColour'},
			$self->{'DBData'}{'strUniformNumber'},
			$self->{'DBData'}{'strAltUniformTopColour'},
			$self->{'DBData'}{'strAltUniformBottomColour'},
			$self->{'DBData'}{'strAltUniformNumber'},
			$self->{'DBData'}{'strTeamNotes'},
			$self->{'DBData'}{'strLadderName'},
			$self->{'DBData'}{'intVenue1ID'},
			$self->{'DBData'}{'intVenue2ID'},
			$self->{'DBData'}{'intVenue3ID'},
			$self->{'DBData'}{'dtStartTime1'},
			$self->{'DBData'}{'dtStartTime2'},
			$self->{'DBData'}{'dtStartTime3'}
		);	
	}
}

sub venues	{
	my($self)=@_;
	my @venues=();
	for my $k (qw(intVenue1ID intVenue2ID intVenue3ID))	{
		push @venues, $self->{'DBData'}{$k}	if $self->{'DBData'}{$k};
	}
	return \@venues;
}


sub canDelete {
    my $self = shift;
 
    my $dbh = $self->{db};
    my $teamID = $self->ID();

    # No Members - tblMember_Teams
    # No Competitions tblComp_Teams. If records don't exist in tblComp_Teams, 
    # shouldn't exist in tblCompRounds, tblCompMatches,tblCompTeamStats.
    my $query1 = qq[SELECT COUNT(*) FROM tblMember_Teams
                    WHERE intTeamID = $teamID
                    AND intStatus != $Defs::RECSTATUS_DELETED
                    ];
        
    my $count1 = $dbh->selectrow_array($query1);
        
    my $query2 = qq[SELECT COUNT(*) FROM tblComp_Teams
                    WHERE intTeamID = $teamID
                    AND intRecStatus != $Defs::RECSTATUS_DELETED
                     ];

    my $count2 = $dbh->selectrow_array($query2);

    if ($count1 == 0 && $count2 == 0) {
        return 1;
    }
    else {
        return 0;
    }

}
 
sub delete {
    my $self = shift;
    
    my $dbh = $self->{db};
    my $teamID = $self->ID();
    
    my $statement = qq[UPDATE tblTeam
                       SET intRecStatus = -1 
                       WHERE intTeamID = $teamID];
    
    
    if ($self->canDelete()) {
        $dbh->do($statement);
        if ($dbh->err()) {
            return "ERROR:$dbh->errstr()";
        }  
        else {
            return 1;
        }
    }
    else {
        return 0;
    }
}

1;
