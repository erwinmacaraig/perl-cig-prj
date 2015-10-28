#!/usr/bin/perl
use warnings;
use strict;

use Date::Calc qw(Add_Delta_DHMS Today_and_Now);
my ($Year,$Month,$Day,$Hr,$Min,$Sec) = Add_Delta_DHMS(Today_and_Now(), 0, 0, 10, 0);
#$Year+=1900;
#$Month++;
$Hr= sprintf("%02s", $Hr);
$Min= sprintf("%02s", $Min);
$Sec= sprintf("%02s", $Sec);
$Month = sprintf("%02s", $Month);
$Day = sprintf("%02s", $Day);
my $ValidityDate= "$Year-$Month-$Day $Hr:$Min:$Sec";
print $ValidityDate;
