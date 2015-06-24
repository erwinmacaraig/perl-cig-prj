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
use FlashMessage;

sub handleFacilityEdit {
    my ($action, $Data) = @_;

    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'};
    my $cl = setClient($clientValues);
    my $e_action = param('e_a') || '';
    my $back_screen = param('bscrn') || '';
    my $entityID = param('venueID') || 0;
    my $venueStatus;	
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
        my $q = qq[ SELECT strStatus FROM tblEntity WHERE intEntityID = ? AND intEntityLevel = $Defs::LEVEL_VENUE AND intRealmID = ? ];
        my $sth = $Data->{'db'}->prepare($q);
        $sth->execute($entityID, $Data->{'Realm'});
        my $dref = $sth->fetchrow_hashref();
        $venueStatus = $dref->{'strStatus'};
        my $allowEditCoreLink;
        my $allowEditContactDetailsLink;
        my $allowEditRoleDetailsLink;
        if($venueStatus eq 'ACTIVE'){
            $allowEditCoreLink  =  qq [<a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=core&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a>];
        
            $allowEditContactDetailsLink = qq[<a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=contactdetails&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a>];
        
            $allowEditRoleDetailsLink = qq[<a href = "$Data->{'target'}?client=$Data->{'client'}&a=FE_E&e_a=roledetails&amp;venueID=$entityID">].$Data->{'lang'}->txt('edit').qq[</a>];
        }
        $values->{'footer-core'} = qq[<div class = "fieldSectionGroupFooter"> $allowEditCoreLink </div>];
        $values->{'footer-contactdetails'} = qq[<div class = "fieldSectionGroupFooter">$allowEditContactDetailsLink</div>];
        $values->{'footer-roledetails'} = qq[<div class = "fieldSectionGroupFooter">$allowEditRoleDetailsLink</div>];
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
            my $controls = qq[<a href = "$Data->{'target'}?client=$client&amp;a=VENUE_Flist&amp;venueID=$entityID">edit</a> |
                            <a href = "$Data->{'target'}?client=$client&amp;a=VENUE_FPA&amp;venueID=$entityID">add</a> |
                            <a href = "$Data->{'target'}?client=$client&amp;a=VENUE_FPD&amp;venueID=$entityID">delete</a>] if($venueStatus eq 'ACTIVE');
            $body .= qq[
                <div class="fieldSectiopGroupWrapper fieldSectionGroupWrapper-DisplayOnly">
                    <h3 class="panel-header sectionheader">].$Data->{'lang'}->txt('Fields') .qq[</h3>
                    <div class="panel-body fieldSectionGroup">
                        $fields_summary 
                        <div class="fieldSectionGroupFooter">
                            $controls
                        </div>                        
                    </div>                    
                </div>
            ];

        }
		
		# Process documents here
		
		my $query = qq[SELECT 
						T.intDocumentTypeID,
						T.strDocumentName,
						T.strLockAtLevel, 
						D.strApprovalStatus, 
						D.intUploadFileID, 
						U.dtUploaded
					FROM tblDocuments as D INNER JOIN tblDocumentType as T ON
					D.intDocumentTypeID = T.intDocumentTypeID
					INNER JOIN tblUploadedFiles as U ON D.intUploadFileID = U.intFileID
					WHERE D.intEntityID = ? AND T.intRealmID = ?
				   ];
		
		#$templateData{'venueDocuments'} = \@venueDocs;
		# 	
			
        my $docs_summary = runTemplate($Data,\%templateData,'entity/venue_docs_summary.templ');
        if($Data->{'SystemConfig'}{'hasVenueDocuments'}){
		    $body .= qq[
		            <div class="fieldSectiopGroupWrapper fieldSectionGroupWrapper-DisplayOnly">
		                <h3 class="panel-header sectionheader">].$Data->{'lang'}->txt('Documents') .qq[</h3>
		                <div class="panel-body fieldSectionGroup"> $docs_summary <tbody>];
		    #<a href="#" class="btn-inside-docs-panel" onclick="docViewer($fileID,'client=$client&amp;a=view');return false;">]. $Data->{'lang'}->txt('View') . q[</a>               
			my $sth = $Data->{'db'}->prepare($query);
			$sth->execute($entityID, $Data->{'Realm'});
			while(my $dref = $sth->fetchrow_hashref()){
				my $parameters = qq[&amp;client=$client&doctype=$dref->{'intDocumentTypeID'}&pID=$entityID&nff=1&entitydocs=1];
				my $documentName = $dref->{'strDocumentName'};
				$documentName =~ s/'/\\\'/g;
				$body .= qq[
					<tr>
		   				 <td>$dref->{'strDocumentName'}</td>
						 <td>$dref->{'strApprovalStatus'}</td>
						 <td>$dref->{'dtUploaded'}</td>
						 <td><a href="#" class="btn-main btn-view-replace" onclick="docViewer($dref->{'intUploadFileID'},'client=$client&amp;a=view');return false;">] . $Data->{'lang'}->txt('View'). qq[</a></td>
		   				 <td><a href="#" class="btn-main btn-view-replace" onclick="replaceFile($dref->{'intUploadFileID'},'$parameters','$documentName','');return false;">] . $Data->{'lang'}->txt('Replace') . qq[</a></td>
					</tr>
				];
			}

		    $body .= qq[</tbody> </table>
		                </div>
		                
		            </div>
		        ];
		}
		#<div class="fieldSectionGroupFooter"><a href = "$Data->{'target'}?client=$client&amp;a=VENUE_Flist&amp;venueID=$entityID">edit</a></div>

    }

    my $auditLog = '';
    if ($Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL) {
        #$auditLog = qq[<a href="$Data->{'target'}?client=$client&amp;a=V_HISTLOG&amp;venueID=$entityID">].$Data->{'lang'}->txt('Audit Trail').qq[</a>];
        $auditLog =  $back_screen ? '' : qq[<a href="$Data->{'target'}?client=$client&amp;a=V_HISTLOG&amp;venueID=$entityID" class = "btn-main">].$Data->{'lang'}->txt('Audit Trail'). "</a>" ;


		#$auditLog = qq[<a href="$Data->{'target'}?client=$client&amp;a=V_HISTLOG&amp;venueID=$entityID" class = "btn-main">].$Data->{'lang'}->txt('Audit Trail')."</a>" ;
    }

    my %flashMessage;
    my $rflashMessage = FlashMessage::getFlashMessage($Data, 'FAC_FM');

    $body = qq[<div class="col-md-12">
                $rflashMessage
                $auditLog
                $body
            </div>];

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
        intAcceptSelfRego
        strShortNotes
        intNotifications
        strOrganisationLevel
        intFacilityTypeID
        intEntityFieldCount

    ));
    return \@fields;
}
