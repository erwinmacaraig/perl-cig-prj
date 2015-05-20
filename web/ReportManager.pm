#
# $Header: svn://svn/SWM/trunk/web/ReportManager.pm 11335 2014-04-22 02:58:17Z apurcell $
#

package ReportManager;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handleReports getSavedReportData getReportObj);
@EXPORT_OK = qw(handleReports getSavedReportData getReportObj);

use strict;
use CGI qw(param unescape escape :cgi );

use lib '.', 'comp','Reports';
use Reg_common;
use PageMain;
use Defs;
use Utils;
use SearchLevels;
use Reports::ReportStandard;
use Reports::ReportAdvanced;
use Payments;
use ConfigOptions;
use Logo;
use Log;
use Data::Dumper;


sub handleReports	{
	my($action, $Data, $params_in)=@_;
	# GET PARAMATERS
	$action||='REP_SETUP';
	my $reportID = param('rID') || '';
	my $target=$Data->{'target'};
	my $activetab = param('at') || '';

	# GET CLIENT VALUES
	my $clientValues_ref=$Data->{'clientValues'};
	my $client=$Data->{'client'};
	$clientValues_ref->{unesc_client}=unescape($client);

	my $currentLevel = $clientValues_ref->{currentLevel};

	my $db=$Data->{'db'};
	my $report = 0;

	my $lang = $Data->{'lang'};
	my $title = $lang->txt('Reports Manager');
	my $body = '';
	if($action eq 'REP_SAVE')	{
        $activetab = getActiveTab($db, $Data);
		$body .= convertSavedReport($db, $Data, $clientValues_ref);
        $action = 'REP_SETUP';
	}
	elsif($action eq 'REP_DELETE')	{
        $activetab = getActiveTab($db, $Data);
		$body .= deleteSavedReport($db, $Data, $clientValues_ref);
        $action = 'REP_SETUP';
	}
	if($action eq 'REP_SETUP')	{
		$body .= displayReportList($db, $Data, $clientValues_ref, $activetab);
	}
	else	{
		my $reportingdb = connectDB('reporting');
		my $reportObj = getReportObj({
            'db'            => $db,
            'reporting_db'  => $reportingdb,                                 
            'data'          => $Data, 
            'client_values' => $clientValues_ref,
            'report_id'     => $reportID, 
            'params_in'     => $params_in,
        });

		if($action eq 'REP_REPORT')	{
			my $b = time();
			my $continue = 1;
			($body, $continue) = $reportObj->runReport();
			$title = $lang->txt($reportObj->Name());
			$body ||= '';
			if(!$continue)	{
				$action = 'REP_CONFIG';
			}
			else	{
				my $a = time();
				print STDERR "\nNew Report run ".($a-$b)." secs\n";
				$report = 1;
			}
		}
		if($action eq 'REP_CONFIG')	{
			$reportObj->setCarryFields({ 
				client=>$clientValues_ref->{unesc_client},
				a =>'REP_REPORT',
				rID => $reportID,
			});
			$body .= $reportObj->displayOptions();
			$title = $lang->txt('Configure Report'). ' - ' .field_changetext($Data, $reportObj->Name());
		}
	}
	
	return ($body, $report, $title);
}

