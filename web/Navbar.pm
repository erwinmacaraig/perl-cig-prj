#
# $Header: svn://svn/SWM/trunk/web/Navbar.pm 11450 2014-05-01 04:32:28Z sliu $
#

package Navbar;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(navBar );
@EXPORT_OK = qw(navBar );

use strict;
use DBI;
use lib '.';
use Reg_common;
use Defs;
use Utils;
use ConfigOptions;
use Duplicates;
use PaymentSplitUtils;
use MD5;
use InstanceOf;
use PageMain;
use ServicesContacts;
use TTTemplate;
use Log;
use Data::Dumper;

sub navBar {
    my(
        $Data, 
        $DataAccess_ref, 
        $SystemConfig
    ) = @_;

    my $clientValues_ref=$Data->{'clientValues'};
    my $currentLevel = $clientValues_ref->{INTERNAL_tempLevel} ||  $clientValues_ref->{currentLevel};
    my $currentID = getID($clientValues_ref);
    $clientValues_ref->{memberID} = $Defs::INVALID_ID if $currentLevel > $Defs::LEVEL_MEMBER;
    $clientValues_ref->{memberID} = $Defs::INVALID_ID if $currentLevel > $Defs::LEVEL_CLUB;
    $clientValues_ref->{clubID} = $Defs::INVALID_ID  if $currentLevel >= $Defs::LEVEL_ASSOC;
    $clientValues_ref->{zoneID} = $Defs::INVALID_ID if $currentLevel >= $Defs::LEVEL_REGION;
    $clientValues_ref->{regionID} = $Defs::INVALID_ID if $currentLevel >= $Defs::LEVEL_NATIONAL;
    $clientValues_ref->{nationalID} = $Defs::INVALID_ID if $currentLevel >= $Defs::LEVEL_INTZONE;
    $clientValues_ref->{natID} = $Defs::INVALID_ID if $currentLevel >= $Defs::LEVEL_INTZONE;
    $clientValues_ref->{intzonID} = $Defs::INVALID_ID if $currentLevel >= $Defs::LEVEL_INTREGION;
    $clientValues_ref->{intregID} = $Defs::INVALID_ID if $currentLevel == $Defs::LEVEL_INTERNATIONAL;

    my ($navTree, $navObjects) = GenerateTree($Data, $clientValues_ref);

    my $client=setClient($clientValues_ref);

    my $menu_template = 'navbar/menu.templ';
    my $menu_data = undef;
    if(
        $currentLevel == $Defs::LEVEL_TOP
            or $currentLevel == $Defs::LEVEL_INTERNATIONAL
            or $currentLevel == $Defs::LEVEL_INTREGION
            or $currentLevel == $Defs::LEVEL_INTZONE
            or $currentLevel == $Defs::LEVEL_NATIONAL
            or $currentLevel == $Defs::LEVEL_STATE
            or $currentLevel == $Defs::LEVEL_REGION
            or $currentLevel == $Defs::LEVEL_ZONE 
    ) {
        $menu_data = getEntityMenuData(
            $Data,
            $currentLevel,
            $currentID,
            $client,
            $navObjects->{$currentLevel},
        );
    }
    elsif( $currentLevel == $Defs::LEVEL_CLUB) {
        $menu_data = getClubMenuData(
            $Data,
            $currentLevel,
            $currentID,
            $client,
            $navObjects->{$currentLevel},
        );
    }
    elsif( $currentLevel == $Defs::LEVEL_MEMBER) {
        $menu_data = getMemberMenuData(
            $Data,
            $currentLevel,
            $currentID,
            $client,
            $navObjects->{$currentLevel},
        );
    }

    my $menu = '';
    if($menu_data and $menu_template) {
        $menu_data->{'client'} = $client;
        my %TemplateData= (
            MenuData => $menu_data,
        );
        $menu = runTemplate(
            $Data,
            \%TemplateData,
            $menu_template
        ) || '';
    }

    my $homeClient = getHomeClient($Data);

    my %HomeAction = (
        $Defs::LEVEL_INTERNATIONAL =>  'E_HOME',
        $Defs::LEVEL_INTREGION =>  'E_HOME',
        $Defs::LEVEL_INTZONE =>  'E_HOME',
        $Defs::LEVEL_NATIONAL =>  'E_HOME',
        $Defs::LEVEL_STATE =>  'E_HOME',
        $Defs::LEVEL_REGION =>  'E_HOME',
        $Defs::LEVEL_ZONE =>  'E_HOME',
        $Defs::LEVEL_CLUB =>  'C_HOME',
        $Defs::LEVEL_MEMBER =>  'M_HOME',
    );

    my %TemplateData= (
        NavTree => $navTree,
        Menu => $menu,
        HomeURL => "$Data->{'target'}?client=$homeClient&amp;a=".$HomeAction{$Data->{'clientValues'}{'authLevel'}},
    );
    my $templateFile = 'navbar/navbar_main.templ';
    my $navbar = runTemplate(
        $Data,
        \%TemplateData,
        $templateFile
    );

    return $navbar;
}

