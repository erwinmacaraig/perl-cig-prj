#
# $Header: svn://svn/SWM/trunk/web/user/UserList.pm 10973 2014-03-13 05:31:22Z eobrien $
#

package UserList;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  getAuthOrgLists
  getAuthOrgListsData
);
@EXPORT_OK = qw(
  getAuthOrgLists
  getAuthOrgListsData
);

use lib "..", "../..";
use Defs;
use strict;
use CGI qw(:cgi escape);
use TTTemplate;
use Reg_common;
use Logo;

sub getAuthOrgListsData {
    my ( $Data, $userID) = @_;

    my $db = $Data->{'db'};

    my $st_pa = qq[
        SELECT
            entityTypeID,
            entityID
        FROM
            tblUserAuth AS PA
        WHERE userID = ?
    ];
    my $q_pa = $db->prepare($st_pa);
    $q_pa->execute($userID);
    my %orgs  = ();
    my %nodes = ();
    while ( my ( $typeID, $entityID ) = $q_pa->fetchrow_array() ) {
        $orgs{$typeID}{$entityID} = 1;
        if ( $typeID >= $Defs::LEVEL_CLUB) {
            $nodes{$entityID} = 1;
        }
    }

    my $member_str = join( ',', keys %{ $orgs{$Defs::LEVEL_MEMBER} } );
    my $club_str   = join( ',', keys %{ $orgs{$Defs::LEVEL_CLUB} } );

    my $node_str = join( ',', keys %nodes );
    my %org_data = ();
    my %realms   = ();

    my %LevelNames = ();
    if ($member_str) {
        my $st = qq[
            SELECT    
                intMemberID,
                intRealmID,
                concat_ws(' ', strFirstname, strSurname) as strName
            FROM
                tblMember
            WHERE intMemberID IN ($member_str)
            ORDER BY strName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $realm, $name ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            if ( !$LevelNames{$realm}{$Defs::LEVEL_MEMBER} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_MEMBER} || 'Association';
            my $logoURL = showLogo( $Data, $Defs::LEVEL_MEMBER, $id, '', 0, 100, 0, );

            my $url = "$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_ASSOC";

            push @{ $org_data{$Defs::LEVEL_MEMBER} },
              {
                Name     => $name || next,
                EntityID => $id   || next,
                EntityTypeID => $Defs::LEVEL_MEMBER,
                Logo         => $logoURL,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($club_str) {
        my $st = qq[
            SELECT    
                E.intEntityID,
                E.strLocalName,
                R.strRealmName
            FROM
                tblEntity AS E
                INNER JOIN tblRealms AS R ON E.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = $Defs::LEVEL_CLUB
                    AND UF.intEntityID = E.intEntityID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE E.intEntityID IN ($club_str)
                AND E.intEntityLevel = $Defs::LEVEL_CLUB
            ORDER BY E.strLocalName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $Defs::LEVEL_CLUB, $id, '', 0, 100, 0, );

            if ( !$LevelNames{$realm}{$Defs::LEVEL_CLUB} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_CLUB} || 'Club';
            my $url = "$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_CLUB";
            push @{ $org_data{$Defs::LEVEL_CLUB} },
              {
                Name     => $name || next,
                EntityID => $id   || next,
                EntityTypeID => $Defs::LEVEL_CLUB,
                Logo         => $logoURL,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($node_str) {
        my $st = qq[
            SELECT    
                E.intEntityID,
                E.strLocalName,
                E.intEntityLevel,
                R.strRealmName
            FROM
                tblEntity AS E
                INNER JOIN tblRealms AS R ON E.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = E.intEntityLevel
                    AND UF.intEntityID = E.intEntityID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE E.intEntityID IN ($node_str)
                AND E.intEntityLevel > $Defs::LEVEL_CLUB
            ORDER BY E.strLocalName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $type, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $type, $id, '', 0, 100, 0, );
            if ( !$LevelNames{$realm}{$type} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$type} || '';
            my $url = "$Defs::base_url/authenticate.cgi?i=$id&amp;t=$type";
            push @{ $org_data{$type} },
              {
                Name         => $name || next,
                EntityID     => $id   || next,
                EntityTypeID => $type || next,
                Logo         => $logoURL,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    my %assocVenues = ();
    my @outdata = ();
    for my $level (
                    $Defs::LEVEL_TOP,
                    $Defs::LEVEL_INTERNATIONAL, $Defs::LEVEL_INTREGION,
                    $Defs::LEVEL_INTZONE,       $Defs::LEVEL_NATIONAL,
                    $Defs::LEVEL_STATE,         $Defs::LEVEL_REGION,
                    $Defs::LEVEL_ZONE,          
                    $Defs::LEVEL_CLUB
      )
    {
        if ( $org_data{$level} ) {
            push @outdata, @{ $org_data{$level} };
        }
    }

    return ( \@outdata, scalar( keys %realms ) );
}

sub getAuthOrgLists {
    my ( $Data, $userID) = @_;

    my $db = $Data->{'db'};

    my ( $authdata, $numrealms ) = getAuthOrgListsData( $Data, $userID );

    my $templateFile = 'user/login_orgs.templ';

    my $body = runTemplate(
        $Data,
        {
           AuthData       => $authdata,
           NumberOfRealms => $numrealms,
        },
        $templateFile,
    );

    return $body;
}

sub getNames {
    my ( $db, $realmID, ) = @_;

    my %tData = (
      db    => $db,
      Realm => $realmID
    );
    getDBConfig( \%tData );
    return $tData{'LevelNames'} || {};
}

1;
