package FlashMessage;
require Exporter;

use strict;
use lib '.', '..', 'Clearances'; #"comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Utils;
use Reg_common;
use JSON;
use CGI qw(param unescape escape redirect);
use TTTemplate;

sub getFlashMessage {
    my ($Data, $cookie_name) = @_;

    my $query = new CGI;
    my $flashMessage = $query->cookie($cookie_name);

    #since a flash message, it should be displayed once
    #reset upon first retrieval
    if($flashMessage){
        setFlashMessage($Data, $cookie_name, '', '-1d');
        my %TemplateData = (
            FlashMessage => decode_json $flashMessage,
        );

        $flashMessage = runTemplate(
            $Data,
            \%TemplateData,
            'flash/message.templ',
        );

        return $flashMessage;
    }

    return '';
}

sub setFlashMessage {
    my ($Data, $cookie_name, $message, $exp) = @_;

    $exp = $exp || '1h';
    $message = ($message) ? encode_json $message : '';

    push @{$Data->{'WriteCookies'}}, [
        $cookie_name,
        $message,
        $exp,
    ];
}

1;
