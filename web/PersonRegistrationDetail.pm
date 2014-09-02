package PersonRegistrationDetail;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    personRegistrationDetail
);

use strict;
use WorkFlow;
use Defs;

#use Log;
use TTTemplate;
use Data::Dumper;
use PersonUtils;
use PersonRegistration;
use Reg_common;
use HTMLForm;
use FormHelpers;

sub personRegistrationDetail   {

    my ($Data, $entityID, $personRegistrationID) = @_;

    my $RegistrationDetail = PersonRegistration::getRegistrationDetail($Data, $personRegistrationID);
    $RegistrationDetail = pop $RegistrationDetail;
    my $option = 'edit';
    my $intRelamID = $Data->{'Relam'} ? $Data->{'Realm'} : 0;
    my %statusoptions = ();

    for my $key (keys %Defs::personRegoStatus) {
        next if !$key;
        if ($key eq $Defs::PERSON_STATUS_PENDING or $key eq $Defs::PERSON_STATUS_ACTIVE) {
            $statusoptions{$key} = $Defs::personRegoStatus{$key} || '';
        }
    }

    my %FieldDefinitions = (
        fields => {
            strStatus => {
                label => 'Status',
                value => uc($RegistrationDetail->{'Status'}),
                type => 'lookup',
                options => \%statusoptions,
                #to be enabled once the query is modified to allow different entities to view the list of PR
                #readonly => $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL ? 0 : 1,
                readonly => 0,
            },
            strAgeLevel => {
                label => 'Age Level',
                value => $RegistrationDetail->{'strAgeLevel'},
                type => 'text',
                readonly => 1,
            },
            strSport => {
                label => 'Sport',
                value => $RegistrationDetail->{'Sport'},
                type => 'text',
                readonly => 1,
            },
            strGender => {
                label => 'Gender',
                value => %Defs::genderInfo->{$RegistrationDetail->{'intGender'}},
                type => 'text',
                readonly => 1,
            },
            strRegistrationNature => {
                label => 'Registraion Type',
                value => $RegistrationDetail->{'RegistrationNature'},
                type => 'text',
                readonly => 1,
            },
            strPersonType => {
                label => 'Type',
                value => $RegistrationDetail->{'PersonType'},
                type => 'text',
                readonly => 1,
            },
            strPersonLevel => {
                label => 'Level',
                value => $RegistrationDetail->{'PersonLevel'},
                type => 'text',
                readonly => 1,
            },
        },
        order => [qw(
            strStatus
            strAgeLevel
            strSport
            strGender
            strRegistrationNature
            strPersonType
            strPersonLevel
        )],
        options => {
            labelsuffix => ':',
            hideblank => 1,
            target => $Data->{'target'},
            formname => 'n_form',
            submitlabel => $Data->{'lang'}->txt('Update'),
            introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
            NoHTML => 1,
            updateSQL => qq[],
            addSQL => qq[],

            afteraddFunction => ,
            afteraddParams => [$option, $Data, $Data->{'db'}],
            afterupdateFunction => ,
            afterupdateParams => [$option, $Data, $Data->{'db'}],
            LocaleMakeText => $Data->{'lang'},
        },
        carryfields => {},
    );

    my $resultHTML = '';
    ($resultHTML, undef) = handleHTMLForm(\%FieldDefinitions, undef, $option, '', $Data->{'db'});

    return $resultHTML;

    #print STDERR Dumper $RegistrationDetail;

    ## Needs to use PersonRegistration::getRegistrationDetail
    ## Needs to get list (SQL fine) of tasks and the Entity who is tasked with each row.... see SQL in PendingRegistrations.pm for SQL example
    ## Needs to be in a template/
    ## For top half, use HTMLForm so Status can be changed if $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL or $Data->{'SystemConfig'}{'ChangePRStatus_Level'} >= $Data->{'clientValues'}{'authLevel'} -- so basically we can set a tblSystemConfig value to what level can change per Realm.  "ChangePRStatus_Level" would be the name of the key-value pair in tblSystemConfig
    #return "NEED PAGE FOR A REGISTRATION RECORD - This will show at top the full detail of the Registration, then a table at bottom showing the list of tasks";
    ## Used for both Registration History from Person level and Pending Registrations from an Entity.
}
1;
