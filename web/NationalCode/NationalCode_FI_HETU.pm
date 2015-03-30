package NationalCode_FI_HETU;

use NationalCode_BaseObj;
our @ISA =qw(NationalCode_BaseObj);

use strict;


sub validate {
    my $self = shift;

    my $data = $self->parse_fi($self->{'value'});
    return 0 if !$data;
    return 0 if !$self->fi_checksum($data);

    my $gender = $self->{'params'}{'gender'} || return 0;
    my $dob = $self->{'params'}{'dob'} || return 0;
    my $chkgender = int($data->{'id'}) %2 ? 1 : 2;
    if($gender != $chkgender)       {
            return 0;
    }
    my $century = 0;
    $century = 1800 if $data->{'c'} eq '+';
    $century = 1900 if $data->{'c'} eq '-';
    $century = 2000 if $data->{'c'} eq 'A';

    my $chkdob = ($century + $data->{'yy'}) . '-' . sprintf("%02d",$data->{'mm'}) . '-' . sprintf("%02d",$data->{'dd'});
    if($dob ne $chkdob)     {
            return 0;
    }
    return 1;
}

sub parse_fi    {
    my $self = shift;
    my($code) = @_;

    return undef if length $code != 11;
    my ($dd,$mm,$yy,$c,$zzz,$q) = $code =~/(\d\d)(\d\d)(\d\d)([\-+aA])(\d\d\d)([0-9A-X])/;
    return undef if !$dd;
    return undef if !$mm;
    return undef if !$yy;
    return undef if !$zzz;
    $c = uc($c);
    return undef if !$c;
    $q = uc($q);
    return undef if !$q;

    return {
        dd => int($dd),
        mm => int($mm),
        yy => int($yy),
        id => $zzz,
        c => $c,
        q => $q,
    };
}
sub fi_checksum {
    my $self = shift;
    my($fi_data) = @_;

    my $number =
            $fi_data->{'dd'}
            . sprintf("%02d",$fi_data->{'mm'})
            . sprintf("%02d",$fi_data->{'yy'})
            . sprintf("%03d",$fi_data->{'id'});
    my @check_digit_array = (qw(
            0 1 2 3 4 5 6 7 8 9 A B C D E F H J K L M N P R S T U V W X Y 
    ));
    my $checknum = $number%31;
    return 1 if $fi_data->{'q'} eq $check_digit_array[$checknum];
    return undef;
}
    

1;
