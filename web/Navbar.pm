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
use DuplicatesUtils;
#use PaymentSplitUtils;
use MD5;
use InstanceOf;
use PageMain;
use ServicesContacts;
use TTTemplate;
use Log;
use Data::Dumper;
use PersonRegisterWhat;

sub navBar {
    my(
        $Data, 
        $DataAccess_ref, 
        $SystemConfig
    ) = @_;
#develop

    my $clientValues_ref=$Data->{'clientValues'};
    my $currentLevel = $clientValues_ref->{INTERNAL_tempLevel} ||  $clientValues_ref->{currentLevel};
    my $authLevel = $clientValues_ref->{authLevel};
    my $currentID = getID($clientValues_ref);
    $clientValues_ref->{personID} = $Defs::INVALID_ID if $currentLevel > $Defs::LEVEL_PERSON;
    $clientValues_ref->{clubID} = $Defs::INVALID_ID  if $currentLevel > $Defs::LEVEL_CLUB;
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
    elsif( $currentLevel == $Defs::LEVEL_PERSON) {
        $menu_data = getPersonMenuData(
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
        $Defs::LEVEL_PERSON =>  'P_HOME',
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

    my $children = getEntityChildrenTypes($Data->{'db'}, $currentID, $Data->{'Realm'});

    my $hideClearances = $entityObj->getValue('intHideClearances');

    my $txt_Clr = $lang->txt('Transfer');
    my $txt_Clr_ListOnline = $lang->txt('List Online Transfers');

    my $paymentSplitSettings = ''; #getPaymentSplitSettings($Data);
    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        advancedsearch => {
            name => $lang->txt('Advanced Search'),
            url => $baseurl."a=SEARCH_F",
        },
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=E_HOME",
        },
    );
    if($currentLevel != $Data->{'clientValues'}{'authLevel'})   {
        delete($menuoptions{'home'});
    }
    if($SystemConfig->{'allowReports'})  {
        $menuoptions{'reports'} = {
            name => $lang->txt('Reports'),
            url => $baseurl."a=REP_SETUP",
        };
    }
    if(exists $children->{$Defs::LEVEL_STATE})    {
        $menuoptions{'states'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_STATE.'_P'}),
            url => $baseurl."a=E_L&amp;l=$Defs::LEVEL_STATE",
        };
    }
    if(exists $children->{$Defs::LEVEL_REGION})    {
        $menuoptions{'regions'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_REGION.'_P'}),
            url => $baseurl."a=E_L&amp;l=$Defs::LEVEL_REGION",
        };
    }
    if(exists $children->{$Defs::LEVEL_ZONE})    {
        $menuoptions{'zones'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_ZONE.'_P'}),
            url => $baseurl."a=E_L&amp;l=$Defs::LEVEL_ZONE",
        };
    }
    #if(exists $children->{$Defs::LEVEL_CLUB})    {
        $menuoptions{'clubs'} = {
            name => $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_CLUB.'_P'}),
            url => $baseurl."a=C_L&amp;l=$Defs::LEVEL_CLUB",
        };
    #}
    #if(exists $children->{$Defs::LEVEL_VENUE})    {
    if($SystemConfig->{'allowVenues'})  {
        $menuoptions{'venues'} = {
            name => $lang->txt('Venues'),
            url => $baseurl."a=VENUE_L&amp;l=$Defs::LEVEL_VENUE",
        };
    }
    #if(exists $children->{$Defs::LEVEL_PERSON})    {
        $menuoptions{'persons'} = {
            name => $lang->txt("List Persons"),
            url => $baseurl."a=P_L&amp;l=$Defs::LEVEL_PERSON",
        };
    #}
    if($SystemConfig->{'menu_newperson_PLAYER_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addplayer'} = {
            name => $lang->txt('Add Player'),
            url => $baseurl."a=PF_&amp;dtype=PLAYER",
        };
    }
    if($SystemConfig->{'menu_newperson_COACH_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addcoach'} = {
            name => $lang->txt('Add Coach'),
            url => $baseurl."a=PF_&amp;dtype=COACH",
        };
    }
    if($currentLevel == $Defs::LEVEL_NATIONAL and $SystemConfig->{'menu_newperson_MAOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addmaofficial'} = {
             name => $lang->txt('Add MA Official'),
            url => $baseurl."a=PF_&amp;dtype=MAOFFICIAL",
        };
    }
    if($SystemConfig->{'menu_newperson_RAOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addraofficial'} = {
             name => $lang->txt('Add RA Official'),
            url => $baseurl."a=PF_&amp;dtype=RAOFFICIAL",
        };
    }
    if($currentLevel == $Defs::LEVEL_CLUB and $SystemConfig->{'menu_newperson_TEAMOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addteamofficial'} = {
            name => $lang->txt('Add Team Official'),
            url => $baseurl."a=PF_&amp;dtype=TEAMOFFICIAL",
        };
    }
    if($currentLevel == $Defs::LEVEL_CLUB and $SystemConfig->{'menu_newperson_CLUBOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addclubofficial'} = {
            name => $lang->txt('Add Club Official'),
            url => $baseurl."a=PF_&amp;dtype=CLUBOFFICIAL",
        };
    }
    if($SystemConfig->{'menu_newperson_REFEREE_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_addofficial'} = {
            name => $lang->txt('Add Referee'),
            url => $baseurl."a=PF_&amp;dtype=REFEREE",
            };
    }
    if($SystemConfig->{'menu_searchpeople_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'persons_search'} = {
            name => $lang->txt('Search'),
            url => $baseurl."a=INITSRCH_P&type=default&amp;origin=" . $Data->{'clientValues'}{'authLevel'},
            };
    }

    #if($paymentSplitSettings->{'psBanks'}) {
    #    $menuoptions{'bankdetails'} = {
    #        name => $lang->txt('Payment Configuration'),
    #        url => $baseurl."a=BA_",
    #    };
    #}


        $menuoptions{'approvals'} = {
            name => $lang->txt('Work Tasks'),
            url => $baseurl."a=WF_",
        };
        $menuoptions{'myAssociation'} = {
            name => $lang->txt('My Association'),
            url => $baseurl."a=EE_D",
        };

    
        $menuoptions{'pending'} = {
            name => $lang->txt('Pending Registrations'),
            url => $baseurl."a=PENDPR_",
        };
        $menuoptions{'incomplete'} = {
            name => $lang->txt('Incomplete Registrations'),
            url => $baseurl."a=INCOMPLPR_",
        };

        if ($SystemConfig->{'allowBulkRenewals'})   {
            $menuoptions{'bulk'} = {
                name => $lang->txt('Bulk Renewals'),
                url => $baseurl."a=PFB_", #PREGFB_T",
            };
        }
        $menuoptions{'entityregistrationallowed'} = {
            name => $lang->txt('Registrations Allowed'),
            url => $baseurl."a=ERA_",
        };

        if($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL)   {
            $menuoptions{'usermanagement'} = {
                name => $lang->txt('User Management'),
                url => $baseurl."a=AM_",
            };
        }

    if( 1==2 and scalar(keys $children)) {
        $menuoptions{'fieldconfig'} = {
            name => $lang->txt('Field Configuration'),
            url => $baseurl."a=FC_C_d",
    };

        if(1==2 and $SystemConfig->{'AllowClearances'} 
                and !$hideClearances
                and (!$Data->{'ReadOnlyLogin'} 
                    or  $SystemConfig->{'Overide_ROL_RequestClearance'})
        ) {
            $menuoptions{'clearances'} = {
                name => $lang->txt($txt_Clr_ListOnline),
                url => $baseurl."a=CL_list",
            };
            $menuoptions{'clearancesettings'} = {
                name => $lang->txt("Clearances Settings"),
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
                url => $baseurl."a=P_PRS_L",
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
            #if($paymentSplitSettings->{'psRun'} 
            #        and ! $SystemConfig->{'AllowOldBankSplit'}) {
            #    $menuoptions{'paymentsplitrun'} = {
            #        name => $lang->txt("Payment Split Run"),
            #        url => $baseurl."a=PSR_opt",
            #    };
            #}

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
        if ($SystemConfig->{'allowDuplicateRes'})   {
            if(isCheckDupl($Data)) {
                $menuoptions{'duplicates'} = {
                    name => $lang->txt('Duplicate Resolution'),
                    url => $baseurl."a=DUPL_L",
                };
            }
        }


        }
    }
                $menuoptions{'products'} = {
                    name => $lang->txt('Products'),
                    url => $baseurl."a=PR_",
                };

    # for Entity menu
    if(($SystemConfig->{'menu_newclub_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} or $SystemConfig->{'menu_newclub_'.$Data->{'clientValues'}{'authLevel'}}) && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'addclub'} = {
             name => $lang->txt("Add Club"),
            url => $baseurl."a=C_DTA",
        };
    }

    if($SystemConfig->{'allowVenues'} && $SystemConfig->{'menu_newvenue_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'addvenue'} = {
             name => $lang->txt("Add Venue"),
            url => $baseurl."a=VENUE_DTA",
        };
    }

    if(!$SystemConfig->{'NoAuditLog'}) {
        $menuoptions{'auditlog'} = {
            name => $lang->txt('Audit Log'),
            url => $baseurl."a=AL_",
        };
    }
    my $txt_RequestCLR = $SystemConfig->{'txtRequestCLR'} || 'Request a Clearance';
if(1==2 and $SystemConfig->{'AllowClearances'} and !$SystemConfig->{'TurnOffRequestClearance'}
    ) {
        if(!$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'newclearance'} = {
                name => $lang->txt($txt_RequestCLR),
                url => $baseurl."a=CL_createnew",
            };
        }
        if (
            $Data->{'ReadOnlyLogin'} or $SystemConfig->{'Overide_ROL_RequestClearance'}) {
            $menuoptions{'newclearance'} = {
                name => $lang->txt($txt_RequestCLR),
                url => $baseurl."a=CL_createnew",
            };
        }
    }
    if ($SystemConfig->{'allowFindPaymentMinLevel'} and $Data->{'clientValues'}{'authLevel'} >= $SystemConfig->{'allowFindPaymentMinLevel'}) {
		$menuoptions{'findpayment'} = { 
			name => $lang->txt('Find Payment'),
			url => $baseurl."a=TXN_FIND",
		}; 
    }
	if ($SystemConfig->{'allowPayInvoice'}) {
		$menuoptions{'bulkpayment'} = { 
			name => $lang->txt('Pay Invoice'),
			url => $baseurl."a=TXN_PAY_INV",
		}; 
		$menuoptions{'payinvoice'} = { 
			name => $lang->txt('Invoices'),
			    url => $baseurl."strInvoiceNumber=&amp;a=TXN_PAY_INV_NUM",
		}; 
    }
		if ($SystemConfig->{'allowPaymentsHistory'})	{
			$menuoptions{'paymenthistory'} = { 
			    name => $lang->txt('Payments History'),
				url => $baseurl."a=P_TXNLog_list",
			};
		}
	# P_TXNLog_list url => $baseurl."a=TXN_PAY_HISTORY",

    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt('States'), 'menu','states'],
        [ $lang->txt('Regions'), 'menu','regions'],
        [ $lang->txt('Zones'), 'menu','zones'],
        [ $lang->txt('Clubs'), 'menu',[
            'clubs',
            'addclub'
        ]],
        [ $lang->txt('Venues'), 'menu',[
            'venues',

            'addvenue'
        ]],
        [ $lang->txt('People'), 'menu',[
            'persons_search',
            'persons_addplayer',
            'persons_addcoach',
            'persons_addteamofficial',
            'persons_addclubofficial',
            'persons_addofficial',
            'persons_addmaofficial',
            'persons_addraofficial',
            'bulk',
            'persons',
        ]],
        [ $lang->txt('Work Tasks'), 'menu',[
            'approvals',
            'pending',
            'incomplete'
        ]],
        [ $lang->txt('Transfers'), 'menu', [
        'clearances',    
        'newclearance',    
        'clearancesAll',
        ]],
        [ $lang->txt('My Association'), 'menu',[
        'myAssociation',
        ]],
        [ $lang->txt('Payments'), 'menu',[
		    'findpayment',
		    'payinvoice',
		    'bulkpayment',
		    'paymenthistory',
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
        [ $lang->txt('Reports'), 'menu',[ 'reports', ]],
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
    my $txt_Clr_ListOnline = $SystemConfig->{'txtCLRListOnline'} || "List Online Clearances";
    my $DataAccess_ref = $Data->{'DataAccess'};

    my $paymentSplitSettings ='' ; #getPaymentSplitSettings($Data);

    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        advancedsearch => {
            name => $lang->txt('Advanced Search'),
            url => $baseurl."a=SEARCH_F",
        },
        home => {
            name => $lang->txt('Dashboard'),
            url => $baseurl."a=C_HOME",
        },
        persons => {
            name => $lang->txt('List Persons'),
            url => $baseurl."a=P_L&amp;l=$Defs::LEVEL_PERSON",
        },
    );
    if($SystemConfig->{'allowReports'})  {
        $menuoptions{'reports'} = {
            name => $lang->txt('Reports'),
            url => $baseurl."a=REP_SETUP",
        };
    }
    if($SystemConfig->{'allowVenues'})  {
        $menuoptions{'venues'} = {
            name => $lang->txt('List Venues'),
            url => $baseurl."a=VENUE_L&amp;l=$Defs::LEVEL_VENUE",
        };
    }
    if($currentLevel != $Data->{'clientValues'}{'authLevel'})   {
        delete($menuoptions{'home'});
    }
    my $txt_RequestCLR = 'Request a Transfer';

    if(1==2 and $SystemConfig->{'AllowClearances'} and !$SystemConfig->{'TurnOffRequestClearance'} 
    ) {
        if(!$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'newclearance'} = {
                name => $lang->txt($txt_RequestCLR),
                url => $baseurl."a=CL_createnew",
            };
        }
        if (
            $Data->{'ReadOnlyLogin'} or $SystemConfig->{'Overide_ROL_RequestClearance'}) {
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

        if(1==2 and $SystemConfig->{'AllowClearances'} 
                and (!$Data->{'ReadOnlyLogin'} or
                $SystemConfig->{'Overide_ROL_RequestClearance'}
            )
        ){
            $menuoptions{'clearances'} = {
                name => $lang->txt($txt_Clr_ListOnline),
                url => $baseurl."a=CL_list",
            };
            $menuoptions{'clearancesettings'} = {
                name => $lang->txt("Clearances Settings"),
                url => $baseurl."a=CLRSET_",
            };
        }

        if (
            $data_access==$Defs::DATA_ACCESS_FULL
                and !$Data->{'ReadOnlyLogin'}
                and allowedAction($Data,'c_e')
        ) {

            if($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL)   {
                $menuoptions{'usermanagement'} = {
                    name => $lang->txt('User Management'),
                    url => $baseurl."a=AM_",
                };
            }
            if ( $Data->{'SystemConfig'}{'AllowPersonTransfers'}  and allowedAction($Data, 'c_e')) {
                $menuoptions{'transferperson'} = {
                    url => $baseurl."a=P_TRANSFER&amp;l=$Defs::LEVEL_PERSON",
                    name => $Data->{'SystemConfig'}{'transferPersonText'} || $lang->txt('Transfer Person'),
                };
            }

            if (allowedAction($Data,'c_e')) {
                #if($paymentSplitSettings->{'psBanks'}) {
                #    $menuoptions{'bankdetails'} = {
                #        name => $lang->txt('Payment Configuration'),
                #        url => $baseurl."a=BA_",
                #    };
                #}
            }
            if ($SystemConfig->{'AssocClubServices'}) {
                $menuoptions{'locator'} = {
                    name => $lang->txt('Locator'),
                    url => $baseurl."a=A_SV_DTE",
                };
            }
        if ($SystemConfig->{'allowDuplicateRes'})   {
            if(isCheckDupl($Data)) {
                $menuoptions{'duplicates'} = {
                    name => $lang->txt('Duplicate Resolution'),
                    url => $baseurl."a=DUPL_L",
                };
            }
        }
            if($SystemConfig->{'AllowTXNs'}
                    and $SystemConfig->{'AllowClubTXNs'}
            ) {
                $menuoptions{'products'} = {
                    name => $lang->txt('Products'),
                    url => $baseurl."a=PR_",
                };
            }   
        $menuoptions{'approvals'} = {
            name => $lang->txt('Work Tasks'),
            url => $baseurl."a=WF_",
        };
        $menuoptions{'entityregistrationallowed'} = {
            name => $lang->txt('Registrations Allowed'),
            url => $baseurl."a=ERA_",
        };


            if (
                1==2 and (
                $Data->{'SystemConfig'}{'AllowOnlineRego'}
                    or $Data-> {'Permissions'}{'OtherOptions'}{'AllowOnlineRego'}
                    and !$Data->{'ReadOnlyLogin'})
            ) {
                $menuoptions{'registrationforms'} = {
                    name => $lang->txt('Registration Forms'),
                    url => $baseurl."a=A_ORF_r",
                };
            }

        }
    }

    if(
            1==2 and
            (!$Data->{'SystemConfig'}{'LockSeasons'}
                    and !$Data->{'SystemConfig'}{'LockSeasonsCRL'}
                    and !$Data->{'SystemConfig'}{'Club_PersonEditOnly'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideAll'}
                    and !$Data->{'SystemConfig'}{'Rollover_HideClub'}
            )
            and allowedAction($Data, 'm_e')) {
        $menuoptions{'personrollover'} = {
            name => $lang->txt('Person Rollover'),
            url => $baseurl."a=P_LSRO&amp;l=$Defs::LEVEL_PERSON",
        };
    }

    # for club menu

    #if(!$SystemConfig->{'NoAuditLog'}) {
    #    $menuoptions{'auditlog'} = {
    #        name => $lang->txt('Audit Log'),
    #        url => $baseurl."a=AL_",
    #    };
    #}
     if($Data->{'clientValues'}{'authLevel'} > $Defs::LEVEL_CLUB and $SystemConfig->{'AllowTXNs'} and $SystemConfig->{'AllowClubTXNs'}) {
        $menuoptions{'transactions'} = {
            name => $lang->txt('Transactions'),
            url => $baseurl."a=C_TXNLog_list",
        };
     }
        $menuoptions{'pending'} = {
            name => $lang->txt('Pending Registrations'),
            url => $baseurl."a=PENDPR_",
        };
        $menuoptions{'incomplete'} = {
            name => $lang->txt('Incomplete Registrations'),
            url => $baseurl."a=INCOMPLPR_",
        };
      
        $menuoptions{'clubdocs'} = {
        url => $baseurl."a=C_DOCS",
    };
    $menuoptions{'myClub'} = {
        name => $lang->txt('My Club'),
        url => $baseurl."a=EE_D",
    };
    if ($Data->{'clientValues'}{'authLevel'}>= $Defs::LEVEL_NATIONAL )   {
        $menuoptions{'auditlog'} = {
            name => $lang->txt("Audit Trail"),
            url => $baseurl."a=C_HISTLOG",
        };
    }


 
    if (1==2)   {
        $menuoptions{'clubidentifier'} = {
           name => $lang->txt('Bulk Renewals'),
           url => $baseurl."a=C_ID_LIST",
        };
    }

    if ($SystemConfig->{'allowPersonRequest'}) {
        $menuoptions{'requesttransfer'} = {
            name => $lang->txt('Request or start a transfer'),
            url => $baseurl."a=PRA_T",
            #url => $baseurl."a=INITSRCH_P&type=transfer&amp;origin=" . $Data->{'clientValues'}{'authLevel'},
        };
    }

    if ($SystemConfig->{'allowPersonLoans'}) {
        $menuoptions{'requestloan'} = {
            name => $lang->txt('Request a Player loan'),
            url => $baseurl."a=PRA_LOAN",
            #url => $baseurl."a=INITSRCH_P&type=transfer&amp;origin=" . $Data->{'clientValues'}{'authLevel'},
        };
    }


    #hide for now; list is already included in Work Tasks
    if ($SystemConfig->{'allowPersonRequest'}) {
        $menuoptions{'listrequests'} = {
           name => $lang->txt('List Requests'),
           url => $baseurl."a=PRA_L",
        };
    }

    if ($Data->{'clientValues'}{'authLevel'} > $Defs::LEVEL_CLUB or $clubObj->getValue('strStatus') ne $Defs::ENTITY_STATUS_DE_REGISTERED)    {
        if ($SystemConfig->{'allowBulkRenewals'})   {
            $menuoptions{'bulk'} = {
                name => $lang->txt('Bulk Renewals'),
                url => $baseurl."a=PFB_", #PREGFB_T",
            };
        }
        if ($SystemConfig->{'allowFindPaymentMinLevel'} and $Data->{'clientValues'}{'authLevel'} >= $SystemConfig->{'allowFindPaymentMinLevel'}) {
		    $menuoptions{'findpayment'} = { 
			    name => $lang->txt('Find Payment'),
			    url => $baseurl."a=TXN_FIND",
		    }; 
        }
        if ($SystemConfig->{'allowPayInvoice'}) {
		    $menuoptions{'bulkpayment'} = { 
			    name => $lang->txt('Pay Invoice'),
			    url => $baseurl."a=TXN_PAY_INV",
		    }; 
		    $menuoptions{'payinvoice'} = { 
			    name => $lang->txt('Invoices'),
			    url => $baseurl."strInvoiceNumber=&amp;a=TXN_PAY_INV_NUM",
		    }; 
        }
		if ($SystemConfig->{'allowPaymentsHistory'})	{
			$menuoptions{'paymenthistory'} = { 
				name => $lang->txt('Payments History'),
				url => $baseurl."a=P_TXNLog_list",
			};
		}
		# url => $baseurl."a=TXN_PAY_HISTORY"

        if ($SystemConfig->{'allowPersonRequest'}) {
            $menuoptions{'requestaccess'} = {
            name => $lang->txt('Request for Person Details'),
            #url => $baseurl."a=PRA_R",
            url => $baseurl."a=INITSRCH_P&type=access",
            };
        }
        if($SystemConfig->{'menu_newperson_PLAYER_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addplayer'} = {
                name => $lang->txt('Add Player'),
                url => $baseurl."a=PF_&amp;dtype=PLAYER",
            };
        }
        if($SystemConfig->{'menu_newperson_COACH_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addcoach'} = {
                name => $lang->txt('Add Coach'),
                url => $baseurl."a=PF_&amp;dtype=COACH",
            };
        }
        if($currentLevel == $Defs::LEVEL_NATIONAL and $SystemConfig->{'menu_newperson_MAOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addmaofficial'} = {
                 name => $lang->txt('Add MA Official'),
                url => $baseurl."a=PF_&amp;dtype=MAOFFICIAL",
            };
        }
        if($SystemConfig->{'menu_newperson_RAOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addraofficial'} = {
                 name => $lang->txt('Add RA Official'),
                url => $baseurl."a=PF_&amp;dtype=RAOFFICIAL",
            };
        }
        if($currentLevel == $Defs::LEVEL_CLUB and $SystemConfig->{'menu_newperson_TEAMOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addteamofficial'} = {
                name => $lang->txt('Add Team Official'),
                url => $baseurl."a=PF_&amp;dtype=TEAMOFFICIAL",
            };
        }
        if($currentLevel == $Defs::LEVEL_CLUB and $SystemConfig->{'menu_newperson_CLUBOFFICIAL_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addclubofficial'} = {
                name => $lang->txt('Add Club Official'),
                url => $baseurl."a=PF_&amp;dtype=CLUBOFFICIAL",
            };
        } 
        if($SystemConfig->{'menu_newperson_REFEREE_'.$Data->{'clientValues'}{'authLevel'}.'_'.$currentLevel} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_addofficial'} = {
                name => $lang->txt('Add Referee'),
                url => $baseurl."a=PF_&amp;dtype=REFEREE",
                };
        }
        if($SystemConfig->{'menu_searchpeople_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
            $menuoptions{'persons_search'} = {
                name => $lang->txt('Search'),
                url => $baseurl."a=INITSRCH_P&type=default&amp;origin=" . $Data->{'clientValues'}{'authLevel'},
                };
        }


   }



    if($SystemConfig->{'allowVenues'} && $SystemConfig->{'menu_newvenue_'.$Data->{'clientValues'}{'authLevel'}} && !$Data->{'ReadOnlyLogin'}) {
        $menuoptions{'addvenue'} = {
             name => $lang->txt("Add a Venue"),
            url => $baseurl."a=VENUE_DTA",
        };
    }



    my @menu_structure = (
        [ $lang->txt('Dashboard'), 'home','home'],
        [ $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_PERSON.'_P'}), 'menu', [
        'persons_search',
        'persons_addplayer',
        'persons_addcoach',
        'persons_addteamofficial',
        'persons_addclubofficial',
        'persons_addofficial',
        'persons_addmaofficial',
        'persons_addraofficial',

        'requesttransfer',
        'requestloan',
        'requestaccess',
        'newclearance',    
        'clearances',    
        'personrollover',
        'transferperson',
        'pendingregistration',
        'listrequests',
        'duplicates',
        'bulk',
        'persons',
         ]],

        [ $lang->txt($Data->{'LevelNames'}{$Defs::LEVEL_VENUE.'_P'}), 'menu',[
            'venues',
            'addvenue'
        ]],
        [ $lang->txt('Club Work Tasks'), 'menu',[
            'approvals',
            'pending',
            'incomplete'
        ]],
        [ $lang->txt("Club Transactions"), 'menu','transactions',],
        [ $lang->txt('My Club'), 'menu',[
        'myClub',
        ]],
         [ $lang->txt('Audit Trail'), 'menu',[
            'auditlog'
        ]],
         [ $lang->txt('Payments'), 'menu',[
		    'findpayment',
		    'payinvoice',
		    'bulkpayment',
		    'paymenthistory',

        ]],

        [ $lang->txt("Club Documents"), 'menu','clubdocs'],
        [ $lang->txt('Identifiers'), 'menu','clubidentifier'],
        [ $lang->txt('Search'), 'search',[
        'advancedsearch',
        'nataccredsearch',
        ]],
                [ $lang->txt('Reports'), 'menu',[ 'reports', ]],
    );
