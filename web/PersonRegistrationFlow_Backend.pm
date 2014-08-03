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
use RegoProducts;
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
    my $regoID = param('rID') || 0;

    if($regoID) {
        my $valid = validateRegoID($Data, $regoID);
        $regoID = 0 if !$valid;
    }
    if ( $action eq 'PREGF_TU' ) {
        #add rego record with types etc.
        $regoID = add_rego_record($Data);
warn("RID $regoID");
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
            $Data->{'clientValues'}{'authLevel'},
            $url,
        );
#getLastEntityLevel($clientValues) -- OriginLevel
    }
    elsif ( $action eq 'PREGF_P' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_PU&amp;rID=$regoID";
        my $products = getRegistrationItems(
            $Data,
            'REGO',
            'PRODUCT',
            $Data->{'clientValues'}{'authLevel'},
            $rego_ref->{'registrationNature'},
            getLastEntityID($clientValues) || 0,
            0,
            0,
            $rego_ref,
        );
use Data::Dumper;
print STDERR Dumper($products);
        $body .= getRegoProducts($Data, $products);
        $body .= qq[
            display product information

            <a href = "$url">Continue</a>
        ];
        
    }
    elsif ( $action eq 'PREGF_D' ) {
        my $url = $Data->{'target'}."?client=$client&amp;a=PREGF_DU&amp;rID=$regoID";
        my $documents = getRegistrationItems(
            $Data,
            'REGO',
            'DOCUMENT',
            $Data->{'clientValues'}{'authLevel'},
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
        submitPersonRegistration(
            $Data, 
            getID($Data->{'clientValues'}),
            $regoID,
        );
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

sub validateRegoID {
    my ($Data, $regoID) = @_;

    my %Reg = (
        personRegistrationID => $regoID,
        entityID => getLastEntityID($Data->{'clientValues'}) || 0,
    );
    my ($count, $regs) = getRegistrationData(
        $Data, 
        getID($Data->{'clientValues'}),
        \%Reg
    );
    return $count || 0;

}


sub add_rego_record{
    my ($Data) =@_;

    my $clientValues = $Data->{'clientValues'};
    my $rego_ref = {
        status => 'INPROGRESS',
        personType => param('pt') || '',
        personLevel => param('pl') || '',
        sport => param('sp') || '',
        ageLevel => param('ag') || '',
        registrationNature => param('nat') || '',
        originLevel => $Data->{'clientValues'}{'authLevel'} || 0, #getLastEntityLevel($clientValues) || 0,
        originID => getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'}), #getLastEntityID($clientValues) || 0,
        entityID => getLastEntityID($clientValues) || 0,
        personID => getID($clientValues) || 0,
        current => 1,
    };

    my ($regID,$rc) = addRegistration($Data,$rego_ref);
    return $regID || 0;
}
