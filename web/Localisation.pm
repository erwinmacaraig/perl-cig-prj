package Localisation;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  initLocalisation
);

use strict;
use lib '.', '..', '../..';

use Defs;
use Lang;
use CGI;
use L10n::DateFormat;
use L10n::CurrencyFormat;

# This function modifies the hash reference passed in 
sub initLocalisation   {
    my ($Data) = @_;

    return 0 if !$Data->{'SystemConfig'};
    if(!$Data->{'lang'})    {
        $Data->{'lang'} = Lang->get_handle('', $Data->{'SystemConfig'}) || die "Can't get a language handle!";
    }
    my $locale = $Data->{'lang'}->getLocale($Data->{'SystemConfig'});
    my $dateFormat = new L10n::DateFormat($Data);
    $Data->{'l10n'}{'date'} = $dateFormat if $dateFormat;
    my $currencyFormat = new L10n::CurrencyFormat($Data);
    $Data->{'l10n'}{'currency'} = $currencyFormat if $currencyFormat;

    return 1;
}


1;