sub getReportObj {
	my $params = shift;
	my ($db, $reportingdb, $Data, $clientValues_ref, $reportID, $params_in) 
	   = @{$params}{qw/ db reporting_db data client_values report_id params_in /};

	my $body = '';
	my $currentLevel = $Data->{'clientValues'}{'currentLevel'} || 0;
	my $entityID = getID($Data->{'clientValues'}, $Data->{'clientValues'}{'currentLevel'});

	my $cgi=new CGI;
	my %Params=$cgi->Vars();
	%Params = %{$params_in} if $params_in;
	my $client = setClient($clientValues_ref);

	my $st = qq[
		SELECT * 
		FROM tblReports
		WHERE intReportID = ?
	];
  my $q = $db->prepare($st);
  $q->execute($reportID);
	my $reportdata = $q->fetchrow_hashref();
	$q->finish();
	my $reportType = $reportdata->{'intType'} || 0;

	my $perms=$Data->{'Permissions'};
	if(!$perms)	{
		$perms = GetPermissions(
			$Data,
			$Data->{'clientValues'}{'currentLevel'},
			$entityID,
			$Data->{'Realm'},
			$Data->{'RealmSubType'},
			$Data->{'clientValues'}{'authLevel'},
		);
	}
	my $fieldPermissions_ref=convert_permissions($Data->{'Permissions'}, $Data);

	my $object = $reportdata->{'strFunction'} || 'Reports::ReportStandard';
	my $logo = showLogo(
		$Data,
		$Data->{'clientValues'}{'authLevel'},
		getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'}),
		$client,
		0,
		0,
		100,
	);
	my %otheroptions = (
		Logo => $logo || '',
	);

	eval "require $object";	
	if($object) {

        $otheroptions{'OtherReports'} = getSavedReportsBasedOn($db, $Data, $clientValues_ref, $reportID);
		my $r = $object->new(
			Data => $Data,
			db => $db,
			dbRun => $reportingdb,
			ID => $reportID,
			EntityTypeID => $currentLevel,
			EntityID => $entityID,
			FormParams => \%Params,
			Permissions => $fieldPermissions_ref,
			Lang => $Data->{'lang'},
			ClientValues => $Data->{'clientValues'} || undef,
			ReturnURL => "$Defs::base_url/$Data->{'target'}?client=$client&amp;a=REP_SETUP",
			SystemConfig => $Data->{'SystemConfig'},
			OtherOptions => \%otheroptions,
		);
		return $r || undef;
	}
	return undef;
}

