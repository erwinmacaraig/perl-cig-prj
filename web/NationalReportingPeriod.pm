package NationalReportingPeriod;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getNationalReportingPeriod);
@EXPORT_OK=qw(getNationalReportingPeriod);

use strict;

sub getNationalReportingPeriod {
    my ($db, $realmID, $subRealmID, $sport, $registrationNature) = @_;
    $subRealmID ||= 0;
    my $st = qq[
        SELECT
            intNationalPeriodID
        FROM
            tblNationalPeriod
        WHERE
            intRealmID = ?
            AND (intSubRealmID = ? or intSubRealmID = 0)
            AND strSport IN ('', ?)
            AND (dtFrom < now() AND dtTo > now())
    ];
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
    my $nationalPeriodID = $q->fetchrow_array();
    $nationalPeriodID ||= 0;
    return $nationalPeriodID;
}

1;
