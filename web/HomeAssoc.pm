#
# $Header: svn://svn/SWM/trunk/web/HomeAssoc.pm 8251 2013-04-08 09:00:53Z rlee $
#

package HomeAssoc;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showAssocHome);
@EXPORT_OK =qw(showAssocHome);

use lib "dashboard";

use strict;
use Reg_common;
use Utils;
use Welcome;
use InstanceOf;

use ServicesContacts;
use Contacts;
use Logo;
use TTTemplate;
use Dashboard;
use Notifications;

sub showAssocHome	{
	my ($Data, $assocID)=@_;

	my $client = $Data->{'client'} || '';
	my $assocObj = getInstanceOf($Data, 'assoc');

  my ($welcome, $killmessage) = getWelcomeText($Data);
  $killmessage ||= 0;
  return ($killmessage,'') if $killmessage;
	my $allowedit = allowedAction($Data, 'a_e') ? 1 : 0;
	my $logo = showLogo(
      $Data,
      $Defs::LEVEL_ASSOC,
      $assocID,
      $client,
      $allowedit,
    );
  my $scMenu = $allowedit
		? getServicesContactsMenu($Data, $Defs::LEVEL_ASSOC, $assocID, $Defs::SC_MENU_SHORT,0)
		: '';
	my $contacts = getLocatorContacts($Data,1);
	if ($Data->{'SystemConfig'}{'DisplayAssocOfficials'}) { 
		my $assocOfficials = loadAssocOfficials($Data->{'db'}, $assocID);
	}

	my ($dashboard, undef) = showDashboard(
    $Data,
    $client,
    $Defs::LEVEL_ASSOC,
    $assocID,
  );
	my ($notifications, $notificationCount) = getNotifications(
		$Data,
		$Defs::LEVEL_ASSOC,
    $assocID,
	);



	my $name = $assocObj->name();
	my %TemplateData = (
		ReadOnlyLogin => $Data->{'ReadOnlyLogin'},
		Welcome => $welcome,
		Logo => $logo,
		Name => $name,
		ContactsMenu => $scMenu,
		Contacts => $contacts,
		EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=A_DTE",
		EditContactsLink => "$Data->{'target'}?client=$client&amp;a=CON_LIST",
		EditDashboardLink => "$Data->{'target'}?client=$client&amp;a=DASHCFG_",
		Dashboard => $dashboard,
		Notifications => $notifications,
		notificationCount => $notificationCount,
		viewAllNotificationsLink=> "$Data->{'target'}?client=$client&amp;a=NOTS_L",
		Details => {
			Address1 => $assocObj->getValue('strAddress1') || '',
			Address2 => $assocObj->getValue('strAddress2') || '',
			Suburb => $assocObj->getValue('strSuburb') || '',
			State => $assocObj->getValue('strState') || '',
			Country => $assocObj->getValue('strCountry') || '',
			PostalCode => $assocObj->getValue('strPostalCode') || '',
			Phone => $assocObj->getValue('strPhone') || '',
			Fax => $assocObj->getValue('strFax') || '',
			Email => $assocObj->getValue('strEmail') || '',
		},
	);
	my $resultHTML = runTemplate(
		$Data,
		\%TemplateData,
		'dashboards/assoc.templ',
	);

	$Data->{'NoHeadingAd'} = 1;
	my $title = $name;
	return ($resultHTML, '');
}


1;

