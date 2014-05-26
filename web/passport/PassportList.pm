#
# $Header: svn://svn/SWM/trunk/web/passport/PassportList.pm 10973 2014-03-13 05:31:22Z eobrien $
#

package PassportList;
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
    my ( $Data, $passportID, $resultsentry, ) = @_;

    $resultsentry ||= 0;

    my $db = $Data->{'db'};

    my $st_pa = qq[
        SELECT
            intEntityTypeID,
            intEntityID,
            intAssocID
        FROM
            tblPassportAuth AS PA
        WHERE intPassportID = ?
    ];
    my $q_pa = $db->prepare($st_pa);
    $q_pa->execute($passportID);
    my %orgs  = ();
    my %nodes = ();
    while ( my ( $typeID, $entityID ) = $q_pa->fetchrow_array() ) {
        if ($resultsentry) {
            next if $typeID > $Defs::LEVEL_ASSOC;
        }
        $orgs{$typeID}{$entityID} = 1;
        if ( $typeID > $Defs::LEVEL_ASSOC ) {
            $nodes{$entityID} = 1;
        }
    }

    my $member_str = join( ',', keys %{ $orgs{$Defs::LEVEL_MEMBER} } );
    my $assoc_str  = join( ',', keys %{ $orgs{$Defs::LEVEL_ASSOC} } );
    my $club_str   = join( ',', keys %{ $orgs{$Defs::LEVEL_CLUB} } );
    my $team_str   = join( ',', keys %{ $orgs{$Defs::LEVEL_TEAM} } );
    my $venue_str  = join( ',', keys %{ $orgs{$Defs::LEVEL_VENUE} } );
    my $event_str  = join( ',', keys %{ $orgs{$Defs::LEVEL_EVENT} } );
    my $osep_str   = join( ',', keys %{ $orgs{$Defs::LEVEL_EDU_DA} } );
    my $osep_str2  = join( ',', keys %{ $orgs{$Defs::LEVEL_EDU_ADMIN} } );

    #my $osep_str  = join(
    #    ',',
    #    keys %{
    #        $orgs{$Defs::LEVEL_EDU_ADMIN}, $orgs{$Defs::LEVEL_EDU_DA},
    #        $orgs{$Defs::LEVEL_EDU_MODULE}
    #    }
    #);

    my $node_str = join( ',', keys %nodes );
    my %org_data = ();
    my %realms   = ();

    my $swol_filter = '';
    if ($resultsentry) {
        $swol_filter = ' AND A.intSWOL = 1 ';
    }

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

            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_ASSOC");
            if ($resultsentry) {
                $url =
                  "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url="
                  . escape("$Defs::base_url/results/onlineresults.cgi?aID=$id&amp;e=$id&amp;et=$Defs::LEVEL_ASSOC&amp;a=LIST_MATCHES");
            }
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
    if ($assoc_str) {
        my $st = qq[
            SELECT    
                intAssocID,
                strName,
                strRealmName
            FROM
                tblAssoc AS A
                INNER JOIN tblRealms AS R ON A.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = $Defs::LEVEL_ASSOC
                    AND UF.intEntityID = A.intAssocID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE intAssocID IN ($assoc_str)
                AND A.intRecStatus <> -1
                $swol_filter
            ORDER BY strName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            if ( !$LevelNames{$realm}{$Defs::LEVEL_ASSOC} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_ASSOC} || 'Association';
            my $logoURL = showLogo( $Data, $Defs::LEVEL_ASSOC, $id, '', 0, 100, 0, );

            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_ASSOC");
            if ($resultsentry) {
                $url =
                  "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url="
                  . escape("$Defs::base_url/results/onlineresults.cgi?aID=$id&amp;e=$id&amp;et=$Defs::LEVEL_ASSOC&amp;a=LIST_MATCHES");
            }
            push @{ $org_data{$Defs::LEVEL_ASSOC} },
              {
                Name     => $name || next,
                EntityID => $id   || next,
                EntityTypeID => $Defs::LEVEL_ASSOC,
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
                C.intClubID,
                C.strName,
                A.strName AS AssocName,
                A.intAssocID,
                R.strRealmName
            FROM
                tblClub AS C
                INNER JOIN tblAssoc_Clubs AS AC ON (
                    C.intClubID = AC.intClubID
                )
                INNER JOIN tblAssoc AS A ON (
                    AC.intAssocID = A.intAssocID
                )
                INNER JOIN tblRealms AS R ON A.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = $Defs::LEVEL_CLUB
                    AND UF.intEntityID = C.intClubID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE C.intClubID IN ($club_str)
                AND C.intRecStatus <> -1
                $swol_filter
            ORDER BY C.strName, AssocName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $assocname, $assocID, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $Defs::LEVEL_CLUB, $id, '', 0, 100, 0, );

            if ( !$LevelNames{$realm}{$Defs::LEVEL_CLUB} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_CLUB} || 'Club';
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_CLUB");
            if ($resultsentry) {
                $url =
                  "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url="
                  . escape("$Defs::base_url/results/onlineresults.cgi?aID=$assocID&amp;e=$id&amp;et=$Defs::LEVEL_CLUB&amp;a=LIST_MATCHES");
            }
            push @{ $org_data{$Defs::LEVEL_CLUB} },
              {
                Name     => $name || next,
                EntityID => $id   || next,
                EntityTypeID => $Defs::LEVEL_CLUB,
                Logo         => $logoURL,
                AssocName    => $assocname,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($team_str) {
        my $st = qq[
            SELECT DISTINCT
                T.intTeamID,
                T.strName,
		IF(group_concat(AC.strTitle ORDER BY AC.strTitle DESC SEPARATOR ' ||-||') LIKE "%||-||%",'Many Competitions',group_concat(AC.strTitle)) AS CompName,
                A.strName AS AssocName,
                A.intAssocID,
                R.strRealmName
            FROM
                tblTeam AS T
                INNER JOIN tblAssoc AS A ON (
                    T.intAssocID = A.intAssocID
                )
                INNER JOIN tblRealms AS R ON A.intRealmID = R.intRealmID
                LEFT JOIN tblComp_Teams AS CT ON T.intTeamID=CT.intTeamID AND CT.intRecStatus>-1
                LEFT JOIN tblAssoc_Comp AS AC ON CT.intCompID=AC.intCompID AND AC.intAssocID=A.intAssocID AND AC.intRecStatus>-1 AND AC.intNewSeasonID = A.intCurrentSeasonID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = $Defs::LEVEL_TEAM
                    AND UF.intEntityID = T.intTeamID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE T.intTeamID IN ($team_str)
                AND T.intRecStatus <> -1
                $swol_filter
		GROUP BY T.intTeamID
            ORDER BY T.strName, AssocName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $compname, $assocname, $assocID, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $Defs::LEVEL_TEAM, $id, '', 0, 100, 0, );
            if ( !$LevelNames{$realm}{$Defs::LEVEL_TEAM} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_TEAM} || 'Team';
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_TEAM");
            if ($resultsentry) {
                $url =
                  "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url="
                  . escape("$Defs::base_url/results/onlineresults.cgi?aID=$assocID&amp;e=$id&amp;et=$Defs::LEVEL_TEAM&amp;a=LIST_MATCHES");
            }
            push @{ $org_data{$Defs::LEVEL_TEAM} },
              {
                Name     => $name || next,
                EntityID => $id   || next,
                EntityTypeID => $Defs::LEVEL_TEAM,
                Logo         => $logoURL,
                CompName     => $compname,
                AssocName    => $assocname,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($event_str) {
        my $st = qq[
            SELECT    
                intEventID,
                strEventName,
                strRealmName
            FROM
                tblEvent AS E
                INNER JOIN tblRealms AS R ON E.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = $Defs::LEVEL_EVENT
                    AND UF.intEntityID = E.intEventID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE intEventID IN ($event_str)
                $swol_filter
            ORDER BY strEventName
        ];

        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $Defs::LEVEL_EVENT, $id, '', 0, 100, 0, );
            if ( !$LevelNames{$realm}{$Defs::LEVEL_EVENT} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$Defs::LEVEL_EVENT} || '';
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$Defs::LEVEL_EVENT");
            push @{ $org_data{$Defs::LEVEL_EVENT} },
              {
                Name         => $name              || next,
                EntityID     => $id                || next,
                EntityTypeID => $Defs::LEVEL_EVENT || next,
                Logo         => $logoURL,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($osep_str2) {
        my $st = qq[
            SELECT
                DA.intDeliveryAgentID as intID,
                DA.strName,
                A.intLevel,
                R.strRealmName
            FROM
                tblAuth A
                inner join tblEDUDeliveryAgent DA on A.intID = DA.intDeliveryAgentID
                inner join tblEDUEdu E on DA.intEduID = E.intEduID
                INNER JOIN tblRealms AS R ON E.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID in ($Defs::LEVEL_EDU_DA)
                    AND UF.intEntityID = A.intID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE A.intID IN ($osep_str2)
            AND A.intLevel in ($Defs::LEVEL_EDU_ADMIN)
                $swol_filter
            ORDER BY DA.strName
        ];

        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $level, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $level, $id, '', 0, 100, 0, );
            if ( !$LevelNames{$realm}{$level} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$level} || '';
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$level");
            push @{ $org_data{$level} },
              {
                Name         => $name  || next,
                EntityID     => $id    || next,
                EntityTypeID => $level || next,
                Logo         => $logoURL,
                Realm        => $realm,
                LevelName    => $levelname,
                URL          => $url,
              };
        }
    }
    if ($osep_str) {
        my $st = qq[
            SELECT
                DA.intDeliveryAgentID as intID,
                DA.strName,
                A.intLevel,
                R.strRealmName
            FROM
                tblAuth A
                inner join tblEDUDeliveryAgent DA on A.intID = DA.intDeliveryAgentID
                inner join tblEDUEdu E on DA.intEduID = E.intEduID
                INNER JOIN tblRealms AS R ON E.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID in ($Defs::LEVEL_EDU_DA)
                    AND UF.intEntityID = A.intID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE A.intID IN ($osep_str)
            AND A.intLevel in ($Defs::LEVEL_EDU_DA)
                $swol_filter
            ORDER BY DA.strName
        ];

        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $level, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;
            my $logoURL = showLogo( $Data, $level, $id, '', 0, 100, 0, );
            if ( !$LevelNames{$realm}{$level} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = $LevelNames{$realm}{$level} || '';
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$level");
            push @{ $org_data{$level} },
              {
                Name         => $name  || next,
                EntityID     => $id    || next,
                EntityTypeID => $level || next,
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
                N.intNodeID,
                N.strName,
                N.intTypeID,
                R.strRealmName
            FROM
                tblNode AS N
                INNER JOIN tblRealms AS R ON N.intRealmID = R.intRealmID
                LEFT JOIN tblUploadedFiles AS UF ON (
                    UF.intEntityTypeID = N.intTypeID
                    AND UF.intEntityID = N.intNodeID
                    AND UF.intFileType = $Defs::UPLOADFILETYPE_LOGO
                )
            WHERE N.intNodeID IN ($node_str)
                AND N.intStatusID <> -1
            ORDER BY N.strName
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
            my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/authenticate.cgi?i=$id&amp;t=$type");
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
    if ($venue_str) {
        my $st = qq[
            SELECT    
                V.intDefVenueID,
                V.strName,
                A.strName AS AssocName,
                A.intAssocID,
                R.strRealmName
            FROM
                tblDefVenue AS V
                INNER JOIN tblAssoc AS A ON (
                    V.intAssocID = A.intAssocID
                )
                INNER JOIN tblRealms AS R ON A.intRealmID = R.intRealmID
            WHERE V.intDefVenueID IN ($venue_str)
                AND V.intRecStatus <> -1
                $swol_filter
            ORDER BY V.strName, AssocName
        ];
        my $q = $db->prepare($st);
        $q->execute();
        while ( my ( $id, $name, $assocname, $assocID, $realm ) = $q->fetchrow_array() ) {
            $realms{$realm} = 1;

            if ( !$LevelNames{$realm}{$Defs::LEVEL_VENUE} ) {
                $LevelNames{$realm} = getNames( $db, $realm );
            }
            my $levelname = 'Venue';
            my $url =
              "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url="
              . escape("$Defs::base_url/results/onlineresults.cgi?aID=$assocID&amp;e=$id&amp;et=$Defs::LEVEL_VENUE&amp;a=LIST_MATCHES");
            if ( !$assocVenues{$assocID} ) {
                push @{ $org_data{$Defs::LEVEL_VENUE} },
                  {
                    Name         => 'Venue Access',
                    EntityID     => $id || next,
                    EntityTypeID => $Defs::LEVEL_VENUE,
                    Logo         => '',
                    AssocName    => $assocname,
                    Realm        => $realm,
                    LevelName    => $levelname,
                    URL          => $url,
                  };
                $assocVenues{$assocID} = 1;
            }
        }
    }
    {
        my $st = qq[
            SELECT PM.intMemberID, M.intRealmID
            FROM tblPassportMember AS PM
                INNER JOIN tblMember AS M
                    ON PM.intMemberID = M.intMemberID
            WHERE PM.intPassportID = ?
        ];
        my $q_p = $db->prepare($st);
        $q_p->execute($passportID);
        my %passportmembers = ();
        while ( my ( $mID, $r ) = $q_p->fetchrow_array() ) {
            $passportmembers{$mID} = $r || next;
        }
        if ( scalar( keys %passportmembers ) ) {
            for my $mID ( keys %passportmembers ) {
                my $realmID = $passportmembers{$mID};
                my $st_u    = qq[
                    SELECT DISTINCT
                        M.intMemberID,
                        CONCAT( M.strFirstname, ' ', M.strSurname),
                        R.strRealmName
                    FROM
                        tblMember_Seasons_$realmID AS MS
                        INNER JOIN tblMember AS M
                            ON MS.intMemberID = M.intMemberID
                        INNER JOIN tblRealms AS R ON M.intRealmID = R.intRealmID
                    WHERE
                        MS.intMemberID = ?
                        AND intUmpireStatus = 1
                        AND dtOutUmpire IS NULL
                ];
                my $q = $db->prepare($st_u);
                $q->execute($mID);
                while ( my ( $mID, $name, $realm ) = $q->fetchrow_array() ) {
                    my $url = "$Defs::PassportURL/login/?apk=$Defs::PassportPublicKey&amp;url=" . escape("$Defs::base_url/results/matchofficial.cgi?e=$mID&amp;et=MO&amp;a=MO_LIST");
                    push @{ $org_data{'MATCHOFFICIAL'} },
                      {
                        Name         => $name,
                        EntityID     => $mID || next,
                        EntityTypeID => 'MO',
                        Logo         => '',
                        AssocName    => '',
                        Realm        => $realm,
                        LevelName    => 'Match Official',
                        URL          => $url,
                      };
                }
            }
        }
    }

    my @outdata = ();
    for my $level (
                    $Defs::LEVEL_TOP,           $Defs::LEVEL_EDU_ADMIN,
                    $Defs::LEVEL_EDU_DA,        $Defs::LEVEL_EDU_MODULE,
                    $Defs::LEVEL_INTERNATIONAL, $Defs::LEVEL_INTREGION,
                    $Defs::LEVEL_INTZONE,       $Defs::LEVEL_NATIONAL,
                    $Defs::LEVEL_STATE,         $Defs::LEVEL_REGION,
                    $Defs::LEVEL_ZONE,          $Defs::LEVEL_ASSOC,
                    $Defs::LEVEL_CLUB,          $Defs::LEVEL_TEAM,
                    $Defs::LEVEL_VENUE,         $Defs::LEVEL_EVENT,
                    'MATCHOFFICIAL',
      )
    {
        if ( $org_data{$level} ) {
            push @outdata, @{ $org_data{$level} };
        }
    }

    return ( \@outdata, scalar( keys %realms ) );
}

sub getAuthOrgLists {
    my ( $Data, $passportID, $resultsentry, ) = @_;

    my $db = $Data->{'db'};

    my ( $authdata, $numrealms ) = getAuthOrgListsData( $Data, $passportID, $resultsentry || 0, );

    my $templateFile = 'passport/login_orgs.templ';

    my $body = runTemplate(
                            $Data,
                            {
                               AuthData       => $authdata,
                               NumberOfRealms => $numrealms,
                               ResultsEntry   => $resultsentry || 0,
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
