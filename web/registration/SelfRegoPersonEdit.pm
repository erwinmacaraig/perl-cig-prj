package SelfRegoPersonEdit;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handleSelfRegoPersonEdit
);

use strict;
use lib '.', '..', '../..', "../../..", "../user", "user";

use InstanceOf;
use Reg_common;
use CGI qw(param);
use Defs;
use Flow_DisplayFields;
use ConfigOptions qw(ProcessPermissions);
use PersonFieldsSetup;
use FieldLabels;
use Data::Dumper;
use AuditLog;
use FieldMessages;

sub handleSelfRegoPersonEdit {
    my ($Data, $action) = @_;
    my $body = '';
    my $e_action = param('e_a') || '';
    my $back_screen = param('bscrn') || '';
    my $personID = param('pID') || '' ;
    my $dtype = param('dtype') || '';
    return '' if !$personID;
    
      
    #my $sth = $Data->{'db'}->prepare($st);
    
    my @fields = keys(%{getFieldLabels($Data, $Defs::LEVEL_PERSON,1)});
    
    my $personObj = new PersonObj(db => $Data->{'db'}, ID => $personID, cache => $Data->{'cache'});
    $personObj->load(); 
    
     
    my $values = {};
    $values->{'defaultType'} = $dtype;
    $values->{'itc'} =  0;
    $values->{'selfRego'} = 1;
    $values->{'minorRego'} =  0;
    if($Data->{'User'}) {
        $values->{'strP1FName'} = $Data->{'User'}->name();
        $values->{'strP1SName'} = $Data->{'User'}->familyname();
    }
    
    if($personObj->ID())    {
           for my $f (@fields) {
            $values->{$f} = $personObj->getValue($f);            
        }
        
    }
    
    $values->{'defaultType'} = $dtype;
    my $fieldset = personFieldsSetup($Data, $values);

    my $fieldsetType = '';
    if($e_action eq 'core') {
        $fieldsetType = 'core';
    }
    elsif($e_action eq 'con') {
        $fieldsetType = 'contactdetails';
    }
    
    if($fieldsetType)   {
        #my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$fieldsetType}{'core'}, 'PersonRegoForm',);
        my $fieldMessages = getFieldMessages($Data, 'person', $Data->{'lang'}->getLocale());
        my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$fieldsetType}, 'PersonRegoForm',);
        my $obj = new Flow_DisplayFields(
          Data => $Data,
          Lang => $Data->{'lang'},
          SystemConfig => $Data->{'SystemConfig'},
          Fields => $fieldset->{$fieldsetType},
          FieldMessages => $fieldMessages,
        );
        if($action eq 'SPE_')    {
          my ($output, undef, $headJS, undef) = $obj->build($permissions,'edit',1);
          $body .= qq[
            <div class="col-md-12">
            <form id = "flowFormID" action = "$Data->{'target'}" method = "POST">
                $output
                $headJS
                <div class="txtright">
                <input type = "hidden" name = "client" value = "$Data->{'client'}"> 
                <input type = "hidden" name = "a" value = "SPE_U">
                <input type="hidden" name="pID" value="$personID" />
                <input type = "hidden" name = "e_a" value = "$e_action"> 
                <!-- <input type = "hidden" name = "bscrn" value = "$back_screen">  -->
                <input type = "submit" value = "].$Data->{'lang'}->txt('Save').qq[" class = "btn-main"> 
                </div>
            </form>
            </div>
          ];
        }
        if($action eq 'SPE_U'){
            my $p = new CGI;
            my $act_acc = param('act_acc');
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
                $action = 'SPE_';
            }
            else  {
                $personObj->setValues($userData);
                $personObj->write();               
                auditLog(
                    $personID,
                    $Data,
                    'Update Person',
                    'Person',
                );

                $body = 'updated';
                
            }
            $Data->{'RedirectTo'} = "$Defs::base_url/registration/index.cgi?client=$Data->{'client'}&amp;a=HOME&amp;act_acc=". $personObj->ID();
            my $header = $p->redirect(-uri => $Data->{'RedirectTo'});
            print $header;
        } # end SPE_U 
        
    
    } # end $fieldsetType
    my $pageHeading = 'Edit Person';
    return ($body, $pageHeading);
}
