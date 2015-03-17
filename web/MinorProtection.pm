package MinorProtection;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getMinorProtectionOptions
    getMinorProtectionExplanation
);

use strict;
use lib '.', '..';
use Defs;
use Countries;


sub getMinorProtectionOptions {
    my ($Data, $transfer) = @_;

    my $isocountries  = getISOCountriesHash();
    my $countrycode = $Data->{'SystemConfig'}{'DefaultCountry'} || '';
    my $country = $isocountries->{$countrycode} || '';
    my $lang = $Data->{'lang'};
    my %options = ();
    $options{1} = $lang->txt('Player and Player\'s Parents moved to [_1] for reasons not linked to football',$country);
    $options{2} = $lang->txt('Player lives no further than 50km from the national border and the club with which the player wishes to be registered is also within 50km from the national border.');
    if($transfer)   {
        if(isEuropean($countrycode))    {
            $options{4} = $lang->txt('Transfer takes place within the territory of the European Union (EU) or European Economic Area (EEA) and the player is aged between 16 and 18. In this case the registering Club commits to fulfill FIFA\'s obligations (from FIFA International Transfers Regulations Art. 19b)');
        }
    }
    else    {
        $options{3} = $lang->txt('Player was already living in [_1] prior to this request.',$country);
    }

    return \%options;
}

sub getMinorProtectionExplanation {
    my ($Data, $transfer) = @_;

    my $string = '';
    if($transfer)   {
        $string = 'Transfer of Minor Players (between 10 and 18 years old) are subject to FIFA Regulations (International Transfers involving minors Art 19).';
    }
    else    {
        $string = 'First Registration of Foreign National Minor Players (between 10 and 18 years old) are subject to FIFA regulations.';
    }

    return $Data->{'lang'}->txt($string) || '';
}

1;
