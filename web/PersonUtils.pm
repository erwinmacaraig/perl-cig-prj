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
use Switch;

sub formatPersonName {

    my ($Data, $firstname, $surname, $gender) = @_;  
    my $locale;
    if(defined $Data->{'lang'}){
        $locale = $Data->{'lang'}->getLocale();
    }    
    switch($locale){
        case ['en_US', 'fi_FI','sv_FI'] {
            return "$firstname $surname";
        }
        case 'zh_CN' {
            return "$surname $firstname";
        }
    }
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
    return 0 if($y eq '0000' or $m eq '00' or $d eq '00');
    my ( $age_year, $age_month, $age_day ) = Delta_YMD( $y, $m, $d, $dateAs_y, $dateAs_m, $dateAs_d);
    $age_year-- unless (sprintf("%02d%02d",$dateAs_m,$dateAs_d) >= sprintf("%02d%02d",$m,$d));
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
    #this function will return the DOB's where the person needs to be between to be accepted as a minor
    my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);
    my $dateAs = $Data->{'SystemConfig'}{'Age-DateAsOf'} || $today;
    my $adultAge = $Data->{'SystemConfig'}{'Age-Adult'} || 18;
    my $tooYoungAge = $Data->{'SystemConfig'}{'Age-TooYoung'} || 10;
    my($dateAs_y,$dateAs_m,$dateAs_d) = $dateAs =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
    my ( $age_year, $age_month, $age_day ) = Add_Delta_Days(Add_Delta_YM( $dateAs_y, $dateAs_m, $dateAs_d, -$adultAge, 0),-1);
    $age_month = '0'.$age_month if $age_month < 10;
    $age_day = '0'.$age_day if $age_day < 10;
    my ( $agel_year, $agel_month, $agel_day ) = Add_Delta_Days(Add_Delta_YM( $dateAs_y, $dateAs_m, $dateAs_d, -$tooYoungAge, 0),1);
    $agel_month = '0'.$agel_month if $agel_month < 10;
    $agel_day = '0'.$agel_day if $agel_day < 10;
    my $ageHigh = "$age_year-$age_month-$age_day";
    my $ageLow= "$agel_year-$agel_month-$agel_day";
    return ($ageHigh, $ageLow);
}
1;

