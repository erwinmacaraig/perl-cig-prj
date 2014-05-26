#! /usr/bin/perl -w

use strict;

use lib '..', '../..';

use CGI qw(param);
use Utils;
use Data::Dumper;
use Log;
use Defs;
use SystemConfig;
use TTTemplate;

my $cgi = CGI->new();
my $dbh = connectDB();
my $content = '';
my ( $entity_type, $entity, $realm, $subrealm ) = ( 0, 0, 0, 0 );

if ( param('id') ) {
    my $encoded_param = param('id');
    if ( $encoded_param =~ /(\w+)?/ ) {
        $encoded_param = $1;
    }
    my $decoded_param = decode($encoded_param);

    my $params = {};
    for ( split '&', $decoded_param ) {
        my ( $k, $v ) = split '=', $_;
        $params->{$k} = $v;
    }

    my $table_name = $params->{'table_name'};
    my $entry_id   = $params->{'entry_id'};

    my $st = '';
    if ( $table_name eq 'tblOptinMember' ) {
        my $st = qq( SELECT O.strOptinText, OM.intEntityTypeID, OM.intEntityID FROM tblOptin AS O JOIN tblOptinMember AS OM ON O.intOptinID=OM.intOptinID WHERE OM.intOptinMemberID = $entry_id );
        my $q = $dbh->prepare($st);
        $q->execute();
        ( my $text, $entity_type, $entity ) = $q->fetchrow_array();

        my $entity_name = '';
        ( $realm, $subrealm, $entity_name ) = get_info( $dbh, $entity_type, $entity );

        $content .= qq(
            <form action="3rdparty_unsubscribe.cgi" method="post">
            <p class="item-info">You are currently subscribed to $entity_name:</p>
            <p class="item-info">$text</p>
            <p class="item-info">Please confirm that you would like to unsubscribe.</p>
        );
    }
    elsif ( $table_name eq 'tblNewsletterOptin' ) {
        my $st = qq( SELECT N.intNewsletterID, N.strName, N.intEntityTypeID, N.intEntityID FROM tblNewsletter AS N JOIN tblNewsletterOptin AS NO ON N.intNewsletterID=NO.intNewsletterID WHERE NO.strEmail = '$entry_id' AND intAction=1);
        my $q = $dbh->prepare($st);
        $q->execute();
        
        $content .= qq(
            <form action="3rdparty_unsubscribe.cgi" method="post">
            <p class="item-info">You are currently subscribed to below newsletters:</p>
        );
        while ( ( my $newsletter_id, my $newsletter_name, $entity_type, $entity ) = $q->fetchrow_array() ) {
            my $entity_name = '';
            ( $realm, $subrealm, $entity_name ) = get_info( $dbh, $entity_type, $entity );
            $content .= qq(<p class="item-info"><input type="checkbox" name="newsletter" value="$newsletter_id">$entity_name: $newsletter_name</p>);
        }
    }
    else {
    }

    $content .= qq(
        <input type="hidden" name="table_name" value="$table_name">
        <input type="hidden" name="entry_id" value="$entry_id">
        <input type="hidden" name="realm" value="$realm">
        <input type="hidden" name="subrealm" value="$subrealm">
        <p class="item-info"><input type="submit" name="unsubscribe" value="Unsubscribe" class="button generic-button"></p>
        </form>
    );
}
elsif ( param('unsubscribe') ) {
    my $table_name  = param('table_name');
    my $entry_id    = param('entry_id');
    $realm          = param('realm');
    $subrealm       = param('subrealm');

    if ( $table_name eq 'tblOptinMember' ) {
        my $st = qq( UPDATE $table_name SET intAction=0 WHERE intOptinMemberID=$entry_id );
        $dbh->do($st);
    }
    elsif ( $table_name eq 'tblNewsletterOptin' ) {
        my $st = qq( UPDATE $table_name SET intAction=0, dtOptOut=NOW() WHERE strEmail=? AND intNewsletterID=? );
        my $q = $dbh->prepare($st);
        my @newsletter_ids = param('newsletter');

        for my $newsletter_id (@newsletter_ids) {
            $q->execute( $entry_id, $newsletter_id );
        }
    }
    else {
        # do nothing
    }

    $content .= qq(
        <p class="item-info">You have been successfully unsubscribed.</p>
    );
}
else {
    # do nothing
}

my ($header, $otherstyle ) =  get_header( $dbh, $realm, $subrealm );

my $templ_ref = { 'Header' => $header, 'Otherstyle' => $otherstyle, 'Content' => $content };
my $result = runTemplate(
    undef,
    $templ_ref,
  	'regoform/common/3rdparty_unsubscribe.templ'
);
my $body = $result if ($result);

disconnectDB($dbh);
print "Content-type: text/html\n\n";
print $body;


sub get_info {
    my ( $dbh, $entity_type, $entity ) = @_;

    my $st = '';
    if ( $entity_type < $Defs::LEVEL_ASSOC ) {
        $st = qq[ SELECT C.strName, A.intRealmID, A.intAssocTypeID FROM tblAssoc AS A JOIN tblAssoc_Clubs AS AC ON A.intAssocID = AC.intAssocID JOIN tblClub AS C ON AC.intClubID=C.intClubID WHERE AC.intClubID = $entity ];
    }
    elsif ( $entity_type == $Defs::LEVEL_ASSOC ) {
        $st = qq[ SELECT strName, intRealmID, intAssocTypeID FROM tblAssoc WHERE intAssocID = $entity ];
    }
    elsif ( $entity_type > $Defs::LEVEL_ASSOC ) {
        $st = qq[ SELECT strName, intRealmID, intSubTypeID FROM tblNode WHERE intNodeID = $entity ];
    }
    else {
        # do nothing
    }
    my $q = $dbh->prepare($st);
    $q->execute();

    my ( $entity_name, $realm, $subrealm ) = ( '', 0, 0 );
    ( $entity_name, $realm, $subrealm ) = $q->fetchrow_array();

    return $realm, $subrealm, $entity_name;
}

sub get_header {
    my ( $dbh, $realm, $subrealm ) = @_;

    my $data = { 'db' => $dbh, 'Realm' => $realm, 'RealmSubType' => $subrealm };
    my $system_config = getSystemConfig($data);

	my $header=qq[<img src="images/sp_membership.png" >];
	$header=$system_config->{'Header'} if $system_config->{'Header'};
    $header=$system_config->{'AssocConfig'}{'Header'} if $system_config->{'AssocConfig'}{'Header'};
	my $otherstyle='';
	$otherstyle.=$system_config->{'OtherStyle'} if $system_config->{'OtherStyle'};
	$otherstyle.=$system_config->{'HeaderBG'} if $system_config->{'HeaderBG'};
	$otherstyle=qq[<style type="text/css">$otherstyle</style>] if $otherstyle;

    return $header, $otherstyle;
}