sub getEntityMenuData {
    my (
        $Data,
        $currentLevel,
        $currentID,
        $client,
        $entityObj,
    ) = @_;


    my $target=$Data->{'target'} || '';
    my $lang = $Data->{'lang'} || '';
    my %cvals=getClient($client);
    $cvals{'currentLevel'}=$currentLevel ;
    $client=setClient(\%cvals);
    my $SystemConfig = $Data->{'SystemConfig'};
    my $txt_SeasonsNames= $SystemConfig->{'txtSeasons'} || 'Seasons';
    my $txt_AgeGroupsNames= $SystemConfig->{'txtAgeGroups'} || 'Age Groups';

    my $nextlevel = getNextEntityType(
        $Data->{'db'}, 
        $currentID,
    );
    my $next_level_name = $Data->{'LevelNames'}{$nextlevel.'_P'} || '';

    my $hideClearances = $entityObj->getValue('intHideClearances');

    my $option='E_L';
    my $txt_Clr = $SystemConfig->{'txtCLR'} || 'Clearance';
    my $txt_Clr_ListOnline = $SystemConfig->{'txtCLRListOnline'} || "List Online $txt_Clr"."s";

    my $paymentSplitSettings = getPaymentSplitSettings($Data);
    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        advancedsearch => {
            name => $lang->txt('Advanced Search'),
            url => $baseurl."a=SEARCH_F",
        },
        reports => {
            name => $lang->txt('Reports'),
            url => $baseurl."a=REP_SETUP",
        },
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=E_HOME",
        },
    );
    if($nextlevel) {
        $menuoptions{'nextlevel'} = {
            name => $lang->txt($next_level_name),
            url => $baseurl.";a=$option&amp;l=$nextlevel",
        };
    }

    if($paymentSplitSettings->{'psBanks'}) {
        $menuoptions{'bankdetails'} = {
            name => $lang->txt('Payment Configuration'),
            url => $baseurl."a=BA_",
        };
    }

    $menuoptions{'usermanagement'} = {
        name => $lang->txt('User Management'),
        url  => $baseurl."a=AM_",
    };

    if( $nextlevel ) {
        $menuoptions{'fieldconfig'} = {
            name => $lang->txt('Field Configuration'),
            url => $baseurl."a=FC_C_d",
        };

        if($SystemConfig->{'AllowClearances'} 
                and !$hideClearances
                and (!$Data->{'ReadOnlyLogin'} 
                    or  $SystemConfig->{'Overide_ROL_RequestClearance'})
        ) {
            $menuoptions{'clearances'} = {
                name => $lang->txt($txt_Clr_ListOnline),
                url => $baseurl."a=CL_list",
            };
            $menuoptions{'clearancesettings'} = {
                name => $lang->txt("$txt_Clr Settings"),
                url => $baseurl."a=CLRSET_",
            };
            if(
                $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL and 
                !$SystemConfig->{'clrHideSearchAll'}
            ) {
                $menuoptions{'clearancesAll'} = {
                    name => $lang->txt("Search ALL Online $txt_Clr"."s"),
                    url => $baseurl."a=CL_list&amp;showAll=1",
                };
            }
        }
        if ($SystemConfig->{'AllowCardPrinting'}) {
            $menuoptions{'cardprinting'} = {
                name => $lang->txt('Card Printing'),
                url => $baseurl."a=MEMCARD_BL",
            };
        }

        if ($SystemConfig->{'AllowPendingRegistration'}) {
            $menuoptions{'pendingregistration'} = {
                name => $lang->txt('Pending Registration'),
                url => $baseurl."a=M_PRS_L",
            };
        }

        #nationalrego. enable regoforms at entity level.
        if  ($SystemConfig->{'AllowOnlineRego_entity'}) {
            $menuoptions{'registrationforms'} = {
                name => $lang->txt('Registration Forms'),
                url => $baseurl."a=A_ORF_r",
            };
        }

        if($currentLevel == $Defs::LEVEL_NATIONAL) {
            #National Level Only
            if( $SystemConfig->{'AllowOldBankSplit'}) {
                $menuoptions{'bankfileexport'} = {
                    name => $lang->txt("Bank File Export"),
                    url => $baseurl."a=BANKSPLIT_",
                };
            }
            if($paymentSplitSettings->{'psRun'} 
                    and ! $SystemConfig->{'AllowOldBankSplit'}) {
                $menuoptions{'paymentsplitrun'} = {
                    name => $lang->txt("Payment Split Run"),
                    url => $baseurl."a=PSR_opt",
                };
            }

            if ($SystemConfig->{'AllowSeasons'}) {
                $menuoptions{'seasons'} = {
                    name => $lang->txt($txt_SeasonsNames),
                    url => $baseurl."a=SE_L",
                };
                $menuoptions{'agegroups'} = {
                    name => $lang->txt($txt_AgeGroupsNames),
                    url => $baseurl."a=AGEGRP_L",
                };
            }
            if($SystemConfig->{'AllowTXNs'}) {
                $menuoptions{'products'} = {
                    name => $lang->txt('Products'),
                    url => $baseurl."a=A_PR_",
                };
            }
        }
    }

    # for Entity menu

    if(!$SystemConfig->{'NoAuditLog'}) {
        $menuoptions{'auditlog'} = {
            name => $lang->txt('Audit Log'),
            url => $baseurl."a=AL_",
        };
    }

    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt($next_level_name), 'menu','nextlevel'],
        [ $lang->txt($txt_Clr.'s'), 'menu', [
        'clearances',    
        'clearancesAll',
        ]],
        [ $lang->txt('Registrations'), 'menu',[
        'bankdetails',
        'bankfileexport',
        'paymentsplitrun',
        'products',
        'registrationforms', #nationalrego. enable regoforms at entity level.
        ]],
        [ $lang->txt('Reports'), 'menu',[
        'reports',
        ]],
        [ $lang->txt('Search'), 'search',[
        'advancedsearch',
        'nataccredsearch',
        ]],
        [ $lang->txt('System'), 'system',[
        'usermanagement',
        'fieldconfig',
        'clearancesettings',
        'seasons',
        'agegroups',
        'mrt_admin',
        'auditlog',
        'optin',
        ]],
    );

    my $menudata = processmenudata(\%menuoptions, \@menu_structure);
    return $menudata;

}

