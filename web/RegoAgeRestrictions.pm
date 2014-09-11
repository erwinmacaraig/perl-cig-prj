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

sub checkRegoAgeRestrictions {
    my ($Data, $personID, $personRegistrationID, $sport, $personType, $entityRole, $personLevel, $ageLevel) = @_;

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
            $sport = $regs->[0]{'strSport'};
            $personType = $regs->[0]{'strPersonType'};
            $entityRole = $regs->[0]{'strPersonEntityRole'};
            $personLevel = $regs->[0]{'strPersonLevel'};
            $ageLevel = $regs->[0]{'strAgeLevel'};
            $entityID = $regs->[0]{'intEntityID'};
            $dtDOB = $regs->[0]{'dtDOB'};
            $personAge = $regs->[0]{'personAge'};
        }
    } else {
        $personDetails = loadPersonDetails($Data->{'db'}, $personID);
        $personAge = $personDetails->{'currentAge'} or undef;
    }

    #print Dumper $personDetails;
    #print Dumper $personAge;
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


    #print Dumper $Data;
    #print Dumper @limitValues;
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
    if (defined $ageLevel) {
        push @limitValues, $ageLevel;
        $st .= qq[ AND strAgeLevel IN ('', ?)];
    }

    my $query = $Data->{'db'}->prepare($st);
    $query->execute(@limitValues);

    my $dref = $query->fetchrow_hashref();
    print Dumper $dref;
}
1;
