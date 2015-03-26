package L10n::CurrencyFormat;

use strict;
use Locale::Currency::Format;

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my (
    $Data, 
    $locale,
  )=@_;
  my %fields=(
    SystemConfig => $Data->{'SystemConfig'} || {},
    Lang => $Data->{'lang'} || undef,
    Locale => $locale || '',
    CurrencyCode => '',
  );

  my $self={%fields};
  bless $self, $class;
  $self->_setupFormats();
  return $self;
}

sub _setupFormats {
	my $self = shift;
    my $currencyCode = '';
    $currencyCode = $self->{'SystemConfig'}{'CurrencyCode'} if $self->{'SystemConfig'};
    $currencyCode ||= 'EUR';
    $self->{'CurrencyCode'} = $currencyCode;
}

sub format {
	my $self = shift;
    #format a currency
    my (
        $value,
        $name
    ) = @_;
    $name ||= 0;
    my $format = $name ? FMT_STANDARD : FMT_HTML;

    return currency_format($self->{'CurrencyCode'},$value, $format);
}

1;
