package RegistrationWindow;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    checkPersonRegistrationWindow
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
use AssocTime;
use Switch;

sub checkPersonRegistrationWindow {
    my ($Data,
        $searchFields,
        $searchFieldValues,
    ) = @_;

    my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);

    my @values;
    my $order = _matrixFieldOrder();

    my $st = qq [
        SELECT
            COUNT(intMatrixID)
        FROM tblMatrix
        WHERE
        1
        AND intLocked = 0
        AND (
                (intHonourOpenDates = 0 OR intHonourOpenDates IS NULL)
                OR
                (intHonourOpenDates = 1 AND (? BETWEEN dtOpenFrom AND dtOpenTo))
            )
    ];

    #for loans, ALWAYS set intHonourOpenDates to 0
    #a loan can be added outside the window
    push @values, $today;

    for my $searchField (@{$searchFields}) {
        $st .= $order->{$searchField}{'queryBlock'};
        push @values, $searchFieldValues->{$searchField};
    }

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(@values);
    my $result = $q->fetchrow_array();
    return  $result || 0;
}

sub _matrixFieldOrder {
    my $orderToCheck = {
        'strRegistrationNature' => {
            'queryBlock' => qq [ AND strRegistrationNature = ? ],
        },
        'strPersonType' => {
            'queryBlock' => qq [ AND strPersonType = ? ],
        },
        'strSport' => {
            'queryBlock' => qq [ AND strSport = ? ],
        },
        'strPersonLevel' => {
            'queryBlock' => qq [ AND strPersonLevel = ? ],
        },
        'intRealmID' => {
            'queryBlock' => qq [ AND intRealmID = ? ],
        },
        'intSubRealmID' => {
            'queryBlock' => qq [ AND intSubRealmID IN (0, ?) ],
        },
        'strWFRuleFor' => {
            'queryBlock' => qq [ AND strWFRuleFor = ? ],
        },
    };

    return $orderToCheck;
}
1;
