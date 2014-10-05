package NationalReportingPeriod;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getPeriods getNationalReportingPeriod);
@EXPORT_OK=qw(getPeriods getNationalReportingPeriod);

use strict;

sub getPeriods {
    my($Data)=@_;

    my $subType = $Data->{'RealmSubType'} || 0;

    my $checkLocked = $Data->{'HideLocked'} ? qq[ AND intLocked <> 1] : '';
    my $subTypeSeasonOnly = $Data->{'SystemConfig'}->{'OnlyUseSubRealmSeasons'} ? '' : 'OR intRealmSubTypeID= 0';
    my $st=qq[
        SELECT
            intNationalPeriodID,
            strNationalPeriodName,
            strSport
        FROM
            tblNationalPeriod
        WHERE
            intRealmID = $Data->{'Realm'}
        ORDER BY dtFrom
    ];

    my $query = $Data->{'db'}->prepare($st);
    $query->execute();

    my $body='';
    my %Periods=();

    while (my ($id,$name, $sport)=$query->fetchrow_array()) {
        $name .= qq[ - $sport] if $sport;
        $Periods{$id}=$name ||'';
        
    }

    return \%Periods;
}

sub getNationalReportingPeriod {
    my ($db, $realmID, $subRealmID, $sport, $registrationNature) = @_;
    $subRealmID ||= 0;
    my $st = qq[
        SELECT
            intNationalPeriodID,
            dtFrom,
            dtTo
        FROM
            tblNationalPeriod
        WHERE
            intRealmID = ?
            AND (intSubRealmID = ? or intSubRealmID = 0)
            AND strSport IN ('', ?)
    ];
            #AND (dtFrom < now() AND dtTo > now())
    if ($registrationNature and $registrationNature eq 'NEW')   {
        $st .= qq[ 
            AND intCurrentNew = 1 
        ];
    }
    if ($registrationNature and $registrationNature eq 'RENEWAL')   {
        $st .= qq[ 
            AND 
                intCurrentRenewal= 1 
        ];
    }
    $st .= qq[
        ORDER BY 
            intSubRealmID DESC,
            strSport DESC   
        LIMIT 1
    ];
    my $q = $db->prepare($st);
    $q->execute($realmID, $subRealmID, $sport);
    my ($nationalPeriodID, $dtFrom, $dtTo) = $q->fetchrow_array();
    $nationalPeriodID ||= 0;
    return ($nationalPeriodID, $dtFrom, $dtTo);
}

1;
