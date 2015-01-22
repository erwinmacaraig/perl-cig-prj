package FacilityEdit;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleFacilityEdit
);

use strict;
use lib '.', '..', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_DisplayFields;
use ConfigOptions qw(ProcessPermissions);
use FacilityFieldsSetup;
use FieldLabels;
use Data::Dumper;
use PersonUserAccess;
use TTTemplate;

sub handleFacilityEdit {
    my ($action, $Data) = @_;

    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'};
    my $cl = setClient($clientValues);
    my $e_action = param('e_a') || '';
    my $back_screen = param('bscrn') || '';
    my $entityID = param('venueID') || 0;
    if(!doesUserHaveEntityAccess($Data, $entityID,'WRITE')) {
        return ('Invalid User',0);
    }

    $entityID = 0 if $entityID < 0;
    return '' if !$entityID;
    my $entityObj = new EntityObj(db => $Data->{'db'}, ID => $entityID, cache => $Data->{'cache'});
    $entityObj->load();
    my $values = {};
    my $fields = getFieldNames();
    if($entityObj->ID())    {
        for my $f (@{$fields}) {
            $values->{$f} = $entityObj->getValue($f);
        }
    }

    my $fieldset = undef;
    my @sections = ('core', 'contactdetails','roledetails');
    if($action eq 'FE_D')   {
        $values->{'footer-core'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=core&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a></div>];
        $values->{'footer-contactdetails'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=contactdetails&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a></div>];
        $values->{'footer-roledetails'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=roledetails&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a></div>];
    }
    $fieldset = facilityFieldsSetup($Data, $values);
    if(!scalar(@sections))  {
        return ('','');
    }

    my $body = '';

    if($action eq 'FE_U')    {
          my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$e_action}, 'Entity',);
          my $obj = new Flow_DisplayFields(
              Data => $Data,
              Lang => $Data->{'lang'},
              SystemConfig => $Data->{'SystemConfig'},
              Fields => $fieldset->{$e_action},
          );
          my $p = new CGI;
          my %params = $p->Vars();
          my ($userData, $errors) = $obj->gather(\%params, $permissions,'edit');
          my $errorstr = '';
          if($errors)   {
            foreach my $e (@{$errors})  {
                $errorstr .= qq[<p>$e</p>];
            }
          } 
          if($errorstr) {
            $body = qq[ 
              <div class="alert">
                  <div>
                      <span class="fa fa-exclamation"></span>$errorstr
                  </div>
              </div>

            ];
            $action = 'FE_E';
          }
          else  {
            my $status = $entityObj->getValue('strStatus');
            my $dissolved = $userData->{'dissolved'};
            if($dissolved)  {
                $userData->{'strStatus'} = $Defs::ENTITY_STATUS_DE_REGISTERED;
            }
            delete($userData->{'dissolved'});

            $entityObj->setValues($userData);
            $entityObj->write();
            $body = 'updated';
            if($back_screen){
                my %tempClientValues = getClient($Data->{'client'});
                $tempClientValues{currentLevel} = $tempClientValues{authLevel};
                my $tempClient= setClient(\%tempClientValues);

                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$tempClient&venueID=$entityID&$back_screen";
            }
            else {
                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=FE_D&amp;venueID=$entityID";
            }
            
          }
    }
    if($action eq 'FE_E')    {
        my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$e_action}, 'Entity',);
        my $obj = new Flow_DisplayFields(
          Data => $Data,
          Lang => $Data->{'lang'},
          SystemConfig => $Data->{'SystemConfig'},
          Fields => $fieldset->{$e_action},
        );
        my ($output, undef, $headJS, undef) = $obj->build($permissions,'edit',1);
        $body .= qq[
            <form  id = "flowFormID" action = "$Data->{'target'}" method = "POST">
                $output
                $headJS
                <div class="txtright">
                <input type = "hidden" name = "client" value = "].unescape($client).qq["> 
                <input type = "hidden" name = "a" value = "FE_U"> 
                <input type = "hidden" name = "venueID" value = "$entityID"> 
                <input type = "hidden" name = "e_a" value = "$e_action"> 
                <input type = "hidden" name = "bscrn" value = "$back_screen">
                <input type = "submit" value = "].$Data->{'lang'}->txt('Save').qq[" class = "btn-main"> 
                </div>
            </form>
        ];
    }
    if($action eq 'FE_D')    {
        for my $section (@sections) {
            my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$section}, 'Entity',);
            my $obj = new Flow_DisplayFields(
              Data => $Data,
              Lang => $Data->{'lang'},
              SystemConfig => $Data->{'SystemConfig'},
              Fields => $fieldset->{$section},
            );
            my ($output, undef, $headJS, undef) = $obj->build($permissions,'display',1);
            $body .= qq[
                    $output
            ];
        }
        
        my $facilityFields = new EntityFields();
        $facilityFields->setEntityID($entityID);
        $facilityFields->setData($Data);
        my $fields = $facilityFields->getAll('RAW');
        my %templateData = (
            Disciplines => \%Defs::sportType,
            GroundNature => \%Defs::fieldGroundNatureType,
            fieldData   => $fields,
        ); 
        my $fields_summary = runTemplate($Data,\%templateData,'entity/venue_fields_summary.templ');
        if($fields_summary) {
            $body .= qq[
    <div class="read-only">
        <h4>].$Data->{'lang'}->txt('Fields') .qq[</h4>
        <div class="read-only-text">
            $fields_summary
            <div class="fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$client&amp;a=VENUE_Flist&amp;venueID=$entityID">edit</a></div>
        </div>
        
    </div>
            ];
        }

    }

    my $auditLog = '';
    if ($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL) {
        #$auditLog = qq[<a href="$Data->{'target'}?client=$client&amp;a=V_HISTLOG&amp;venueID=$entityID">].$Data->{'lang'}->txt('Audit Trail').qq[</a>];
        $auditLog = qq[<a href="$Data->{'target'}?client=$client&amp;a=V_HISTLOG&amp;venueID=$entityID" class = "btn-main">].$Data->{'lang'}->txt('Audit Trail')."</a><br><br>" ;
    }
    $body = qq[ $auditLog<div class="col-md-12">$body</div>];

    my $pageHeading = $entityObj->name();
    return ($body, $pageHeading);
}

