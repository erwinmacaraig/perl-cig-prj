#!/usr/bin/perl

use strict;
use lib "..", "../web";
use Utils;
use DBI;
use Defs;
use Data::Dumper;

{
    my %Data = ();
    my $db = connectDB();
    my @realm;

    $Data{'db'} = $db;

    my $targetRealm = getRealm(\%Data);
    my $st = undef;
    my $q;

    while(my $realm = $targetRealm->fetchrow_hashref()) {

        $st = qq [
            UPDATE
                tblPersonRegistration_$realm->{'intRealmID'} as PR
		INNER JOIN tblNationalPeriod as NP ON (
			NP.intNationalPeriodID = PR.intNationalPeriodID
		)
            SET
                PR.strStatus = ?
            WHERE
                (
			(
				NP.dtTo > '1900-01-01'
				AND NP.dtTo < DATE(NOW())
			)
			OR
			(
				PR.dtTo > '1900-01-01'
				AND PR.dtTo < DATE(NOW())
			)
		)
                AND PR.strStatus = 'ACTIVE'
        ];

        $q = $db->prepare($st);
        $q->execute(
            $Defs::PERSONREGO_STATUS_PASSIVE
        ) or query_error($st);
    }
}

sub getRealm {
    my ($Data) = @_;

    my $st = qq[
        SELECT 
            intRealmID
        FROM 
            tblRealms
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st);
    $q->execute() or query_error($st);

    return $q;
}
