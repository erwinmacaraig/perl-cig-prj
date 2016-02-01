package L10n::CurrencyFormat;

use strict;
use Locale::Currency::Format;
use Data::Dumper;

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
    CustomFormat => '',
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
    my $format = '';
    $format = $self->{'SystemConfig'}{'CurrencyCustomFormat'} if $self->{'SystemConfig'};
    if($format) {
        $self->{'CustomFormat'} = $format;
    }
    return 1;
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

    if($self->{'CustomFormat'}) {
        currency_set($self->{'CurrencyCode'}, $self->{'CustomFormat'}, FMT_COMMON);
        $format = FMT_COMMON;
    }
    return currency_format($self->{'CurrencyCode'},$value, $format);
}

1;
