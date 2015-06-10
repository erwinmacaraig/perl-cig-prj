package NationalCode;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getNationalCodeValidator);
@EXPORT_OK = qw(getNationalCodeValidator);

use strict;
use NationalCode_FI_HETU;


sub getNationalCodeValidator {
    my ($SystemConfig, $value, $params)=@_;

    my $type = $SystemConfig->{'NatCodeType'} || '';
    if($type eq 'FI_HETU')  {
        return new NationalCode_FI_HETU(
            SystemConfig => $SystemConfig,
            value => $value,
            params => $params,
        );
    }
    return undef;
}

1;
