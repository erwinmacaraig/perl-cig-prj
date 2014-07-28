#!/usr/bin/perl

use strict;
use lib "../","../web";
use Utils;

my $db = connectDB();


my $st = qq[
    INSERT INTO tblWFRule (
        intRealmID,
        intOriginLevel,
        strWFRuleFor,
        strRegistrationNature,
        strPersonType,
        strPersonLevel,
        strSport,
        strAgeLevel,
        strTaskType
    )
    VALUES (
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?
    )
];

my $q = $db->prepare($st);
my $realm = 1;
my $origin = 100;
foreach my $sport (keys %Defs::sportType)   {
    foreach my $nature (keys %Defs::registrationNature)   {
        foreach my $personType (keys %Defs::personType)   {
            foreach my $personLevel (keys %Defs::personLevel)   {
                foreach my $ageLevel (keys %Defs::ageLevel)   {
                    $q->execute(
                        $realm,
                        $origin,
                        'REGO',
                        $nature,
                        $personType,
                        $personLevel,
                        $sport,
                        $ageLevel,
                        'APPROVAL',
                    );
                }
            }
        }
    }
}



