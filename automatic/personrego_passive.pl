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
                tblPersonRegistration_$realm->{'intRealmID'}
            SET
                strStatus = ?
            WHERE
                dtTo > '1900-01-01'
                AND dtTo < DATE(NOW())
                AND strStatus = 'ACTIVE'
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
