#!/usr/bin/perl
use warnings;
use strict;
use lib "../web";
use MA_Gateways;


main();

sub main {
    my $logID =  $ARGV[0];
print "S-R $logID\n";
    my $checksum = calcuatePaymentCheckSum($logID);
    print "S-NUMBER WAS: $logID\n";
    print "S-CHECKSUM IS $checksum\n";
    my $number = $logID . $checksum;
    print "S-NEW NUMBER IS $number\n\n";
}
