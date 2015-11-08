#!/usr/bin/perl
use warnings;
use strict;

use Digest::SHA qw(hmac_sha512_hex sha512_hex sha512);
main();

sub main    {
    my %v = ();
    $v{'mid'} ="20141121001";
    $v{'ref'} ="11321"; #
    $v{'cur'} ="SGD";
    $v{'amt'} ="107.00";
    $v{'transtype'} ="sale";
    $v{'status'} = 'YES';
    $v{'error'} = '';
    my $key = "ABC123456";
    print "\n";
    my $str = '';

    #amt,ref,cur,mid,transtype + SECURITY_KEY
    

#   my $delim = ",";
#    $str = "$v{'amt'}$delim$v{'ref'}$delim$v{'cur'}$delim$v{'mid'}$delim$v{'transtype'}ABC123456";
#    print $str."\n";
#    my $digest=uc(hmac_sha512_hex($str));
#    checkDigest($digest);

    $str = "$v{'amt'}$v{'ref'}$v{'cur'}$v{'mid'}$v{'transtype'}$v{'status'}$v{'error'}";
    print $str."\n";
    my $digest=uc(sha512_hex($str, $key));
    checkDigest($digest);


}


sub checkDigest {

    my ($digest) = @_;
print "CALC Digest:\n$digest\n";

if ($digest eq "86C63F0B086C94FB071674890AA4697FF20AAA64ABAC829C67079E72AA64DF12B6DF8BFAE12C5D3A02C3EA09E69568CCD9DD6A96C0B6D91BACDB15B18C3533A5")  {
    print "ALL IS OK\n";
}
else    {
    print "FAIL\n\n\n";
}
}
