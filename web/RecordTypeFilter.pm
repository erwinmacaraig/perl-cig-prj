#
# $Header: svn://svn/SWM/trunk/web/RecordTypeFilter.pm 11534 2014-05-12 04:47:44Z sliu $
#

package RecordTypeFilter;

## LAST EDITED -> 10/09/2007 ##

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(show_recordtypes);
@EXPORT_OK = qw(show_recordtypes);

use strict;
use CGI qw(param unescape escape);

use lib '.', "..";
use Defs;
use Reg_common;
require FieldLabels;
use Utils;
use FormHelpers;

use Data::Dumper;
use Log;

sub show_recordtypes	{
    my(
        $Data, 
        $level, 
        $memberrecords, 
        $fieldlabels,
        $textfilter_name,
        $season_reload,
        $omit_statusfilter,
        $omit_seasonfilter,
    )=@_;

    my $lang = $Data->{'lang'};

    $level||=0;
    $memberrecords||=0;
    $season_reload ||= 0;
    my $statusfilter='';
    if (not $omit_statusfilter) {
        if (
            !defined $Data->{'Permissions'}{'Member'}{'intRecStatus'} 
                or $Data->{'Permissions'}{'Member'}{'intRecStatus'} ne 'Hidden' 
                or $level >= $Defs::LEVEL_TEAM
                or $level== $Defs::LEVEL_PERSON
        )	{
            my $checked_active= $Data->{'ViewActStatus'} == 1 ? ' selected ' : '';
            my $checked_inactive= $Data->{'ViewActStatus'} == 0 ? ' selected ' : '';
            my $checked_all = $Data->{'ViewActStatus'} == 2 ? ' selected ' : '';

            my $name = '';
            if ($level == $Defs::LEVEL_PERSON) {
                #$name = $lang->txt("$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Status") . ':' ;
                $name = $lang->txt("Status") . ':' ;
            }

            my $cgi = new CGI;
            $statusfilter =  $name . $cgi->popup_menu(
                -name    => "actstatus",
                -id      => "dd_actstatus",
                -size    => 1,
                -style   => "font-size:10px;",
                -values  => [1, 0, 2],
                -default => $Data->{'ViewActStatus'},
                -labels  => {
                    0 => $lang->txt('Inactive'),
                    1 => $lang->txt('Active'),
                    2 => $lang->txt('All'),
                }
            );

            my $statuscookie=qq[
            jQuery("#dd_actstatus").change(function() {
                    SetCookie('$Defs::COOKIE_ACTSTATUS',jQuery('#dd_actstatus').val(),30);
                });
            ];
            $Data->{'AddToPage'}->add('js_bottom','inline',$statuscookie);
        }
    }
    my $statusMCfilter='';
    my $assocSeasons = '';#Seasons::getDefaultAssocSeasons($Data);
    my $seasonFilter='';


    my $blankseasons = 0;
    my $allseasons = 0;
    if (
            not $omit_seasonfilter
            and (
            (
                $level == $Defs::LEVEL_TEAM 
                    and $Data->{'clientValues'}{'currentLevel'} != $Defs::LEVEL_COMP
            ) 
                or $level == $Defs::LEVEL_COMP
                or $level == $Defs::LEVEL_PERSON
                or $level == $Defs::LEVEL_TEAM
            ) 
            and $Data->{'clientValues'}{'currentLevel'} >= $Defs::LEVEL_TEAM
and 1==2
    )	
    {
        my ($Seasons, undef) = Seasons::getSeasons($Data, $allseasons, $blankseasons);
        my $season = ($Data->{'ViewSeason'} and exists $Seasons->{$Data->{'ViewSeason'}} and $Data->{'ViewSeason'} > 0) 
        ?	$Data->{'ViewSeason'} 
        :	$assocSeasons->{'currentSeasonID'};
        if (
            $level == $Defs::LEVEL_TEAM 
                or $level == $Defs::LEVEL_PERSON 
                or $level == $Defs::LEVEL_COMP)	{
            ### In Teams allow for a -1 Season Filter (ie: Not in a season)
            $Data->{'ViewSeason'} ||= 0;
            $season = ($Data->{'ViewSeason'}<= -1 or ($Data->{'ViewSeason'} and exists $Seasons->{$Data->{'ViewSeason'}})) 
            ? $Data->{'ViewSeason'} 
            : $assocSeasons->{'currentSeasonID'};
        }

        my $txt_SeasonName = $lang->txt( $Data->{'SystemConfig'}{'txtSeason'} || 'Season' );

#reverse order for seasons
        my @order=();
        for my $i (reverse sort {$Seasons->{$a} cmp $Seasons->{$b}} keys %{$Seasons})  { push @order, $i;  }
        my $order_ref=\@order;

        $seasonFilter = qq[$txt_SeasonName] . drop_down('seasonfilter',$Seasons,$order_ref,$season,1,0,"font-size:10px;");
        $season_reload ||= 0;
        my $season_refresh = $season_reload
        ? 'document.location.reload();'
        : '';
        my $seasonCookie=qq[
        jQuery("#dd_seasonfilter").change(function() {
                SetCookie('$Defs::COOKIE_SEASONFILTER',jQuery('#dd_seasonfilter').val(),30);
                $season_refresh;
            });
        ];
        $Data->{'AddToPage'}->add('js_bottom','inline',$seasonCookie);
    }
    my $ageGroupFilter='';
    my $ageGroupCookie='';
    if (
            (
            (
                $level == $Defs::LEVEL_TEAM 
                    and $Data->{'clientValues'}{'currentLevel'} != $Defs::LEVEL_COMP
            ) 
                or $level == $Defs::LEVEL_COMP 
                or $level == $Defs::LEVEL_PERSON
        ) 
            and $Data->{'clientValues'}{'currentLevel'} >= $Defs::LEVEL_TEAM
    )	{
        my ($AgeGroups, undef) =AgeGroups::getAgeGroups($Data, 1, 1);
        my $ageGroup = ($Data->{'ViewAgeGroup'} and exists $AgeGroups->{$Data->{'ViewAgeGroup'}} and $Data->{'ViewAgeGroup'} > 0) 
        ? $Data->{'ViewAgeGroup'} 
        : $Data->{'SystemConfig'}{'DefaultAgeGroup'};
        $Data->{'ViewAgeGroup'} ||= 0;
        $ageGroup= ($Data->{'ViewAgeGroup'} == -1 or ($Data->{'ViewAgeGroup'} and exists $AgeGroups->{$Data->{'ViewAgeGroup'}})) 
        ? $Data->{'ViewAgeGroup'} 
        : $Data->{'SystemConfig'}{'DefaultAgeGroup'};

        my $txt_AgeGroupName = $lang->txt( $Data->{'SystemConfig'}{'txtAgeGroup'} || 'Age Group');
        $ageGroupFilter = $txt_AgeGroupName.drop_down('ageGroupfilter',$AgeGroups,undef,$ageGroup,1,0, "font-size:10px;");
        $ageGroupCookie=qq[
        jQuery("#dd_ageGroupfilter").change(function() {
                SetCookie('$Defs::COOKIE_AGEGROUPFILTER',jQuery('#dd_ageGroupfilter').val(),30);
            });
        ];
        $Data->{'AddToPage'}->add('js_bottom','inline',$ageGroupCookie);
    }
    if( $level == $Defs::LEVEL_PERSON and $Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB ) {
        if (!  $Data->{'SystemConfig'}{'ShowInactiveClubMembers'})	{
            $statusMCfilter = qq[<input type="hidden" name="MCstatus" id="dd_MCStatus" value="2">];
        } else	{
            my $checked_active= $Data->{'ViewMCStatus'} == 1 ? ' selected ' : '';
            my $checked_inactive= $Data->{'ViewMCStatus'} == 0 ? ' selected ' : '';
            my $checked_all = $Data->{'ViewMCStatus'} == 2 ? ' selected ' : '';
            $statusMCfilter=qq[
            $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Status: <select name="MCstatus" size="1" style="font-size:10px;" id = "dd_MCStatus">
            <option $checked_active value="1">Active</option>
            <option $checked_inactive value="0">Inactive</option>
            <option $checked_all value="2">All</option>
            </select>
            ];
        }
        my $statusMCcookie=qq[
        jQuery("#dd_MCStatus").change(function() {
                SetCookie('$Defs::COOKIE_MCSTATUS',jQuery('#dd_MCStatus').val(),30);
            });
        ];
        $Data->{'AddToPage'}->add('js_bottom','inline',$statusMCcookie);
    }

    my $membertypefilter='';
    my $record_type_filter = '';

    if($memberrecords)	{
            my $membertypes='';
            ### Lets show different types depending on if Seasons turned on or not
            if (1==2)	{
                for my $i (qw(Seasons.intPlayerStatus Seasons.intCoachStatus Seasons.intUmpireStatus Seasons.intOther1Status Seasons.intOther2Status intOfficial intMisc intVolunteer Seasons.intMSRecStatus))	{
                    next if ($i =~ /Other1Status/ and ! $Data->{'SystemConfig'}{'Seasons_Other1'});
                    next if ($i =~ /Other2Status/ and ! $Data->{'SystemConfig'}{'Seasons_Other2'});
                    next if (defined $Data->{'Permissions'}{'Member'}{$i} and $Data->{'Permissions'}{'Member'}{$i} eq 'Hidden');
                    my $selected =  $Data->{'CookieMemberTypeFilter'} eq $i ? ' SELECTED ' : '';
                    $membertypes.=qq[<option $selected value="$i">$fieldlabels->{$i}</option>];
                }
            }
            else	{
                for my $i (qw(intPlayer intCoach intUmpire intOfficial intMisc intVolunteer ))	{
                    next if (defined $Data->{'Permissions'}{'Member'}{$i} and $Data->{'Permissions'}{'Member'}{$i} eq 'Hidden');
                    my $selected =  $Data->{'CookieMemberTypeFilter'} eq $i ? ' SELECTED ' : '';
                    $membertypes.=qq[<option $selected value="$i">$fieldlabels->{$i}</option>];
                }
            }

            if ($membertypes) {
                $membertypefilter=qq[
                <select name="mtfilter" size="1" style="font-size:10px;" id = "dd_mtfilter">
                <option value="">All</option>
                $membertypes
                </select> 
                ];
                my $membertypecookie = qq[
                jQuery("#dd_mtfilter").change(function() {
                        SetCookie('$Defs::COOKIE_MTYPEFILTER',jQuery('#dd_mtfilter').val(),30);
                        document.location.reload();;
                    });
                ];
                $Data->{'AddToPage'}->add('js_bottom','inline',$membertypecookie);
            }
    }
    my $textfilter = '';
    if($textfilter_name)	{
        my $including = $lang->txt('including');
        $textfilter = qq[
        $textfilter_name  $including <input type = "text" value = "" name = "textfilterfield" id = "id_textfilterfield" size = "10">
        ];
    }

    my $Filter  = $lang->txt('Filter');

    my $form_text = join(
        '',
        $lang->txt('Showing'),
        ' - ',
        $textfilter,
        $seasonFilter,
        $ageGroupFilter,
        $statusfilter,
        $statusMCfilter,
        $membertypefilter,
        $record_type_filter,
        #' ',
        #$lang->txt('records'),
    );

    my $line=qq[
    <div class="showrecoptions">
    <form action="#" onsubmit="return false;" name="recoptions">
    $form_text
    </form>
    </div>
    ];
    $line = '' if (! $statusfilter and ! $textfilter and ! $membertypefilter and ! $seasonFilter);
    $Data->{'AddToPage'}->add('js_bottom','file','js/jscookie.js');

    DEBUG "show_recordtypes: $line";
    return $line;
}

1;
