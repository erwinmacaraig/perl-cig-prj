#
# $Header: svn://svn/SWM/trunk/web/HomeNode.pm 8251 2013-04-08 09:00:53Z rlee $
#

package HomeNode;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showNodeHome);
@EXPORT_OK =qw(showNodeHome);

use lib "dashboard";

use strict;
use Reg_common;
use Utils;
use Welcome;
use InstanceOf;

use Logo;
use TTTemplate;
use Dashboard;
use Notifications;

sub showNodeHome	{
	my ($Data, $nodeID)=@_;

	my $client = $Data->{'client'} || '';
	my $nodeObj = getInstanceOf($Data, 'node', $nodeID);

  my ($welcome, $killmessage) = getWelcomeText($Data);
  $killmessage ||= 0;
  return ($killmessage,'') if $killmessage;
	my $allowedit = allowedAction($Data, 'n_e') ? 1 : 0;
	my $logo = showLogo(
      $Data,
      $Defs::LEVEL_NODE,
      $nodeID,
      $client,
      $allowedit,
    );

	my ($dashboard, undef) = showDashboard(
    $Data,
    $client,
    $Defs::LEVEL_NODE,
    $nodeID,
  );
	my ($notifications, $notificationCount) = getNotifications(
		$Data,
		$Defs::LEVEL_NODE,
    $nodeID,
	);

	my $name = $nodeObj->name();
	my %TemplateData = (
		Welcome => $welcome,
		Logo => $logo,
		Name => $name,
		ReadOnlyLogin => $Data->{'ReadOnlyLogin'},
		EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=N_DTE",
		EditDashboardLink => "$Data->{'target'}?client=$client&amp;a=DASHCFG_",
		Dashboard => $dashboard,
		Notifications => $notifications,
		Details => {
			Address1 => $nodeObj->getValue('strAddress1') || '',
			Address2 => $nodeObj->getValue('strAddress2') || '',
			Suburb => $nodeObj->getValue('strSuburb') || '',
			State => $nodeObj->getValue('strState') || '',
			Country => $nodeObj->getValue('strCountry') || '',
			PostalCode => $nodeObj->getValue('strPostalCode') || '',
			Phone => $nodeObj->getValue('strPhone') || '',
			Fax => $nodeObj->getValue('strFax') || '',
			Email => $nodeObj->getValue('strEmail') || '',
			Contact => $nodeObj->getValue('strContact') || '',
		},
	);
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/node.templ',
	);

	$Data->{'NoHeadingAd'} = 1;
	my $title = $name;
	return ($resultHTML, '');
}


1;