#[ $lang->txt('System'), 'system',[
#        'usermanagement',
#        'clearancesettings',
#        'mrt_admin',
#        'auditlog',
#        ]],

    my $menudata = processmenudata(\%menuoptions, \@menu_structure);
    return $menudata;

}

sub getEntityChildrenTypes  {
    my($db, $ID, $realmID) = @_;

    my %existingChildren = ();

    my $st = qq[
        SELECT 
            CE.intEntityLevel,
            COUNT(1) as cnt
        FROM
            tblEntityLinks AS EL
            INNER JOIN tblEntity AS CE
                ON EL.intChildEntityID = CE.intEntityID
        WHERE
            EL.intParentEntityID = ?
            AND CE.intDataAccess >= $Defs::DATA_ACCESS_STATS
        GROUP BY
            CE.intEntityLevel
        HAVING
            cnt > 0
    ];
    my $q = $db->prepare($st);
    $q->execute($ID);
    while(my($level, $cnt) = $q->fetchrow_array()) {
        $existingChildren{$level} = 1;
    }
    $st = qq[
        SELECT 
            1
        FROM
            tblPersonRegistration_$realmID
        WHERE
            intEntityID = ?
        LIMIT 1
    ];
    $q = $db->prepare($st);
    $q->execute($ID);
    my ($foundperson) = $q->fetchrow_array();
    $q->finish();
    if($foundperson)    {
        $existingChildren{$Defs::LEVEL_PERSON} = 1;
    }

    return \%existingChildren;
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
        personID => ['person', $Defs::LEVEL_PERSON, 'P_HOME', ''],
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
        personID
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
                levelname => $Data->{'lang'}->txt($Data->{'LevelNames'}{$levelType}),
                ma_phone_number => $Data->{'SystemConfig'}{'ma_phone_number'},
                ma_website => $Data->{'SystemConfig'}{'ma_website'},
                ma_email => $Data->{'SystemConfig'}{'ma_email'},
                help_desk_email => $Data->{'SystemConfig'}{'help_desk_email'},
                help_desk_phone_number => $Data->{'SystemConfig'}{'help_desk_phone_number'},
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


sub getPersonMenuData {
    my (
        $Data,
        $currentLevel,
        $currentID,
        $client,
        $personObj,
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

    my ($intOfficial) = 0;#$personObj->getValue('intOfficial');
    my $clubs = $Data->{'SystemConfig'}{'NoClubs'} ? 0 : 1;
    my $clr= $Data->{'SystemConfig'}{'AllowClearances'} || 0;

    my $baseurl = "$target?client=$client&amp;";
    my %menuoptions = (
        home => {
            name => $lang->txt('Person Dashboard'),
            url => $baseurl."a=P_HOME",
        },
    );
       #if(!$SystemConfig->{'NoAuditLog'}) {
       #    $menuoptions{'auditlog'} = {
       #        name => $lang->txt('Audit Log'),
       #        url => $baseurl."a=AL_",
       #    };
       #}
       if ($SystemConfig->{'NationalAccreditation'} or $SystemConfig->{'AssocConfig'}{'NationalAccreditation'}) {
           $menuoptions{'accreditation'} = {
               name => $lang->txt($accreditation_title),
               url => $baseurl."a=P_NACCRED_LIST",
           };
       }

    my $txns_link_name = $lang->txt('Transactions');
    if($SystemConfig->{'AllowTXNs'}) {
        $menuoptions{'transactions'} = {
		   name => $lang->txt('List Transactions'),
           url => $baseurl."a=P_TXNLog_list",
        };
	   
        if ($Data->{'clientValues'}{'authLevel'} >= $SystemConfig->{'AddTXN_MinLevel'}) {
	        $menuoptions{'addtransactions'} = {
		        name => $lang->txt('Add Transactions'),
                url => $baseurl."a=P_TXN_ADD",
            };
        }
    }
    $menuoptions{'docs'} = {
       url => $baseurl."a=P_DOCS",
    };
    
    $menuoptions{'certificates'} = {
       url => $baseurl."a=P_CERT",
    };
    $menuoptions{'passport'} = {
       url => $baseurl."a=P_PASS",
    };
    if (
        $Data->{'clientValues'}{'authLevel'}>= $Defs::LEVEL_NATIONAL 
        or ($SystemConfig->{'PersonMenus_level'} 
            and $SystemConfig->{'PersonMenus_level'} >= $Data->{'clientValues'}{'authLevel'}
        )
    )   {
        $menuoptions{'auditlog'} = {
            name => $lang->txt("Audit Trail"),
            url => $baseurl."a=P_HISTLOG",
        } if ($Data->{'clientValues'}{'authLevel'}>= $Defs::LEVEL_NATIONAL);

        $menuoptions{'regos'} = {
            name => $lang->txt("Registration History"),
            url => $baseurl."a=P_REGOS",
        };
        if($clr and $Data->{'clientValues'}{'authLevel'}>= $Defs::LEVEL_NATIONAL)    {
            $menuoptions{'clr'} = {
                    name => $lang->txt('Transfer History'),
                 url => $baseurl."a=P_CLR",
            };
        }
    }

    $Data->{'SystemConfig'}{'TYPE_NAME_3'} = '' if not exists $Data->{'SystemConfig'}{'TYPE_NAME_3'};
    my @menu_structure = (
        [ $lang->txt('Person Dashboard'), 'home','home'],
        [ $lang->txt('Player Passport'), 'menu','passport'],
        [ $lang->txt('Transactions'), 'menu',['transactions','addtransactions']],
        [ $lang->txt('Certificates'), 'menu','certificates'],
        [ $lang->txt('History'), 'menu',[
            'regos',
            'clr',
            'auditlog'
        ]],
        [ $lang->txt('Documents'), 'menu','docs'],
    );
        #[ $lang->txt('Transfer History'), 'menu','clr'],
    #    [ $lang->txt('System'), 'system',[
    #    'auditlog',
    #    ]],
    #);

    my $menudata = processmenudata(\%menuoptions, \@menu_structure );
    return $menudata;

}

1;
