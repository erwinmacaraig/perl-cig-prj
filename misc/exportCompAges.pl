#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/exportCompAges.pl 11579 2014-05-15 21:31:18Z eobrien $
#

use lib "../web", "..";
use Defs;
use Utils;
use DBI;
use Date::Calc qw(Today Add_Delta_YM);
use CGI qw(param cookie escape);
use LWP::UserAgent;
use JSON qw( encode_json decode_json );
use Log;
use Data::Dumper;

use strict;

use constant {
               WEBSITES_API_SIGNATURE => 'stiewiuXLAcOuH40coEfrLUwR28r0a',
               WEBSITES_API_URL       => "$Defs::sww_base_url/api/",
};

main();

sub main {
    my %Data = ();
    my $db   = connectDB();

    my $st = qq[
		SELECT
			*
		FROM
			tblStatistics_CompAges
	];

    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute() or query_error($st);

    open LOGFILE, "> STATISTICS_compAges.sql";

    my @rows = ();

    my $stClr = qq[DELETE FROM tblStatistics_CompAges WHERE intLocked=0;\n];
    print LOGFILE $stClr;
    while ( my $dref = $qry->fetchrow_hashref() ) {
        my $realmID      = $dref->{'intRealmID'}   || next;
        my $assocID      = $dref->{'intAssocID'}   || next;
        my $compID       = $dref->{'intCompID'}    || next;
        my $dblAvgAge    = $dref->{'dblAvgAge'}    || 0;
        my $dblMinAge    = $dref->{'dblMinAge'}    || 0;
        my $dblMaxAge    = $dref->{'dblMaxAge'}    || 0;
        my $dblModeAge   = $dref->{'dblModeAge'}   || 0;
        my $dblMeanAge   = $dref->{'dblMeanAge'}   || 0;
        my $dblMedianAge = $dref->{'dblMedianAge'} || 0;
        my $dtRun        = $dref->{'dtRun'};
        my $ins =
qq[INSERT INTO tblStatistics_CompAges (intSWMAssocID, intSWMCompID, intSWMRealmID, dblAvgAge, dblMinAge, dblMaxAge, dblModeAge, dblMeanAge, dblMedianAge, dtRun) VALUES ($assocID, $compID, $realmID, $dblAvgAge, $dblMinAge, $dblMaxAge, $dblModeAge, $dblMeanAge, $dblMedianAge, "$dtRun");\n];
        print LOGFILE $ins;
        my @cols = ( $assocID, $compID, $realmID, $dblAvgAge, $dblMinAge, $dblMaxAge, $dblModeAge, $dblMeanAge, $dblMedianAge, "$dtRun" );
        push @rows, \@cols;
    }
    my $stUpdate =
qq[UPDATE tblStatistics_CompAges as S INNER JOIN tblComp as C ON (C.intOnlineID=S.intSWMCompID) SET intSWWAssocID=C.intAssocID, intSWWCompID=C.intCompID WHERE S.intLocked=0 and S.intSWWCompID=0;\n];
    print LOGFILE $stUpdate;

    my $session_key = _get_session_key();
    if ($session_key) {
        _call_api( 'UpdateCompAgesStats', $session_key, { Stats => \@rows } );
    }

    close LOGFILE;
}

sub _get_session_key {
    my $data = _call_api( 'Authorise', '', { 'Signature' => WEBSITES_API_SIGNATURE } );
    my $session_key = $data->{Response}{Data}{SessionKey};
    return $session_key;
}

sub _call_api {
    my ( $action, $session_key, $data ) = @_;

    my $api_url = WEBSITES_API_URL;
    my $ua      = LWP::UserAgent->new;
    $ua->agent('SWM');
    my $request_obj = HTTP::Request->new( GET => $api_url );
    #$request_obj->authorization_basic('script1', 'axe526');
    my $Request = {
                    Request => {
                                 Version => '1.0',
                                 Action  => $action,
                                 Data    => $data,
                    },
    };
    if ($session_key) {
        $Request->{Request}{SessionKey} = $session_key;
    }
    my $msg = encode_json( $Request->{Request} );
    $request_obj->header( 'Content-type' => 'application/json' );
    $request_obj->content($msg);

    my $response_obj = $ua->request($request_obj);
    my $responsetxt  = '';
    my $response     = '';

    if ( $response_obj->is_success ) {
        $responsetxt = $response_obj->content;
        $response    = decode_json($responsetxt);
    }

    return $response;
}
1;