sub getAssocMenuData {
    my (
        $Data,
        $currentLevel,
        $currentID,
        $client,
        $assocObj,
    ) = @_;

    my $target=$Data->{'target'} || '';
    my $lang = $Data->{'lang'} || '';
    my %cvals=getClient($client);
    $cvals{'currentLevel'}=$currentLevel ;
    $client=setClient(\%cvals);
    my $SystemConfig = $Data->{'SystemConfig'};
    my $txt_SeasonsNames= $SystemConfig->{'txtSeasons'} || 'Seasons';
    my $txt_AgeGroupsNames= $SystemConfig->{'txtAgeGroups'} || 'Age Groups';
    my $txt_Clr = $SystemConfig->{'txtCLR'} || 'Clearance';
    my $txt_Clr_ListOnline = $SystemConfig->{'txtCLRListOnline'} || "List Online $txt_Clr"."s";
    my $txt_Clr_ListOffline = "List Offline $txt_Clr"."s";

    my $swol_url = $Defs::SWOL_URL;
    $swol_url = $Defs::SWOL_URL_v6 if ($Data->{'SystemConfig'}{'AssocConfig'}{'olrv6'});
    my $DataAccess_ref = $Data->{'DataAccess'};


    my (
        $intAllowClearances, 
        $intSWOL,
        $hideAssocRollover,
        $hideClubRollover,
        $hideAllCheckbox,
        $intAllowRegoForm,
        $intAllowSeasons,
    ) = $assocObj->getValue([
        'intAllowClearances', 
        'intSWOL',
        'intHideRollover',
        'intClubRollover',
        'intHideAllRolloverCheckbox',
        'intAllowRegoForm',
        'intAllowSeasons',
        ]);
    $intSWOL = 0 if !$SystemConfig->{'AllowSWOL'};

    my $paymentSplitSettings = getPaymentSplitSettings($Data);

    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        advancedsearch => {
            name => $lang->txt('Advanced Search'),
            url => $baseurl."a=SEARCH_F",
        },
        reports => {
            name => $lang->txt('Reports'),
            url => $baseurl."a=REP_SETUP",
        },
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=A_HOME",
        },
        members => {
            name => $lang->txt('List '.$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'}),
            url => $baseurl."a=M_L&amp;l=$Defs::LEVEL_MEMBER",
        },
    );

    if (
        $Data->{'Permissions'}{'OtherOptions'}{ShowClubs} 
            or !$SystemConfig->{'NoClubs'}) {
        $menuoptions{'clubs'} = {
            name => $lang->txt('List '.$Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'}),
            url => $baseurl."a=C_L&amp;l=$Defs::LEVEL_CLUB",
        };
    }
    if ($SystemConfig->{'AssocServices'} and !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'services'} = {
            name => $lang->txt('Locator'),
            url => $baseurl."a=A_SV_DTE",
        };
    }

    #first can the person looking see any other options anyway
    my $data_access=$DataAccess_ref->{$Defs::LEVEL_ASSOC}{$currentID};
    #$data_access=$Defs::DATA_ACCESS_FULL;
    if (
        $data_access==$Defs::DATA_ACCESS_FULL 
            or $data_access==$Defs::DATA_ACCESS_READONLY
    ) {

        if($SystemConfig->{'AllowClearances'} 
                and $intAllowClearances
        ) {
            $menuoptions{'clearances'} = {
                name => $lang->txt($txt_Clr_ListOnline),
                url => $baseurl."a=CL_list",
            };
        }
        if($SystemConfig->{'DisplayOffLineClearances'}
                and $intAllowClearances
        )       {
            $menuoptions{'clearancesoff'} = {
                name => $lang->txt($txt_Clr_ListOffline),
                url => $baseurl."a=CL_offlist",
            };
        }


        if (
            $data_access==$Defs::DATA_ACCESS_FULL
                and !$Data->{'ReadOnlyLogin'}
                and allowedAction($Data,'a_e')
        ) {
            $menuoptions{'usermanagement'} = {
                name => $lang->txt('User Management'),
                url => $baseurl."a=AM_",
            };
            if(!$SystemConfig->{'NoConfig'}) {
                $menuoptions{'settings'} = {
                    name => $lang->txt('Settings'),
                    url => $baseurl."a=A_O_m",
                };
            }

            if(isCheckDupl($Data)) {
                $menuoptions{'duplicates'} = {
                    name => $lang->txt('Duplicate Resolution'),
                    url => $baseurl."a=DUPL_L",
                };
            }

            if (allowedAction($Data,'ba_e')) {
                if($paymentSplitSettings->{'psBanks'}) {
                    $menuoptions{'bankdetails'} = {
                        name => $lang->txt('Payment Configuration'),
                        url => $baseurl."a=BA_",
                    };
                }
            }
            if($paymentSplitSettings->{'psSplits'}) {
                $menuoptions{'paymentsplits'} = {
                    name => $lang->txt('Payment Splits'),
                    url => $baseurl."a=A_PS_showsplits",
                };
            }

            if ($SystemConfig->{'AllowCardPrinting'}) {
                $menuoptions{'cardprinting'} = {
                    name => $lang->txt('Card Printing'),
                    url => $baseurl."a=MEMCARD_BL",
                };
            }

            if ($SystemConfig->{'AllowPendingRegistration'}) {
                $menuoptions{'pendingregistration'} = {
                    name => $lang->txt('Pending Registration'),
                    url => $baseurl."a=M_PRS_L",
                };
            }

            if($SystemConfig->{'AllowTXNs'}) {
                $menuoptions{'products'} = {
                    name => $lang->txt('Products'),
                    url => $baseurl."a=A_PR_",
                };
            }   
            if (
                $intAllowRegoForm
                    and (
                    $Data->{'SystemConfig'}{'AllowOnlineRego'}
                        or $Data-> {'Permissions'}{'OtherOptions'}{'AllowOnlineRego'}
                )
            ) {
                $menuoptions{'registrationforms'} = {
                    name => $lang->txt('Registration Forms'),
                    url => $baseurl."a=A_ORF_r",
                };
            }

        }
    }

    if(
        $intAllowSeasons
            and ((!$Data->{'SystemConfig'}{'LockSeasons'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideAll'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideAssoc'}) or $Data->{'SystemConfig'}{'AssocConfig'}{'Rollover_AddRollover_Override'})
            and !$hideAssocRollover
            and allowedAction($Data, 'm_e')) {
        $menuoptions{'memberrollover'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}.' Rollover'),
            url => $baseurl."a=M_LSRO&amp;l=$Defs::LEVEL_MEMBER",
        };
    }

    if (
        $Data->{'SystemConfig'}{'AllowMemberTransfers'}
            and allowedAction($Data, 'a_e')
    ) {
        $menuoptions{'transfermember'} = {
            url => $baseurl."a=M_TRANSFER&amp;l=$Defs::LEVEL_MEMBER",
            name => $Data->{'SystemConfig'}{'transferMemberText'} || $lang->txt('Transfer Member'),
        };
    }


    # for assoc menu
    if(!$SystemConfig->{'NoAuditLog'}) {
        $menuoptions{'auditlog'} = {
            name => $lang->txt('Audit Log'),
            url => $baseurl."a=AL_",
        };
    }

    #if ($Data->{'SystemConfig'}{'DefaultListAction'} and $Data->{'SystemConfig'}{'DefaultListAction'} eq 'SUMM') {
    #push @assoc_options, [ $target, { client => $nc, a => 'A_SUMM' }, $textLabels{'Association Summary'}, ];
    #}

    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'}), 'menu', [
        'members',
        'duplicates',
        'clearances',    
        'clearancesoff',    
        'memberrollover',
        'transfermember',
        'cardprinting',
        'pendingregistration',
        ]],
        [ $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'}), 'menu', [
        'clubs',
        'clubchampionships',
        ]],
        [ $lang->txt('Registrations'), 'menu',[
        'bankdetails',
        'products',
        'registrationforms',
        'paymentsplits',
        'services',
        ]],
        [ $lang->txt('Reports'), 'menu',[
        'reports',
        ]],
        [ $lang->txt('Search'), 'search',[
        'advancedsearch',
        'nataccredsearch',
        ]],
        [ $lang->txt('System'), 'system',[
        'settings',
        'usermanagement',
        'seasons',
        'processlog',
        'mrt_admin',
        'auditlog',
        ]],
    );

    my $menudata = processmenudata(\%menuoptions, \@menu_structure);
    return $menudata;

}

