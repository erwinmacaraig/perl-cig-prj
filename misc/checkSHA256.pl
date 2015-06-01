#!/usr/bin/perl
use warnings;
use strict;

use Digest::SHA qw(hmac_sha256_hex);
my %v = ();
$v{'VERSION'} ="0001";
$v{'STAMP'} =109;
$v{'REFERENCE'} =109;
$v{'PAYMENT'} = 21924557;
$v{'STATUS'} =2;
$v{'ALGORITHM'} =3;

my $str = "$v{'VERSION'}&$v{'STAMP'}&$v{'REFERENCE'}&$v{'PAYMENT'}&$v{'STATUS'}&$v{'ALGORITHM'}";
my $digest=uc(hmac_sha256_hex($str, "SAIPPUAKAUPPIAS"));
print "CALC Digest:\n$digest\n";
print "vs\n375B6B34A4B2735E41251A43D1F0330ACCBDE77A229C47C2203E275ABB73991C\n\n\n";