sub displayReportList	{
	my($db, $Data, $clientValues, $activetab) = @_;

	my $body = '';
	my $reports = getReportsInfo($db, $Data, $clientValues);
	my $client = setClient($clientValues);
	my $lastgroup = '';
	my $l = $Data->{'lang'};
	my @grouplist = ();
	my $groups = '';

    my $cnt = 0;
	for my $group (sort keys %{$reports})	{
        my $groupkey = lc $group;
        $groupkey =~s/[^\da-zA-Z]//g;
        if($groupkey eq 'people') { $activetab ||= 'people'; }
    }
	for my $group (sort keys %{$reports})	{
        $cnt++;
        $activetab = $group if !$activetab;
		if($lastgroup ne $group)	{
			my $groupkey = lc $group;
			$groupkey =~s/[^\da-zA-Z]//g;
			push @grouplist, [$groupkey, $group];
			my $groupname = $l->txt($group);
            my $active = $groupkey eq $activetab ? 'in active' : '';
			$groups .=qq[ 
				<div class="tab-pane fade $active" id="repgroup-$groupkey" role = "tabpanel">
			];
			$lastgroup = $group;
		}
        for my $subtype ('build','run') {
            if(!exists $reports->{$group}{$subtype})   {
                next;
            }
            my $subtypename = $subtype eq 'build'
                ? $Data->{'lang'}->txt('Build a Report')
                : $Data->{'lang'}->txt('Run a Report');
            $groups .= qq[
                <h4>$subtypename</h4>
                <div style = "padding-left:20px;">
                <table class = "table table-striped">
            ];
            for my $report (@{$reports->{$group}{$subtype}})	{
                my $hasParams = $report->{'intParameters'} || 0;
                my $reptarget = 'report';
                my $buttonevent = $report->{'intParameters'}
                    ? qq[ onclick="showParams($report->{'intReportID'}); return false;" ]
                    : '';
                my $newaction = 'REP_REPORT';
                my $buttoncaption = $l->txt('Run');
                my $repID = '';
                my $run = '';
                my $delete = '';
                if($report->{'intType'} == 3)	{
                    #Advanced Report
                    $reptarget= '';
                    $newaction = 'REP_CONFIG';
                    $buttonevent = '';
                    $buttoncaption = $l->txt('Build');
                }
                elsif($report->{'intType'} == 6)	{
                    $newaction = 'REP_CONFIG';
                    $repID = $report->{'intSavedReportID'} || '';
                    $buttonevent = '';
                    $buttoncaption = $l->txt('Edit');
                    $delete = qq[
                        <a href = "$Data->{'target'}?client=$clientValues->{unesc_client}&amp;a=REP_DELETE&amp;rID=$report->{'intReportID'}&amp;repID=$repID" class = "btn-inside-panels" onclick = "return confirm('].$l->txt('Are you sure you want to delete this saved report?').qq[');">].$Data->{'lang'}->txt('Delete').qq[</a>
                    ];
                    $run = qq[
                        <a href = "$Data->{'target'}?client=$clientValues->{unesc_client}&amp;a=REP_REPORT&amp;rID=$report->{'intReportID'}&amp;repID=$repID" class = "btn-inside-panels">].$Data->{'lang'}->txt('Run').qq[</a>
                    ];
                }
                $groups .= qq[
                    <tr>
                        <td>
                            <b>].$l->txt($report->{'strName'}).qq[</b><br>
                            ].$l->txt($report->{'strDescription'}).qq[
                        </td>
                        <td class = "repbutton-col">
                            <a href = "$Data->{'target'}?client=$clientValues->{unesc_client}&amp;a=$newaction&amp;rID=$report->{'intReportID'}&amp;repID=$repID" class = "btn-inside-panels">].$l->txt($buttoncaption).qq[</a>
                            $delete
                            $run
                        </td>
                    </tr>
                ];
            }
            $groups .= '</table></div>';
        }
		$groups .= '</div>';
	}
	my $tablist = '';
	for my $g(@grouplist)	{
        my $activeClass = $g->[0] eq $activetab ? 'active' : '';
		$tablist .= qq[
			<li role = "presentation" class = "$activeClass"><a href = "#repgroup-$g->[0]" aria-controls="#repgroup-$g->[0]" role="tab" data-toggle="tab">].$l->txt($g->[1]).qq[</a></li>
		];
	}
	my $paramcode = qq[
		<script type="text/javascript">
			function showParams(reportID)	{
				var url = 'reportparams.cgi?client=$client&amp;rID=' + reportID;
				var d = jQuery('<div>').dialog({
						modal: true,
						autoOpen: false,
						open: function () { jQuery(this).load(url); },         
						close: function(ev, ui) { 
						    jQuery(this).dialog('destroy'); 
						    jQuery('#repparams_form').remove();
						},
						height: 400,
						width: 400,
						resizable: false,
						title: 'Choose Options',
						buttons: { 
							"Cancel": function() { jQuery(this).dialog("close"); },
							"Run Report": function() { 
								jQuery('#repparams_form').submit();
								jQuery(this).dialog("close"); 
							} 
						}
				});
				d.dialog('open');
			}
		</script>
	];
	$body = qq[
		$paramcode
        <div role = "tabpanel">
                <ul class = "nav nav-tabs">
                    $tablist
                </ul>
			<div class="tab-content">
				$groups
			</div>
		</div>
	];
	return $body || '';
}

