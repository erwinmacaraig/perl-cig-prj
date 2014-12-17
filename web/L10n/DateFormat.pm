package L10n::DateFormat;

use Exporter;
@EXPORT=qw(new);

use lib "../web";
use strict;
use Utils;

# Allowed Specifiers

# Specifier   Replaced by Example
# %a  Abbreviated weekday name *  Thu
# %A  Full weekday name * Thursday
# %b  Abbreviated month name *    Aug
# %B  Full month name *   August
# %C  Year divided by 100 and truncated to integer (00-99)    20
# %d  Day of the month, zero-padded (01-31)   23
# %D  Short MM/DD/YY date, equivalent to %m/%d/%y 08/23/01
# %e  Day of the month, space-padded ( 1-31)  23
# %F  Short YYYY-MM-DD date, equivalent to %Y-%m-%d   2001-08-23
# %g  Week-based year, last two digits (00-99)    01
# %g  Week-based year 2001
# %h  Abbreviated month name * (same as %b)   Aug
# %H  Hour in 24h format (00-23)  14
# %I  Hour in 12h format (01-12)  02
# %j  Day of the year (001-366)   235
# %m  Month as a decimal number (01-12)   08
# %M  Minute (00-59)  55
# %n  New-line character ('\n')   
# %p  AM or PM designation    PM
# %r  12-hour clock time *    02:55:02 pm
# %R  24-hour HH:MM time, equivalent to %H:%M 14:55
# %S  Second (00-61)  02
# %t  Horizontal-tab character ('\t') 
# %T  ISO 8601 time format (HH:MM:SS), equivalent to %H:%M:%S 14:55
# %u  ISO 8601 weekday as number with Monday as 1 (1-7)   4
# %U  Week number with the first Sunday as the first day of week one (00-53)  33
# %V  ISO 8601 week number (00-53)    34
# %w  Weekday as a decimal number with Sunday as 0 (0-6)  4
# %W  Week number with the first Monday as the first day of week one (00-53)  34
# %x  Date representation *   08/23/01
# %X  Time representation *   14:55:02
# %y  Year, last two digits (00-99)   01
# %Y  Year    2001
# %z  ISO 8601 offset from UTC in timezone (1 minute=1, 1 hour=100)
# If timezone cannot be termined, no characters   +100
# %Z  Timezone name or abbreviation *
# If timezone cannot be termined, no characters   CDT
# %%  A % sign    %

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my (
    $Data, 
    $locale,
  )=@_;
  my %fields=(
    formats =>  {
        DATE => {
            SHORT => '%Y-%m-%d',
            MEDIUM => '%d-%b-%Y',
            LONG => '%B %e, %Y',
            FULL => '%A, %B %e, %Y',
            NONE => '',
        },
        TIME => {
            SHORT => '%H:%M',
            MEDIUM => '%I:%M %p',
            LONG  => '%H:%M:%S',
            FULL => '%H:%M:%S %z',
            NONE => '',
        },
    },
    SystemConfig => $Data->{'SystemConfig'} || {},
    Lang => $Data->{'lang'} || undef,
    Locale => $locale || '',
  );

  my $self={%fields};
  bless $self, $class;
  ##bless selfhash to GenCode;
  ##return the blessed hash
  $self->_setupFormats();
  return $self;
}

sub _setupFormats {
	my $self = shift;
    return 0 if !$self->{'SystemConfig'};
    my $locale = $self->{'Locale'} || '';
    for my $formatname (qw(
        SHORT 
        MEDIUM
        LONG
        FULL
    ))  {
        for my $formattype (qw(DATE TIME))  {
            my $f = '';
            if($self->{'SystemConfig'}{$formattype . 'FORMAT_' . $formatname})    {
                $f = $self->{'SystemConfig'}{$formattype .'FORMAT_' . $formatname} || '';
            }
            if($self->{'SystemConfig'}{$formattype . 'FORMAT_' .$locale . '_' . $formatname})    {
                $f = $self->{'SystemConfig'}{$formattype . 'FORMAT_' . $locale . '_' . $formatname} || '';
            }
            if($f)  {
                $self->{'formats'}{$formattype}{$formatname} = $f || '';
            }
        }
    }
}