sub getClubMenuData {
    my (
        $Data,
        $currentLevel,
        $currentID,
        $client,
        $clubObj,
        $assocObj,
    ) = @_;

    my $target=$Data->{'target'} || '';
    my $lang = $Data->{'lang'} || '';
    my %cvals=getClient($client);
    $cvals{'currentLevel'}=$currentLevel ;
    $client=setClient(\%cvals);
    my $SystemConfig = $Data->{'SystemConfig'};
    my $txt_SeasonsNames= $SystemConfig->{'txtSeasons'} || 'Seasons';
    my $txt_AgeGroupsNames= $SystemConfig->{'txtAgeGroups'} || 'Age Groups';
    my $txt_Clr = $SystemConfig->{'txtCLR'} || 'Clearance';
    my $txt_Clr_ListOnline = $SystemConfig->{'txtCLRListOnline'} || "List Online $txt_Clr"."s";
    my $DataAccess_ref = $Data->{'DataAccess'};

    my (
        $intAllowClearances, 
        $intAllowClubClrAccess,
        $intAllowRegoForm,
        $assocID,
        $hideAssocRollover,
        $hideClubRollover,
        $intAllowSeasons,
    ) = $assocObj->getValue([
        'intAllowClearances', 
        'intAllowClubClrAccess',
        'intAllowRegoForm',
        'intAssocID',
        'intHideRollover',
        'intHideClubRollover',
        'intAllowSeasons',
        ]);
    $intAllowClubClrAccess = 1 if ($Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC);

    my $paymentSplitSettings = getPaymentSplitSettings($Data);

    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        advancedsearch => {
            name => $lang->txt('Advanced Search'),
            url => $baseurl."a=SEARCH_F",
        },
        reports => {
            name => $lang->txt('Reports'),
            url => $baseurl."a=REP_SETUP",
        },
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=C_HOME",
        },
        members => {

            name => $lang->txt('List '.$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'}),
            url => $baseurl."a=M_L&amp;l=$Defs::LEVEL_MEMBER",
        },
    );
    my $txt_RequestCLR = $SystemConfig->{'txtRequestCLR'} || 'Request a Clearance';

    if ($SystemConfig->{'AllowPendingRegistration'}) {
        $menuoptions{'pendingregistration'} = {
            name => $lang->txt('Pending Registration'),
            url => $baseurl."a=M_PRS_L",
        };
    }

    if($SystemConfig->{'AllowClearances'} 
            and $intAllowClearances
            and $intAllowClubClrAccess
            and !$SystemConfig->{'TurnOffRequestClearance'} 
    ) {
        if(!$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'newclearance'} = {
                name => $lang->txt($txt_RequestCLR),
                url => $baseurl."a=CL_createnew",
            };
        }
        if (
            $Data->{'ReadOnlyLogin'} 
                or $SystemConfig->{'Overide_ROL_RequestClearance'}) {
            $menuoptions{'newclearance'} = {
                name => $lang->txt($txt_RequestCLR),
                url => $baseurl."a=CL_createnew",
            };
        }
    }
    #first can the person looking see any other options anyway
    my $data_access=$DataAccess_ref->{$Defs::LEVEL_CLUB}{$currentID};
    $data_access=$Defs::DATA_ACCESS_FULL;

    if (
        $data_access==$Defs::DATA_ACCESS_FULL 
            or $data_access==$Defs::DATA_ACCESS_READONLY
    ) {

        if($SystemConfig->{'AllowClearances'} 
                and $intAllowClearances
                and (!$Data->{'ReadOnlyLogin'} or
                $SystemConfig->{'Overide_ROL_RequestClearance'}
            )
        ){
            $menuoptions{'clearances'} = {
                name => $lang->txt($txt_Clr_ListOnline),
                url => $baseurl."a=CL_list",
            };
            $menuoptions{'clearancesettings'} = {
                name => $lang->txt("$txt_Clr Settings"),
                url => $baseurl."a=CLRSET_",
            };
        }

        if (
            $data_access==$Defs::DATA_ACCESS_FULL
                and !$Data->{'ReadOnlyLogin'}
                and allowedAction($Data,'c_e')
        ) {

            $menuoptions{'fieldconfig'} = {
                name => $lang->txt('Field Configuration'),
                url => $baseurl."a=FC_C_d",
            };
            $menuoptions{'usermanagement'} = {
                name => $lang->txt('User Management'),
                url => $baseurl."a=AM_",
            };
            if ( $Data->{'SystemConfig'}{'AllowMemberTransfers'}  and allowedAction($Data, 'c_e')) {
                $menuoptions{'transfermember'} = {
                    url => $baseurl."a=M_TRANSFER&amp;l=$Defs::LEVEL_MEMBER",
                    name => $Data->{'SystemConfig'}{'transferMemberText'} || $lang->txt('Transfer Member'),
                };
            }

            if (allowedAction($Data,'c_e')) {
                if($paymentSplitSettings->{'psBanks'}) {
                    $menuoptions{'bankdetails'} = {
                        name => $lang->txt('Payment Configuration'),
                        url => $baseurl."a=BA_",
                    };
                }
            }
            if ($SystemConfig->{'AssocClubServices'}) {
                $menuoptions{'locator'} = {
                    name => $lang->txt('Locator'),
                    url => $baseurl."a=A_SV_DTE",
                };
            }

            if($SystemConfig->{'AllowTXNs'}
                    and $SystemConfig->{'AllowClubTXNs'}
            ) {
                $menuoptions{'products'} = {
                    name => $lang->txt('Products'),
                    url => $baseurl."a=A_PR_",
                };
            }   
            if (
                $intAllowRegoForm
                    and (
                    $Data->{'SystemConfig'}{'AllowOnlineRego'}
                        or $Data-> {'Permissions'}{'OtherOptions'}{'AllowOnlineRego'}
                )
                    and !$Data->{'ReadOnlyLogin'}
            ) {
                $menuoptions{'registrationforms'} = {
                    name => $lang->txt('Registration Forms'),
                    url => $baseurl."a=A_ORF_r",
                };
            }

        }
    }

    $hideClubRollover = '' if ($hideClubRollover == 2 and $Data->{'clientValues'}{'authLevel'} > $Defs::LEVEL_CLUB);
    if(
        $intAllowSeasons
            and ((!$Data->{'SystemConfig'}{'LockSeasons'}
                    and !$Data->{'SystemConfig'}{'LockSeasonsCRL'}
                    and !$Data->{'SystemConfig'}{'Club_MemberEditOnly'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideAll'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideClub'}) or $Data->{'SystemConfig'}{'AssocConfig'}{'Rollover_AddRollover_Override'})
            and !$hideAssocRollover
            and !$hideClubRollover
            and allowedAction($Data, 'm_e')) {
        $menuoptions{'memberrollover'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}.' Rollover'),
            url => $baseurl."a=M_LSRO&amp;l=$Defs::LEVEL_MEMBER",
        };
    }

    # for club menu

    if(!$SystemConfig->{'NoAuditLog'}) {
        $menuoptions{'auditlog'} = {
            name => $lang->txt('Audit Log'),
            url => $baseurl."a=AL_",
        };
    }
    if(!$SystemConfig->{'NoOptIn'}) {
        $menuoptions{'optin'} = {
            name => $lang->txt('Opt-Ins'),
            url => $baseurl."a=OPTIN_L",
        };
    }
    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_MEMBER.'_P'}), 'menu', [
        'members',
        'newclearance',    
        'clearances',    
        'memberrollover',
        'transfermember',
        'pendingregistration',
        ]],
        [ $lang->txt('Registrations'), 'menu',[
        'bankdetails',
        'products',
        'registrationforms',
        'locator',
        ]],
        [ $lang->txt('Reports'), 'menu',[
        'reports',
        ]],
        [ $lang->txt('Search'), 'search',[
        'advancedsearch',
        'nataccredsearch',
        ]],
        [ $lang->txt('System'), 'system',[
        'fieldconfig',
        'member_record_types',
        'passwordmanagement',
        'usermanagement',
        'clearancesettings',
        'mrt_admin',
        'auditlog',
        'optin',
        ]],
    );

    my $menudata = processmenudata(\%menuoptions, \@menu_structure);
    return $menudata;

}

