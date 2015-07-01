package EntityEdit;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleEntityEdit
);

use strict;
use lib '.', '..', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_DisplayFields;
use ConfigOptions qw(ProcessPermissions);
use EntityFieldsSetup;
use FieldLabels;
use Data::Dumper;
use AuditLog;
use FieldMessages;
use AssocTime;

sub handleEntityEdit {
    my ($action, $Data) = @_;

    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'};
    my $cl = setClient($clientValues);
    my $e_action = param('e_a') || '';
    my $back_screen = param('bscrn') || '';
    my $entityID = getID($clientValues);
    $entityID = 0 if $entityID < 0;
    return '' if !$entityID;
    my @sections = ();

    my $entityObj = new EntityObj(db => $Data->{'db'}, ID => $entityID, cache => $Data->{'cache'});
    $entityObj->load();
    my $values = {};
    my $fields = getFieldNames();
    if($entityObj->ID())    {
        for my $f (@{$fields}) {
            $values->{$f} = $entityObj->getValue($f);
        }
    }

    my $permissionType = 'Entity';
    my $fieldset = undef;
    if($currentLevel == $Defs::LEVEL_CLUB)  {
        $permissionType = 'Club';
        @sections = ('core', 'contactdetails','roledetails');
        if($action eq 'EE_D')   {
            $values->{'footer-core'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=EE_E&e_a=core">].$Data->{'lang'}->txt('edit').qq[</a></div>];
            $values->{'footer-contactdetails'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=EE_E&e_a=contactdetails">].$Data->{'lang'}->txt('edit').qq[</a></div>];
            $values->{'footer-roledetails'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=EE_E&e_a=roledetails">].$Data->{'lang'}->txt('edit').qq[</a></div>];
        }
        $fieldset = clubFieldsSetup($Data, $values);
    }
    elsif($currentLevel == $Defs::LEVEL_REGION
     or $currentLevel == $Defs::LEVEL_NATIONAL)  {
        @sections = ('core', 'contactdetails');
        if($action eq 'EE_D')   {
            $values->{'footer-core'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=EE_E&e_a=core">].$Data->{'lang'}->txt('edit').qq[</a></div>];
            $values->{'footer-contactdetails'} = qq[<div class = "fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$Data->{'client'}&a=EE_E&e_a=contactdetails">].$Data->{'lang'}->txt('edit').qq[</a></div>];
        }
        $fieldset = entityFieldsSetup($Data, $values);
    }
    if(!scalar(@sections))  {
        return ('','');
    }

    my $body = '';

    if($action eq 'EE_U')    {
          my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$e_action}, $permissionType,);
          my $fieldMessages = getFieldMessages($Data, lc($permissionType), $Data->{'lang'}->getLocale());

          my $obj = new Flow_DisplayFields(
              Data => $Data,
              Lang => $Data->{'lang'},
              SystemConfig => $Data->{'SystemConfig'},
              Fields => $fieldset->{$e_action},
              FieldMessages => $fieldMessages,
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
            $action = 'EE_E';
          }
          else  {
            my $status = $entityObj->getValue('strStatus');
            my $dissolved = $userData->{'dissolved'};
            if($dissolved)  {
                $userData->{'strStatus'} = $Defs::ENTITY_STATUS_DE_REGISTERED;
            }

            delete($userData->{'dissolved'});

            #comparing date - set strStatus to DE-REGISTERED if dtTo <= today
            my $timezone = $Data->{'SystemConfig'}{'Timezone'} || 'UTC';
            my $today = dateatAssoc($timezone);

            my ($y, $m, $d) = $userData->{'dtTo'} =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
            my ($yt, $mt, $dt) = $today =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;

            if(Date::Calc::check_date($y, $m, $d) and Date::Calc::check_date($yt, $mt, $dt)) {
                my $deltaDays = Date::Calc::Delta_Days($yt, $mt, $dt, $y, $m, $d);
                if($deltaDays <= 0) {
                    $userData->{'strStatus'} = $Defs::ENTITY_STATUS_DE_REGISTERED;
                }
            }

            $entityObj->setValues($userData);
            $entityObj->write();
            $body = 'updated';
            auditLog(
                $entityID,
                $Data,
                'Update',
                'Entity',
            );
            if($back_screen){
                my %tempClientValues = getClient($Data->{'client'});
                $tempClientValues{currentLevel} = $tempClientValues{authLevel};
                my $tempClient= setClient(\%tempClientValues);

                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$tempClient&$back_screen";
            }
            else {
                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=EE_D";
            }
            
          }
    }
    if($action eq 'EE_E')    {
        my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$e_action}, $permissionType,);
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
                <input type = "hidden" name = "a" value = "EE_U"> 
                <input type = "hidden" name = "e_a" value = "$e_action"> 
                <input type = "hidden" name = "bscrn" value = "$back_screen"> 
                <input type = "submit" value = "].$Data->{'lang'}->txt('Save').qq[" class = "btn-main"> 
                </div>
            </form>
        ];
    }
    if($action eq 'EE_D')    {
        for my $section (@sections) {
            my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$section}, $permissionType,);
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
    }

    $body = qq[ <div class="col-md-12">$body</div>];

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
        strShortNotes
        intNotifications
        strOrganisationLevel
        intFacilityTypeID
        strBankAccountNumber
        intAcceptSelfRego
    ));
    return \@fields;
}
