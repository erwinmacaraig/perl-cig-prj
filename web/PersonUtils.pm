package PersonUtils;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  formatPersonName
  personAge
  personIsMinor
  minorComparisonDate
);

use strict;
use lib '.', '..', 'Clearances';
use Date::Calc qw(Today Delta_YMD Add_Delta_YM Add_Delta_Days);
use Defs;
use AssocTime;

sub formatPersonName {

    my ($Data, $firstname, $surname, $gender) = @_;
    
    return "$firstname $surname";
}

sub personAge {

    my ($Data, $dob) = @_;
    
    return 0 if !$dob;
    my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);
    my $dateAs = $Data->{'SystemConfig'}{'Age-DateAsOf'} || $today;
    return 0 if !$dateAs;
    my($dateAs_y,$dateAs_m,$dateAs_d) = $dateAs =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
    my($y,$m,$d) = $dob =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
    return 0 if(!$y or !$m or !$d);
    my ( $age_year, $age_month, $age_day ) = Delta_YMD( $y, $m, $d, $dateAs_y, $dateAs_m, $dateAs_d);

    return $age_year || 0;
}

sub personIsMinor   {
    my ($Data, $dob) = @_;

    my $age = personAge($Data, $dob);
    my $adultAge = $Data->{'SystemConfig'}{'Age-Adult'} || 18;
    return 1 if $age < $adultAge;
    return 0;
}

sub minorComparisonDate {
    my ($Data) = @_;
    #this function will return the oldest DOB to be accepted as a minor
    my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);
    my $dateAs = $Data->{'SystemConfig'}{'Age-DateAsOf'} || $today;
    my $adultAge = $Data->{'SystemConfig'}{'Age-Adult'} || 18;
    my($dateAs_y,$dateAs_m,$dateAs_d) = $dateAs =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
    my ( $age_year, $age_month, $age_day ) = Add_Delta_Days(Add_Delta_YM( $dateAs_y, $dateAs_m, $dateAs_d, -$adultAge, 0),1);
    return "$age_year-$age_month-$age_day";
}
1;