sub getFieldNames {

    my @fields = (qw(
        intEntityID
        intEntityLevel
        intRealmID
        strEntityType
        strStatus
        intRealmApproved
        intCreatedByEntityID
        strFIFAID
        strMAID
        strLocalName
        strLocalShortName
        strLocalFacilityName
        strLatinName
        strLatinShortName
        strLatinFacilityName
        dtFrom
        dtTo
        strISOCountry
        strRegion
        strPostalCode
        strTown
        strCity
        strState
        strAddress
        strAddress2
        strWebURL
        strEmail
        strPhone
        strFax
        strAssocNature
        strMANotes
        intLegalTypeID
        strContactTitle
        strContact
        strContactEmail
        strContactPhone
        strContactCity
        strContactISOCountry
        dtAdded
        tTimeStamp
        intCapacity
        intCoveredSeats
        intUncoveredSeats
        intCoveredStandingPlaces
        intUncoveredStandingPlaces
        intLightCapacity
        strGroundNature
        strDiscipline
        strGender
        strMapRef
        intMapNumber
        dblLat
        dblLong
        strDescription
        intSubRealmID
        intDataAccess
        strPaymentNotificationAddress
        strEntityPaymentBusinessNumber
        strEntityPaymentInfo
        intPaymentRequired
        intIsPaid
        intLocalLanguage
        strLegalID
        strImportEntityCode
        intImportID
        strAcceptSelfRego
        strShortNotes
        intNotifications
        strOrganisationLevel
        intFacilityTypeID
        intEntityFieldCount

    ));
    return \@fields;
}