sub getNextEntityType {
    my($db, $ID) = @_;
    my $nextlevelType='';
    my $looptimes=0;
    do  {
        return 0 if !$ID;
        $looptimes++;
        my $st=qq[
        SELECT CN.intEntityID as CNintEntityID, CN.intTypeID AS CNintTypeID, CN.intStatusID, PN.intTypeID AS PNType
        FROM tblEntity AS PN 
        LEFT JOIN tblEntityLinks ON PN.intEntityID=tblEntityLinks.intParentEntityID 
        LEFT JOIN tblEntity AS CN ON CN.intEntityID=tblEntityLinks.intChildEntityID
        WHERE PN.intEntityID = ?
        LIMIT 1
        ];
        my $query = $db->prepare($st);
        $query->execute($ID);
        my $dref=$query->fetchrow_hashref();
        $query->finish();
        if(!$dref->{CNintEntityID})   {
            #No child entitys
            #Check to see if we are a zone - if so check for assocs
            if($dref->{'PNType'} == $Defs::LEVEL_ZONE)  {
                my $sta=qq[ SELECT COUNT(*) FROM tblAssoc_Entity WHERE intEntityID= ? LIMIT 1 ];
                my $q= $db->prepare($sta);
                $q->execute($ID);
                my ($assocs)=$q->fetchrow_array();
                $q->finish();
                $assocs||=0;
                return ($assocs ? $Defs::LEVEL_ASSOC : 0);
            }
            else    {   return 0;   }
        }
        #return 0 if !$dref->{intEntityID};
        return $dref->{CNintTypeID} if $dref->{intStatusID} != $Defs::NODE_HIDE;
        $ID=$dref->{CNintEntityID};
    } while ($looptimes < 8); #This shouldn't happen more than 8 times
}   

