#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/compAges.pl 11213 2014-04-02 06:32:51Z eobrien $
#

use lib "../web", "..";
use Defs;
use Utils;
use DBI;
use Date::Calc qw(Today Add_Delta_YM);
use CGI qw(param cookie escape);
use Statistics::Basic qw(:all);

use strict;

main();

sub main {
    my %Data        = ();
    my $db          = connectDB();
    my $reportingdb = connectDB('reporting');

    my $stRealms = qq[
		SELECT
			intRealmID
		FROM
			tblRealms
		WHERE
			intRealmID NOT IN (6,35)
	];

    my $qryRealms = $reportingdb->prepare($stRealms) or query_error($stRealms);
    $qryRealms->execute() or query_error($stRealms);

    my $stInsAges = qq[
		INSERT INTO tblStatistics_CompAges (intRealmID, intAssocID, intCompID, dblAvgAge, dblMinAge, dblMaxAge, dblModeAge, dblMeanAge, dblMedianAge, dtRun)
		VALUES (?,?,?,?,?,?,?,?,?,NOW())
		ON DUPLICATE KEY UPDATE dblAvgAge=?, dblMinAge=?, dblMaxAge=?, dblModeAge=?, dblMeanAge=?, dblMedianAge=?, dtRun=NOW()
	];
    my $qryInsAges = $db->prepare($stInsAges) or query_error($stInsAges);

    while ( my $realm_ref = $qryRealms->fetchrow_hashref() ) {
        my $realmID = $realm_ref->{'intRealmID'} || next;
        print "STARTING REALM: $realmID\n";

        ## NOW LOOP ASSOC/COMPS:
        my $stAssocComps = qq[
			SELECT
				A.intAssocID,
				C.intCompID
			FROM
				tblAssoc_Comp as C
				INNER JOIN tblAssoc as A ON (A.intAssocID=C.intAssocID)
			WHERE
				A.intRealmID=?
				AND C.intRecStatus<>-1
				AND C.intUpload=1
				AND (dtStart>='2013-01-01'
				OR C.intNewSeasonID=intCurrentSeasonID)
		];

        #AND C.intNewSeasonID=intCurrentSeasonID

        my $MSTablename = "tblMember_Seasons_" . $realmID;
        my $stMembers   = qq[
			SELECT 
				DATE_FORMAT(NOW(), '%Y') - DATE_FORMAT(M.dtDOB, '%Y') - (DATE_FORMAT(NOW(), '00-%m-%d') < DATE_FORMAT(M.dtDOB, '00-%m-%d')) AS age
			FROM 
				tblAssoc_Comp AS AC 
				INNER JOIN tblComp_Teams AS CT ON (CT.intCompID = AC.intCompID)
				INNER JOIN tblMember_Teams AS MT ON (MT.intTeamID=CT.intTeamID)
				INNER JOIN tblMember AS M ON (M.intMemberID=MT.intMemberID)
			WHERE 
				AC.intAssocID=?
				AND CT.intCompID= ? 
				AND CT.intRecStatus=1 
				AND MT.intStatus=1 
				AND dtDOB > '1900-01-01' 
				AND dtDOB < NOW()
				AND MT.intCompID = AC.intCompID 
		];

        #AND C.intRecStatus<>-1 ?????
        my $qryAssocComps = $reportingdb->prepare($stAssocComps) or query_error($stAssocComps);
        $qryAssocComps->execute($realmID) or query_error($stAssocComps);
        while ( my $ac_ref = $qryAssocComps->fetchrow_hashref() ) {
            my $assocID = $ac_ref->{'intAssocID'} || next;
            my $compID  = $ac_ref->{'intCompID'}  || next;
            my $qryMembers = $reportingdb->prepare($stMembers) or query_error($stMembers);
            $qryMembers->execute( $assocID, $compID ) or query_error($stMembers);
            my @tempMemberAges = ();
            while ( my $memref = $qryMembers->fetchrow_hashref() ) {
                push @tempMemberAges, $memref->{'age'} || next;
            }
            next if !scalar(@tempMemberAges);
            my @MemberAges = sort (@tempMemberAges);
            my $v1         = vector(@MemberAges);
            my $v2         = computed($v1);
            $v2->set_filter(
                sub {
                    my $m = mean($v1);
                    my $s = stddev($v1);
                    grep { abs( $_ - $m ) <= $s } @_;
                }
            );
            my $mode   = mode($v2);
            my $median = median($v2);
            my $mean   = mean($v2);
            my $avg    = avg($v2);
            my @copyv2 = $v2->query();
            my $first  = $copyv2[0];
            my $last   = $copyv2[-1];

            if ( $mode->is_multimodal() ) {
                my $vMode = $mode->query();
                my @vMode = $vMode->query();
                $mode = $vMode[0];
            }
            $qryInsAges->execute(
                                  $realmID,
                                  $assocID,
                                  $compID,
                                  $avg,
                                  $first,
                                  $last,
                                  $mode,
                                  $mean,
                                  $median,
                                  $avg,
                                  $first,
                                  $last,
                                  $mode,
                                  $mean,
                                  $median,
            ) or query_error($stInsAges);
        }

    }
}
1;
