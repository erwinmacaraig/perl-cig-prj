package RegoAgeRestrictions;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    checkRegoAgeRestrictions
);

use lib ".", "..";
use strict;
use Reg_common;
use Utils;
use AuditLog;
use CGI qw(unescape param);
use Log;
use PersonRegistration;
use Person;
use Data::Dumper;
use SystemConfig;
use List::MoreUtils qw(uniq);

sub checkRegoAgeRestrictions {
    my ($Data, $personID, $personRegistrationID, $sport, $personType, $entityRole, $personLevel, @ageLevel) = @_;

    $personID ||= 0;
    $personRegistrationID ||= 0;
    my $entityID = 0;
    my $dtDOB;
    my $personAge;
    my $personDetails;

    if ($personRegistrationID) {
        my %Reg = (
            personRegistrationID => $personRegistrationID,
        );

        my ($count, $regs) = PersonRegistration::getRegistrationData(
            $Data,
            $personID,
            \%Reg
        );

        if ($count == 1) {
            @ageLevel = ();
            push @ageLevel, $regs->[0]{'strAgeLevel'};
            $sport = $regs->[0]{'strSport'};
            $personType = $regs->[0]{'strPersonType'};
            $entityRole = $regs->[0]{'strPersonEntityRole'};
            $personLevel = $regs->[0]{'strPersonLevel'};
            $entityID = $regs->[0]{'intEntityID'};
            $dtDOB = $regs->[0]{'dtDOB'};
            $personAge = $regs->[0]{'currentAge'};
        }
    } else {
        $personDetails = Person::loadPersonDetails($Data, $personID);
        #print STDERR Dumper $personDetails;
        $personAge = $personDetails->{'currentAge'} or undef;
    }

    return 0 if(!defined($personAge));

    my $st = qq[
        SELECT 
            *
        FROM
            tblRegoAgeRestrictions
        WHERE 
            intRealmID = ?
            AND intSubRealmID IN (0, ?)
            AND strPersonType = ?
            AND ? BETWEEN intFromAge AND intToAge
    ];
    my @limitValues = (
        $Data->{'Realm'}, 
        $Data->{'RealmSubType'},
        $personType,
        $personAge,
    );

    if (defined $sport) {
        push @limitValues, $sport;
        $st .= qq[ AND strSport IN ('', ?)];
    }
    if (defined $entityRole) {
        push @limitValues, $entityRole;
        $st .= qq[ AND strPersonEntityRole IN ('', ?)];
    }
    if (defined $personLevel) {
        push @limitValues, $personLevel;
        $st .= qq[ AND strPersonLevel IN ('', ?)];
    }

    if (scalar(@ageLevel)) {
        #push @limitValues, $ageLevel;
        my $strMergeAgeString = "'" . join("','", @ageLevel) . "'";
        $st .= qq[ AND strAgeLevel IN ('', $strMergeAgeString)];
    }

    $st .= qq [ ORDER BY strAgeLevel ASC ];

    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@limitValues);

    my @retrievedValues = ();
    while (my $dref = $query->fetchrow_hashref()) {
        push @retrievedValues, $dref->{'strAgeLevel'};
        if($dref->{'strAgeLevel'} eq '') {
            #strAgeLevel is optional; return @ageLevel if that's the case
            @retrievedValues = ();
            @retrievedValues = @ageLevel;
            last;
        }
    }

    my @uniqueAgeLevelOptions = uniq @retrievedValues;

    return 0 if !@uniqueAgeLevelOptions;

    my $systemConfig = getSystemConfig($Data);
    $Data->{'SystemConfig'} = $systemConfig;

    my $personAgeLevel = Person::calculateAgeLevel($Data, $personAge);

    my @retdata = ();
    foreach(@uniqueAgeLevelOptions) {
        if($_ eq '') {
            push @retdata, {
                name => '-',
                value => '',
            };
        }
        elsif($personAgeLevel eq $_) {
            push @retdata, {
                name => $Data->{'lang'}->txt($Defs::ageLevel{$_}),
                value => $_,
            };
        }
    }

    return \@retdata;
}
1;