sub getReportsInfo  {
	my($db, $Data, $clientValues_ref) = @_;

	my %reports = ();

  my $currentLevel = $clientValues_ref->{'currentLevel'};
  my $userID=getID($clientValues_ref, $clientValues_ref->{'authLevel'}) || 0;
  my $realmID = $Data->{'Realm'} || 0;
  my $subRealmID = $Data->{'RealmSubType'} || 0;
  my $where_subRealmID = $subRealmID ? "intSubRealmID IN (0,$subRealmID)" : " intSubRealmID=0 ";
	my $display_config = getReportDisplayConfig($db, $Data);

  my $st = qq[
    SELECT 
			R.intReportID,
			R.strName,
			R.strDescription,
			R.intType,
			R.intParameters,
			R.strGroup,
			R.strRequiredOptions

    FROM tblReportEntity AS RE
      INNER JOIN tblReports AS R ON (R.intReportID =RE.intReportID)
    WHERE RE.intRealmID IN(0,$realmID)
      AND $where_subRealmID
      AND RE.intEntityTypeID IN (0,$currentLevel)
      AND RE.intEntityID IN (0,$userID)
      AND $currentLevel >= RE.intMinLevel
      AND $currentLevel <= RE.intMaxLevel
		ORDER BY intOrder
  ];
  my $q = $db->prepare($st);
  $q->execute();
  while (my $dref = $q->fetchrow_hashref()) {
		my $skip = 0;
		if($dref->{'strRequiredOptions'})	{
			my @options = split /;/,$dref->{'strRequiredOptions'};
			for my $i (@options)	{
				my($o, $v) = split /=/,$i;
				$v ||= 0;
				if(($display_config->{$o} || 0) ne $v)	{
					$skip = 1;
				}
			}
		}
        DEBUG "SKIP", $dref->{'strGroup'}, $dref->{'strName'} if $skip;
		if(!$skip)	{
			$dref->{'strGroup'} = field_changetext($Data, $dref->{'strGroup'});
			$dref->{'strName'} = field_changetext($Data, $dref->{'strName'});
			$dref->{'strDescription'} = field_changetext($Data, $dref->{'strDescription'});

            my $subtype = $dref->{'intType'} == 3 ? 'build' : 'run';
            push @{$reports{$dref->{'strGroup'}}{$subtype}}, $dref;
		}
  }

    #Now get saved Reports
      $st = qq[
        SELECT 
            S.strReportName,
            S.intSavedReportID,
            R.strGroup,
            R.intReportID,
            R.intType
        FROM 
            tblSavedReports AS S
            INNER JOIN tblReports AS R ON (R.intReportID = S.intReportID)
        WHERE 
          S.intLevelID = ?
          AND S.intID = ?
          AND S.intTemporary = 0
        ORDER BY strReportName
      ];
      $q = $db->prepare($st);
      $q->execute(
        $currentLevel,
        $userID,
      );
      while (my $dref = $q->fetchrow_hashref()) {
                $dref->{'strGroup'} = field_changetext($Data, $dref->{'strGroup'});
                $dref->{'strName'} = $dref->{'strReportName'} || '';
                $dref->{'strDescription'} = '';
                $dref->{'intType'} = 6;

                push @{$reports{$dref->{'strGroup'}}{'run'}}, $dref;
      }

	return \%reports;
}

sub field_changetext {
	my($Data, $text) = @_;

	my $SystemConfig = $Data->{'SystemConfig'};
	#return $text if $text !~/ReplaceText-/;
	
	my %TextReplacements = (
  	Clearance => $SystemConfig->{'txtCLR'} || 'Clearance',
	Clearances => $SystemConfig->{'txtCLRs'} || 'Clearances',
		Member => $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER},
		Members => $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER."_P"},
		Team => $Data->{'LevelNames'}{$Defs::LEVEL_TEAM},
		Teams => $Data->{'LevelNames'}{$Defs::LEVEL_TEAM."_P"},
		Club => $Data->{'LevelNames'}{$Defs::LEVEL_CLUB},
		Clubs => $Data->{'LevelNames'}{$Defs::LEVEL_CLUB."_P"},
		Association => $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC},
		Associations => $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC."_P"},
	);

	$text =~s/ReplaceText-(\w+)/$TextReplacements{$1}/eg;
	return $text;
}


