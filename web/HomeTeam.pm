#
# $Header: svn://svn/SWM/trunk/web/HomeTeam.pm 9793 2013-10-21 04:33:10Z fkhezri $
#

package HomeTeam;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showTeamHome);
@EXPORT_OK =qw(showTeamHome);

use lib "dashboard",'..';

use strict;
use Defs;
use Reg_common;
use Utils;
use Welcome;
use InstanceOf;

use Logo;
use TTTemplate;
use Notifications;

require Team;

sub showTeamHome	{
	my ($Data, $teamID)=@_;

	my $client = $Data->{'client'} || '';
	my $teamObj = getInstanceOf($Data, 'team');
	my $assocObj = getInstanceOf($Data, 'assoc');

  my ($welcome, $killmessage) = getWelcomeText($Data);
  $killmessage ||= 0;
  return ($killmessage,'') if $killmessage;
	my $allowedit = allowedAction($Data, 't_e') ? 1 : 0;
	my $logo = showLogo(
      $Data,
      $Defs::LEVEL_TEAM,
      $teamID,
      $client,
      $allowedit,
	);
	my ($notifications, $notificationCount) = getNotifications(
		$Data,
		$Defs::LEVEL_TEAM,
		$teamID,
	);
	my $compID;
	my $hascomp=0;
	if($Data->{'SystemConfig'}{'AssocConfig'}{'allowTeamIfNotInSeason'}) {
 		my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
		$compID = $teamObj->TeamInComp($assocSeasons->{'newRegoSeasonID'});
	} else{
		$compID = $teamObj->TeamInComp(0);
	}
	$hascomp=1 if $compID;

my $assigntocomplink = '';
if ((!$hascomp or $Data->{'SystemConfig'}{'AssocConfig'}{'showAssignTeamToCompBTN'} )  and !$Data->{'ReadOnlyLogin'} and ($Data->{'clientValues'}{authLevel} >= $Defs::LEVEL_ASSOC or allowedAction($Data, 'ac_a')))
{
$assigntocomplink = "<div style='float:right'><span class = 'button-small generic-button'><a href='$Data->{'target'}?client=$client&amp;a=T_CA'>Assign to Competition</a></span></div>";
}

	my $name = $teamObj->name();
	my $compHistory = Team::showTeamComps($Data, $teamID);

    my %Extras = '';

    if ($Data->{'SystemConfig'}->{'HighlightTeamUnpaid'} and allowedAction($Data, 'm_e')) {
        my $assocID  = $assocObj->getValue('intAssocID');
        my $payFees  = checkForUnpaidTrans($Data, $assocID, $teamID);
        $Extras{'payFeesAction'} = 'T_TXNLog_list' if $payFees;
    }

    if ($Data->{'SystemConfig'}->{'AllowInviteTeammates'} and allowedAction($Data, 'm_e') and $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_TEAM) {
        $Extras{'inviteTeammatesAction'} = 'T_IT';
    }

    if (%Extras) {
        $Extras{'target'} = $Data->{'target'};
        $Extras{'client'} = $client;
    }

	my %TemplateData = (
		Welcome               => $welcome,
		ReadOnlyLogin         => $Data->{'ReadOnlyLogin'},
		Logo                  => $logo,
		Name                  => $name.$assigntocomplink,
		EditDetailsLink       => "$Data->{'target'}?client=$client&amp;a=T_DTE",
		Notifications         => $notifications,
		compHistory           => $compHistory,
		Details               => {
			Nickname          => $teamObj->getValue('strNickname')       || '',
			ContactTitle      => $teamObj->getValue('strContactTitle')   || '',
			Contact           => $teamObj->getValue('strContact')        || '',
			Address1          => $teamObj->getValue('strAddress1')       || '',
			Address2          => $teamObj->getValue('strAddress2')       || '',
			Suburb            => $teamObj->getValue('strSuburb')         || '',
			State             => $teamObj->getValue('strState')          || '',
			Country           => $teamObj->getValue('strCountry')        || '',
			PostalCode        => $teamObj->getValue('strPostalCode')     || '',
			Phone1            => $teamObj->getValue('strPhone1')         || '',
			Phone2            => $teamObj->getValue('strPhone2')         || '',
			Mobile            => $teamObj->getValue('strMobile')         || '',
			Email             => $teamObj->getValue('strEmail')          || '',
  
			ContactTitle2     => $teamObj->getValue('strContactTitle2')  || '',
			Contact2          => $teamObj->getValue('strContactName2')   || '',
			Contact2Mobile    => $teamObj->getValue('strContactMobile2') || '',
			Contact2Phone     => $teamObj->getValue('strContactPhone2')  || '',
			Contact2Email     => $teamObj->getValue('strContactEmail2')  || '',

			ContactTitle3     => $teamObj->getValue('strContactTitle3')  || '',
			Contact3          => $teamObj->getValue('strContactName3')   || '',
			Contact3Phone     => $teamObj->getValue('strContactPhone3')  || '',
			Contact3Mobile    => $teamObj->getValue('strContactMobile3') || '',
			Contact3Email     => $teamObj->getValue('strContactEmail3')  || '',

		},
        Extras                => \%Extras,

	);
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/team.templ',
	);

  $Data->{'NoHeadingAd'} = 1;

	my $title = $name;
	return ($resultHTML, '');
}

sub checkForUnpaidTrans {
    my ($Data, $assocID, $teamID) = @_;

    my $sql = qq[
        SELECT 
            count(T.intTransactionID)
        FROM 
            tblTransactions AS T
            INNER JOIN tblProducts AS P ON (P.intProductID=T.intProductID)
        WHERE
            T.intStatus=? AND P.intProductType<>? AND T.intAssocID=? AND T.intID=? AND T.intTableType=?
        GROUP BY 
            T.intTransactionID
     ];

    my $query = $Data->{'db'}->prepare($sql);
    $query->execute(0, 2, $assocID, $teamID, $Defs::LEVEL_TEAM);

	my ($count) = $query->fetchrow_array();
    $count ||= 0;
    
    return $count;
}

1;