sub getNavIcons {
    my($Data,$icons)=@_;

    my $navicons='';
    for my $row (@{$icons}) {
        $navicons.=qq~<a href="$row->[0]"><img title="$row->[1]" alt="$row->[1]" src="images/$row->[2]" border="0"></a>~;
    }
    $navicons=qq[ <div class="navicons">$navicons</div> ] if $navicons;
    return $navicons;
}


sub GenerateTree {
    my ($Data, $clientValues_ref) = @_;

    my @tree = ();
    my %objects = ();
    my %instancetypes = (
        interID => ['entity', $Defs::LEVEL_INTERNATIONAL, 'E_HOME', ''],
        intregID => ['entity', $Defs::LEVEL_INTREGION, 'E_HOME', ''],
        intzonID => ['entity', $Defs::LEVEL_INTZONE, 'E_HOME', ''],
        natID => ['entity', $Defs::LEVEL_NATIONAL, 'E_HOME', ''],
        stateID => ['entity', $Defs::LEVEL_STATE, 'E_HOME', ''],
        regionID => ['entity', $Defs::LEVEL_REGION, 'E_HOME', ''],
        zoneID => ['entity', $Defs::LEVEL_ZONE, 'E_HOME', ''],
        clubID => ['club', $Defs::LEVEL_CLUB, 'C_HOME', ''],
        memberID => ['member', $Defs::LEVEL_MEMBER, 'M_HOME', ''],
    );
    for my $level (qw(
        interID
        intregID
        intzonID
        natID
        stateID
        regionID
        zoneID
        clubID
        memberID
        )) {
        my $id = $clientValues_ref->{$level} || 0;
        if(
            $id 
                and $id != $Defs::INVALID_ID
        ) {
            my %tempClientRef = %{$clientValues_ref};
            my $instancetype = $instancetypes{$level}[0] || next;
            my $levelType = $instancetypes{$level}[1] || next;
            my $action = $instancetypes{$level}[2] || '';
            my $namefield = $instancetypes{$level}[3] || 'strName';
            my $obj = getInstanceOf($Data, $instancetype, $id) || next;
            $tempClientRef{'currentLevel'} = $levelType;
            my $client=setClient(\%tempClientRef);
            my $url = "$Data->{'target'}?client=$client&amp;a=$action";
            my $name = $obj->name();
            $objects{$levelType} = $obj;
            next if $levelType > $clientValues_ref->{'authLevel'};
            push @tree, {
                name => $name,
                type => $levelType,
                url => $url,
                levelname => $Data->{'LevelNames'}{$levelType},
            };
        }
    }

    return (
        \@tree,
        \%objects,
    );
}

