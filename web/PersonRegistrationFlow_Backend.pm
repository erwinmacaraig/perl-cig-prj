package PersonRegistrationFlow_Backend;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleRegistrationFlowBackend
);

use strict;
use lib "../..","..";
use PersonRegistration;
use RegistrationItem;
use PersonRegisterWhat;
use Reg_common;
use CGI qw(:cgi);

sub handleRegistrationFlowBackend   {
    my (
        $action,
        $Data
         ) = @_;

    my $body = '';
    my $title = '';
    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {};
    if ( $action eq 'PREGF_TU' ) {
        #add rego record with types etc.
        $rego_ref = {
            personType => param('pt') || '',
            personLevel => param('pl') || '',
            sport => param('sp') || '',
            ageLevel => param('ag') || '',
            registrationNature => param('nat') || '',
        };
        $action = 'PREGF_P';
    }
    if ( $action eq 'PREGF_PU' ) {
        #Update product records
        $action = 'PREGF_D';
    }
    if ( $action eq 'PREGF_DU' ) {
        #Update document records
        $action = 'PREGF_C';
    }



    if ( $action eq 'PREGF_T' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_TU&amp;";
        my $dob = '';
        my $gender = '';
        $body = displayPersonRegisterWhat(
            $Data,
            getID($clientValues, $Defs::LEVEL_PERSON) || 0,
            getLastEntityID($clientValues) || 0,
            $dob,
            $gender,        
            getLastEntityLevel($clientValues),
            $url,
        );
    }
    elsif ( $action eq 'PREGF_P' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;";
        my $products = getRegistrationItems(
            $Data,
            'REGO',
            'PRODUCT',
            getLastEntityLevel($clientValues) || 0,
            $rego_ref->{'registrationNature'},
            getLastEntityID($clientValues) || 0,
            0,
            0,
            $rego_ref,
        );
use Data::Dumper;
print STDERR Dumper($products);
        $body = qq[
            display product information

            <a href = "$url">Continue</a>
        ];
    }
    elsif ( $action eq 'PREGF_D' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;";
        my $documents = getRegistrationItems(
            $Data,
            'REGO',
            'DOCUMENT',
            getLastEntityLevel($clientValues) || 0,
            $rego_ref->{'registrationNature'},
            getLastEntityID($clientValues) || 0,
            0,
            0,
            $rego_ref,
        );
use Data::Dumper;
print STDERR Dumper($documents);
        $body = qq[
            display document upload information

            <a href = "$url">Continue</a>
        ];
    }    
    elsif ( $action eq 'PREGF_C' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=P_HOME;";
        $body = qq[
            Registration is complete

            <a href = "$url">Continue</a>
        ];
    }    
    else {
    }

    return ( $body, $title );
}


