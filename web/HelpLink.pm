package HelpLink;

require Exporter;
@ISA = qw(Exporter);
@EXPORT= qw(retrieveHelpLink);
@EXPORT_OK = qw(retrieveHelpLink);

use lib "..",".";
use Defs;
use PersonLanguages;
use Reg_common;
use InstanceOf;

sub retrieveHelpLink {
    my ($Data) = @_;

    my $sysConfigSuffix = '_helplink';
    my $defaultHelpLink = $Data->{'SystemConfig'}{'en_US_helplink'} || '';

    my $currentLanguage = $Data->{'lang'}->generateLocale($Data->{'SystemConfig'});
    my $currentLevel = $Data->{'clientValues'}{'authLevel'};

    if($currentLevel == 3) {
	    my $localLanguage;
	    my $entityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'currentLevel'});
        my $clubObj = getInstanceOf($Data, 'club', $entityID);

        return $Data->{'SystemConfig'}{$currentLanguage . $sysConfigSuffix} || $defaultHelpLink
            if (!$clubObj->getValue('intLocalLanguage')); 


        my $languageOptions = getPersonLanguages($Data,1,1);
        for my $l (@{$languageOptions}) {
            $localLanguage = $l->{'strLocale'} if ($l->{'intLanguageID'} == $clubObj->getValue('intLocalLanguage'));
            next if($localLanguage);
        }

        return $Data->{'SystemConfig'}{$localLanguage . $sysConfigSuffix} || $defaultHelpLink;
    }
    else {
        return $Data->{'SystemConfig'}{$currentLanguage . $sysConfigSuffix} || $defaultHelpLink; 
    }
}

1;
