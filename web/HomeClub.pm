package HomeClub;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(showClubHome);
@EXPORT_OK =qw(showClubHome);

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

sub showClubHome  {
  my ($Data, $clubID)=@_;

  my $client = $Data->{'client'} || '';
  my $clubObj = getInstanceOf($Data, 'club');

  my ($welcome, $killmessage) = getWelcomeText($Data, $clubID);
  $killmessage ||= 0;
  return ($killmessage,'') if $killmessage;
  my $allowedit = allowedAction($Data, 'c_e') ? 1 : 0;
  my $logo = showLogo(
      $Data,
      $Defs::LEVEL_CLUB,
      $clubID,
      $client,
      $allowedit,
    );
  my $scMenu = $allowedit
    ? getServicesContactsMenu($Data, $Defs::LEVEL_CLUB, $clubID, $Defs::SC_MENU_SHORT,0)
    : '';
  my $contacts = getLocatorContacts($Data,1);
    ## lets clean up some stuff for now
    $scMenu = '';
    $contacts = '';
  my ($dashboard, undef) = showDashboard(
    $Data,
    $client,
    $Defs::LEVEL_CLUB,
    $clubID,
  );
    ### Lets clear Dashboard graphs for now
    $dashboard = '';


  my ($notifications, $notificationCount)  = getNotifications(
    $Data,
    $Defs::LEVEL_CLUB,
    $clubID,
  );
  
  #my @ctrlMatrix = ([1,1],[0,0]);
  #my $controlEdit = $ctrlMatrix[( ($clubObj->getValue('strStatus') eq 'ACTIVE') ? 1 : 0 )][$Data->{'ReadOnlyLogin'}];
  #($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL) ? $controlEdit = 0 : undef;
  
   my $readonly = !( ($clubObj->getValue('strStatus') eq 'ACTIVE' ? 1 : 0) || ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 1 : 0 ) );
   $Data->{'ReadOnlyLogin'} ? $readonly = 1 : undef;
  
  my $name = $clubObj->name();

    #ContactsMenu => $scMenu,
    #Contacts => $contacts,
  my %TemplateData = (
    Welcome => $welcome,
    ReadOnlyLogin => $readonly,
    Logo => $logo,
    Name => $name,
    EditDetailsLink => "$Data->{'target'}?client=$client&amp;a=C_DTE",
    EditContactsLink => "$Data->{'target'}?client=$client&amp;a=CON_LIST",
    EditDashboardLink => "$Data->{'target'}?client=$client&amp;a=DASHCFG_",
    Dashboard => $dashboard,
    Notifications => $notifications,
    Details => {
      Address => $clubObj->getValue('strAddress') || '',
      Town => $clubObj->getValue('strTown') || '',
      Region => $clubObj->getValue('strRegion') || '',
      Country => $clubObj->getValue('strISOCountry') || '',
      PostalCode => $clubObj->getValue('strPostalCode') || '',
      Phone => $clubObj->getValue('strPhone') || '',
      Fax => $clubObj->getValue('strFax') || '',
      Email => $clubObj->getValue('strEmail') || '',
    },
  );
  my $resultHTML = runTemplate(
    $Data,
    \%TemplateData,
    'dashboards/club.templ',
  );

  my $title = $name;
  return ($resultHTML, '');
}


1;

