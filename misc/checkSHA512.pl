#!/usr/bin/perl
use warnings;
use strict;
use lib "../web/";
use AssocTime;

use Digest::SHA qw(hmac_sha512_hex sha512_hex sha512);
main();

sub main    {
    my %v = ();
    $v{'mid'} ="20141121001";
    $v{'ref'} ="raintest0001";
    $v{'cur'} ="SGD";
    $v{'amt'} ="100.00";
    $v{'transtype'} ="SALE";
    my $key = "ABC123456";
    print "\n";
    my $str = '';

    #amt,ref,cur,mid,transtype + SECURITY_KEY

#   my $delim = ",";
#    $str = "$v{'amt'}$delim$v{'ref'}$delim$v{'cur'}$delim$v{'mid'}$delim$v{'transtype'}ABC123456";
#    print $str."\n";
#    my $digest=uc(hmac_sha512_hex($str));
#    checkDigest($digest);

    $str = "$v{'amt'}$v{'ref'}$v{'cur'}$v{'mid'}$v{'transtype'}";
    print $str."\n";
    my $digest=uc(sha512_hex($str, $key));
    checkDigest($digest);

    my $timezone = 'Europe/Rome'; #$Data->{'SystemConfig'}{'Timezone'} || 'UTC';
    my $today = dateatAssoc($timezone);
    my $todayTime = timeatAssoc($timezone, $today);
    print $today . "\n\n";
    print $todayTime . "\n\n";
print "NEED TO ADD 10 mins\n";

}


sub checkDigest {

    my ($digest) = @_;
print "CALC Digest:\n$digest\n";

if ($digest eq "2C3EF639E6EC648DB60062098B3D06D7CC534B469EDF1AD90D8AA93416BFA04F615AC33A4E0BB108EBA724B37B40EC1F951B8F5BC5D1F621452FCBF45BDC8BF1")  {
    print "ALL IS OK\n";
}
else    {
    print "FAIL\n\n\n";
}
}