sub processmenudata {
    my(
        $menuoptions, 
        $menu_structure
    ) = @_;

    my %menudata = ();
    for my $toplevel  (@{$menu_structure}) {
        my @menu = ();
        if(ref $toplevel->[2]) {
            for my $sub (@{$toplevel->[2]}) {
                push @menu, $menuoptions->{$sub} if $menuoptions->{$sub};
            }
        }
        else {
            push @menu, $menuoptions->{$toplevel->[2]} if $menuoptions->{$toplevel->[2]};
        }
        my $numitems = scalar(@menu);
        next if !$numitems;
        push @{$menudata{$toplevel->[1]}}, {
            name => $toplevel->[0],
            numitems => $numitems,
            items => \@menu,
        };

    }
    return \%menudata;
}


sub getMemberMenuData {
    my (
        $Data,
        $currentLevel,
        $currentID,
        $client,
        $memberObj,
        $assocObj,
    ) = @_;

    my $target=$Data->{'target'} || '';
    my $lang = $Data->{'lang'} || '';
    my %cvals=getClient($client);
    $cvals{'currentLevel'}=$currentLevel ;
    $client=setClient(\%cvals);
    my $SystemConfig = $Data->{'SystemConfig'};
    my $txt_SeasonsNames= $SystemConfig->{'txtSeasons'} || 'Seasons';
    my $txt_Clrs = $Data->{'SystemConfig'}{'txtCLRs'} || 'Clearances';
    my $DataAccess_ref = $Data->{'DataAccess'};
    my $accreditation_title = exists $Data->{'SystemConfig'}{'ACCRED_Custom_Name'} ? $Data->{'SystemConfig'}{'ACCRED_Custom_Name'}.'s' : "Accreditations";


    my ($intOfficial) = $memberObj->getValue('intOfficial');
    my $clubs = $Data->{'SystemConfig'}{'NoClubs'} ? 0 : 1;
    my $clr= ($assocObj->getValue('intAllowClearances') and $Data->{'SystemConfig'}{'AllowClearances'});

    my $invalid_club = 0;
    if (
        $Data->{'clientValues'}{'clubID'} 
            and $Data->{'clientValues'}{'clubID'} !=$Defs::INVALID_ID 
            and $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB
    )   {
        my $st = qq[
        SELECT MAX(intStatus)   
        FROM tblMember_Clubs
        WHERE intMemberID = ?
            AND intClubID = ?
        ];
        my $qry= $Data->{'db'}->prepare($st);
        $qry->execute($Data->{'clientValues'}{memberID}, $Data->{'clientValues'}{'clubID'});
        my($mcStatus)= $qry->fetchrow_array();
        $qry->finish;
        if ($mcStatus != $Defs::RECSTATUS_ACTIVE)   {
            $invalid_club = 1;
        }
    }
    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=M_HOME",
        },
    );
    if(!$invalid_club) {
        if(!$SystemConfig->{'NoAuditLog'}) {
            $menuoptions{'auditlog'} = {
                name => $lang->txt('Audit Log'),
                url => $baseurl."a=AL_",
            };
        }
        if(!$SystemConfig->{'NoMemberTypes'}) {
            $menuoptions{'membertypes'} = {
                name => $lang->txt('Member Types'),
                url => $baseurl."a=M_MT_LIST",
            };
        }
        if ($SystemConfig->{'NationalAccreditation'} or $SystemConfig->{'AssocConfig'}{'NationalAccreditation'}) {
            $menuoptions{'accreditation'} = {
                name => $lang->txt($accreditation_title),
                url => $baseurl."a=M_NACCRED_LIST",
            };
        }
        if($SystemConfig->{'AllowTXNs'} 
                and (
                (allowedAction($Data, 'm_tran') and $Data->{'clientValues'}{authLevel} == $Defs::LEVEL_TEAM)
                    or $Data->{'clientValues'}{authLevel} != $Defs::LEVEL_TEAM
            )
        ) {
            my $txns_link_name = $SystemConfig->{'txns_link_name'} || $lang->txt('Transactions');
            $menuoptions{'transactions'} = {
                url => $baseurl."a=M_TXNLog_list",
            };
        }
        if($clubs) {
            $menuoptions{'clubs'} = {
                name => $lang->txt('Clubs'),
                url => $baseurl."a=M_CLUBS",
            };
        }
        if($SystemConfig->{'AllowSeasons'})  {
            $menuoptions{'seasons'} = {
                name => $lang->txt($txt_SeasonsNames),
                url => $baseurl."a=M_SEASONS",
            };
        }
        if($clr) {
            $menuoptions{'clr'} = {
                name => $lang->txt($txt_Clrs),
                url => $baseurl."a=M_CLR",
            };
        }
    }


    $Data->{'SystemConfig'}{'TYPE_NAME_3'} = '' if not exists $Data->{'SystemConfig'}{'TYPE_NAME_3'};
    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt('Types'), 'menu','membertypes'],
        [ $lang->txt($SystemConfig->{'txns_link_name'} || 'Transactions'), 'menu','transactions'],
        [ $lang->txt($txt_Clrs), 'menu','clr'],
        [ $lang->txt('Member History'), 'menu',[
        'clubs',
        'seasons',
        ]],
        [ $lang->txt('System'), 'system',[
        'auditlog',
        ]],
    );

    my $menudata = processmenudata(\%menuoptions, \@menu_structure );
    return $menudata;

}

# vim: set et sw=4 ts=4:
1;