sub TZformat {
	my $self = shift;

    my (
        $datetimeIN,
        $dateformat,
        $timeformat,
    ) = @_;
    return $self->format(
        $datetimeIN,
        $dateformat,
        $timeformat,
        1
    );
}

sub format {
	my $self = shift;
    #format a date
    #datetime IN must one of the following formats :
        # YYY-MM-DD HH:MM:SS
        # YYY-MM-DD
        # HH:MM:SS
        # HH:MM

    my (
        $datetimeIN,
        $dateformat,
        $timeformat,
        $TZConversion,
    ) = @_;
    return '' if !$datetimeIN;
    return '' if $datetimeIN eq '0000-00-00 00:00:00';
    return '' if $datetimeIN eq '0000-00-00';
    $TZConversion ||= 0;
    my $datetime = $self->tzConversion($datetimeIN, $TZConversion);
    #If present in the string - these patterns need to be translated

    $dateformat ||= '';
    $timeformat ||= '';
    if(exists($self->{'formats'}{'DATE'}{$dateformat}))   {
        $dateformat = $self->{'formats'}{'DATE'}{$dateformat};
    }
    if(exists($self->{'formats'}{'TIME'}{$timeformat}))   {
        $timeformat = $self->{'formats'}{'TIME'}{$timeformat};
    }
    return '' if !$datetime;
    my $dtFormat = $self->_runFormat($datetime, $dateformat);
    my $tmFormat = $self->_runFormat($datetime, $timeformat);

    my $output = join(' ',$dtFormat, $tmFormat) || '';
    return $output;
}

sub tzConversion    {
	my $self = shift;
    my (
        $datetimeIN,
        $TZConversion,
    ) = @_;

    return '' if !$datetimeIN;
    my $timezone = $self->{'SystemConfig'}{'Timezone'} || 'UTC';
    $TZConversion = 0 if $timezone eq 'UTC';
    my ($y,$mon, $d, $h, $min, $s) = (0,0,0,0,0,0);
    if($datetimeIN =~ /^\d\d\d\d\-\d\d\-\d\d [012]\d:[0-5]\d:[0-5]\d$/) {
        ($y,$mon, $d, $h, $min, $s) = $datetimeIN =~ /(\d\d\d\d)-([01]\d)\-([0123]\d) ([012]\d):([0-5]\d):([0-5]\d)/;
    }
    elsif($datetimeIN =~ /^\d\d\d\d\-\d\d\-\d\d$/) {
        ($y,$mon, $d) = $datetimeIN =~ /(\d\d\d\d)-([01]\d)\-([0123]\d)/;
    }
    elsif($datetimeIN =~ /^[012]\d:[0-5]\d:[0-5]\d$/) {
        ($h, $min, $s) = $datetimeIN =~ /([012]\d):([0-5]\d):([0-5]\d)/;
    }
    elsif($datetimeIN =~ /^[012]\d:[0-5]\d$/) {
        ($h, $min) = $datetimeIN =~ /([012]\d):([0-5]\d)/;
    }
    if(!$y and !$h)  {
        return '';
    }
    $y ||= 1970;
    $mon ||= 1;
    $d ||= 1;
    my $dt = DateTime->new( year   => $y, month=>$mon, day=>$d, hour=>$h, minute=>$min, second => $s, time_zone => 'UTC');
    if($TZConversion)   {
        $dt->set_time_zone($timezone);
    }
    my $convertedDate = $dt->ymd . ' ' . $dt->hms;
    return $convertedDate;
}

sub _runFormat   {
	my $self = shift;
    my (
        $value,
        $format,
    ) = @_;

    return '' if !$value;
    return '' if !$format;
    my $problemPattern = 0;
    if($format =~/\%[aAbBhp]/)  { #outputs that need translating
        #$problemPattern = 1;
    }
    my ($y,$mon, $d, $h, $min, $s) = $value =~ /(\d\d\d\d)-([01]\d)\-([0123]\d) ([012]\d):([0-5]\d):([0-5]\d)/;
    my $output = '';
    if(!$problemPattern)    {
        $output = POSIX::strftime (
            $format || '',
            $s || 0,
            $min || 0,
            $h || 0,
            $d,
            ($mon-1),
            ($y-1900)
        );
    }
    else    {

    }

    return $output;
}

1;
