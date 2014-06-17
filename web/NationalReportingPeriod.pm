package NationalReportingPeriod;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getNationalReportingPeriod);
@EXPORT_OK=qw(getNationalReportingPeriod);

use strict;

sub getNationalReportingPeriod {
    my ($db, $realmID, $subRealmID) = @_;
    $subRealmID ||= 0;
    my $st = qq[
        SELECT
            intNationalPeriodID
        FROM
            tblNationalPeriod
        WHERE
            intRealmID = ?
            AND (intSubRealmID = ? or intSubRealmID = 0)
            AND (dtStart < now() AND dtEnd > now())
    ];
    my $q = $db->prepare($st);
    $q->execute($realmID, $subRealmID);
    my $nationalPeriodID = $q->fetchrow_array();
    $nationalPeriodID ||= 0;
    return $nationalPeriodID;
}

1;