sub convert_permissions {
  my($perms, $Data)=@_;
  #Convert permissions from SWM to ReportOptions format
  my $validperms= defined $perms ? 1 : 0;
  my %newperms=();
  my $viewablefields=0;
  my $onlycompulsory=1;
	my @permstypes = (qw(Member Club Team));
	for my $type (@permstypes)	{
		for my $k (keys %{$perms->{$type}})  {
			my $val=$perms->{$type}{$k} eq 'Hidden' ? 0 : 1;
			$newperms{$type}{$k}=$val;
			$viewablefields ||= $val;
		}
	}
  $validperms=0 if !$viewablefields;

	#my $totalfields = getConfigurableFields($Data);
  #for my $f (@{$totalfields}) {
    #$newperms{$f}=0 if !exists $perms->{$f};
    #$newperms{$f}=1 if($Data->{'clientValues'}{'currentLevel'} > $Defs::LEVEL_ASSOC and !$validperms and !exists $perms->{$f});
    #$newperms{$f}=1 if($Data->{'clientValues'}{'currentLevel'} > $Defs::LEVEL_ASSOC and $onlycompulsory and !exists $perms->{$f});
    #$newperms{$f}=1 if($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_EVENT and !$validperms and !exists $perms->{$f});
  #}
  if(
		(
			$Data->{'clientValues'}{'currentLevel'} > $Defs::LEVEL_ASSOC 
			and $Data->{'SystemConfig'}{'rptSchools'}
		) 
		or (
			$Data->{'SystemConfig'}{'Schools'} 
			and $newperms{'Member'}{'intSchoolID'}
		)
	)  {
    $newperms{'Member'}{'strSchoolName'}=1;
    $newperms{'Member'}{'strSchoolSuburb'}=1;
  }
  else  {
    $newperms{'Member'}{'strSchoolName'}=0;
    $newperms{'Member'}{'strSchoolSuburb'}=0;
  }
  return \%newperms;
}

sub getSavedReportsBasedOn {
    my($db, $Data, $clientValues_ref, $reportID) = @_;

    my $entityTypeID = $clientValues_ref->{'currentLevel'};
    my $entityID = getID($clientValues_ref, $clientValues_ref->{'authLevel'}) || 0;

    my $st = qq[
        SELECT 
            S.strReportName,
            S.intSavedReportID
        FROM 
            tblSavedReports AS S
        WHERE 
          S.intLevelID = ?
          AND S.intID = ?
          AND S.intTemporary = 0
          AND S.intReportID = ?
        ORDER BY strReportName
    ];
    my $q = $db->prepare($st);
    $q->execute(
        $entityTypeID,
        $entityID,
        $reportID,
    );
    my @otherreports = ();
    while (my $dref = $q->fetchrow_hashref()) {
        push @otherreports, [ 
            $dref->{'intSavedReportID'} || 0,
            $dref->{'strReportName'} || '',
        ];
    }
    return \@otherreports;
}

sub getSavedReportData  {
  my(
		$Data, 
		$saved_reportID,
	)=@_;
	my $reportID = 0;
	{
		my $st = qq[
			SELECT 
			intReportID 
			FROM tblSavedReports
			WHERE intSavedReportID = ?
		];
		my $q = $Data->{'db'}->prepare($st);
		$q->execute($saved_reportID);
		($reportID) = $q->fetchrow_array();
		$q->finish();
	}
	return undef if !$reportID;
	my %params = (
		RO_SR_run => 1,
		repID => $saved_reportID,
		ReturnData => 1,
	);
  	my $reportingdb = connectDB('reporting');
	my $reportObj = getReportObj({
		'db'            => $Data->{'db'},
        'reporting_db'  => $reportingdb,                                 
		'data'          => $Data, 
		'client_values' => $Data->{'clientValues'},
		'report_id'     => $reportID, 
		'params_in'     => \%params,
	});

	my $reportdata = $reportObj->runReport();
  return $reportdata;

}

sub getReportDisplayConfig	{
	my($db, $Data) = @_;

	my %options = ();
	for my $k (keys %{$Data->{'SystemConfig'}})	{
		$options{$k} = $Data->{'SystemConfig'}{$k};
	}
	for my $k (keys %{$Data->{'EventOptions'}})	{
		$options{$k} = $Data->{'EventOptions'}{$k};
	}
  #my $paymentsettings = getPaymentSettings($Data, 0);
  #my $paypal = $paymentsettings->{'paymentType'} == $Defs::PAYMENT_ONLINEPAYPAL ? 1 : 0;
#	$options{'PayPal'} = $paypal;
 # my $nab = $paymentsettings->{'paymentType'} == $Defs::PAYMENT_ONLINENAB ? 1 : 0;
#	$options{'NAB'} = $nab;
#	$options{'ReceiveFunds'} = $nab || $paypal;

	return \%options;
}

