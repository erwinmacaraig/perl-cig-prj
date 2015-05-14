package LanguageChooser;

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(genLanguageChooser);
@EXPORT_OK = qw(genLanguageChooser);
use lib "..",".";
use LangBase;
use Defs;
use TTTemplate;
use PersonLanguages;


sub genLanguageChooser  {
    my ($Data, $seq) = @_;

    my $currentLanguage = $Data->{'lang'}->generateLocale($Data->{'SystemConfig'});

    my $languageOptions = getPersonLanguages($Data,1,1);
    return '' if !$languageOptions;
    return '' if scalar(@{$languageOptions}) <= 1;

    my $body = runTemplate(
        $Data,
        {
            currentLanguage => $currentLanguage,
            Languages => $languageOptions,
            cookieName => $Defs::COOKIE_LANG,
            seq => $seq || '',
        },
        'page_wrapper/language_chooser.templ',
    );

    return $body || '';
}

1;