sub convertSavedReport  {
    my($db, $Data, $clientValues_ref) = @_;

    my $id = param('repID') || '';
    my $name = param('repname') || '';
    my $repreplace = param('repreplace') || '';
    my $entityTypeID = $clientValues_ref->{'currentLevel'};
    my $entityID = getID($clientValues_ref, $clientValues_ref->{'authLevel'}) || 0;

    my $error = 0;
    my $msg = '';
    if($repreplace) {
        my $st = qq[
            SELECT strReportData
            FROM tblSavedReports
            WHERE intSavedReportID = ?
        ];
        my $q = $Data->{'db'}->prepare($st);
        $q->execute($id);
        my ($reportData) = $q->fetchrow_array();
        $q->finish();

        my $st_u = qq[
            UPDATE tblSavedReports
            SET
                strReportData = ?
            WHERE 
                intSavedReportID = ?
                AND intLevelID = ?
                AND intID = ?
        ];
        my $q_u = $Data->{'db'}->prepare($st_u);
		$q_u->execute(
            $reportData,
            $repreplace,
            $entityTypeID,
            $entityID,
        );
		$q_u->finish();

        $msg = 'Report Saved';
    }
    elsif($name)    {
        my $st = qq[
            UPDATE tblSavedReports
            SET 
                strReportName = ?,
                intTemporary = 0
            WHERE
                intSavedReportID = ?
                AND intLevelID = ?
                AND intID = ?
        ];
		my $q = $Data->{'db'}->prepare($st);
		$q->execute(
            $name,
            $id,
            $entityTypeID,
            $entityID,
        );
		$q->finish();
        $msg = 'Report Saved';
    }
    else {
        $error = 1;
        $msg = 'Report not saved';

    }
    my $alertclass = $error 
        ? ''
        : 'fa-info';
    my $alert = qq[
<div class="alert">
    <div>
        <span class="fa $alertclass fa-exclamation"></span>
        <p>$msg</p>
    </div>
</div>
    ];
    return $alert;
}

sub deleteSavedReport  {
    my($db, $Data, $clientValues_ref) = @_;

    my $id = param('repID') || '';
    my $entityTypeID = $clientValues_ref->{'currentLevel'};
    my $entityID = getID($clientValues_ref, $clientValues_ref->{'authLevel'}) || 0;

    my $error = 0;
    my $msg = '';
    if($id) {
        my $st = qq[
            DELETE FROM tblSavedReports
            WHERE
                intSavedReportID = ?
                AND intLevelID = ?
                AND intID = ?
        ];
		my $q = $Data->{'db'}->prepare($st);
		$q->execute(
            $id,
            $entityTypeID,
            $entityID,
        );
		$q->finish();
        $msg = 'Report deleted';
    }
    else {
        $error = 1;
        $msg = 'Report not deleted';

    }
    my $alertclass = $error 
        ? ''
        : 'fa-info';
    my $alert = qq[
<div class="alert">
    <div>
        <span class="fa $alertclass fa-exclamation"></span>
        <p>$msg</p>
    </div>
</div>
    ];
    return $alert;
}

sub getActiveTab {
    my($db, $Data, $clientValues_ref) = @_;

    my $id = param('repID') || '';
    my $st = qq[
        SELECT 
            strGroup
        FROM
            tblSavedReports AS SR
                INNER JOIN tblReports AS R
            ON SR.intReportID = R.intReportID
        WHERE
            SR.intSavedReportID = ?
        LIMIT 1
    ];
    my $q = $db->prepare($st);
    $q->execute(
        $id,
    );
    my ($group) = $q->fetchrow_array();
    my $groupkey = lc $group;
    $groupkey =~s/[^\da-zA-Z]//g;

    return $groupkey;
}
1;

