package PersonEdit;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    handlePersonEdit
    triggerRule
);

use strict;
use lib '.', '..', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Flow_DisplayFields;
use ConfigOptions qw(ProcessPermissions);
use PersonFieldsSetup;
use FieldLabels;
use Data::Dumper;
use WorkFlow;
use AuditLog;
use FieldMessages;

sub handlePersonEdit {
    my ($action, $Data) = @_;

    my $client = $Data->{'client'};
    my $clientValues = $Data->{'clientValues'};
    my $cl = setClient($clientValues);
    my $e_action = param('e_a') || '';
    my $back_screen = param('bscrn') || '';
    #print STDERR Dumper $back_screen;
    my $personID = getID($clientValues, $Defs::LEVEL_PERSON);
    $personID = 0 if $personID < 0;

    return '' if !$personID;

    my $personObj = new PersonObj(db => $Data->{'db'}, ID => $personID, cache => $Data->{'cache'});
    $personObj->load();
    my $values = {};
    my @fields = keys(%{getFieldLabels($Data, $Defs::LEVEL_PERSON,1)});
    if($personObj->ID())    {
        for my $f (@fields) {
            $values->{$f} = $personObj->getValue($f);
        }
    }
    my $dtype = param('dtype') || '';
    $values->{'defaultType'} = $dtype;

    my $fieldset = personFieldsSetup($Data, $values);

    my $fieldsetType = '';
    if($e_action eq 'core') {
        $fieldsetType = 'core';
    }
    elsif($e_action eq 'con') {
        $fieldsetType = 'contactdetails';
    }

    my $body = '';
    if($fieldsetType)   {
        my $fieldMessages = getFieldMessages($Data, 'person', $Data->{'lang'}->getLocale());
        my $permissions = ProcessPermissions($Data->{'Permissions'}, $fieldset->{$fieldsetType}, 'Person',);
        my $obj = new Flow_DisplayFields(
          Data => $Data,
          Lang => $Data->{'lang'},
          SystemConfig => $Data->{'SystemConfig'},
          Fields => $fieldset->{$fieldsetType},
          FieldMessages => $fieldMessages,
        );
        if($action eq 'PE_U')    {
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
            $action = 'PE_';
          }
          else  {

            $personObj->setValues($userData);
            $personObj->write();

            triggerRule($Data, $values, $personObj) if ($personObj->getValue('strStatus') eq $Defs::PERSON_STATUS_REGISTERED);
            auditLog(
                $personID,
                $Data,
                'Update Person',
                'Person',
            );

            $body = 'updated';
            if($back_screen){
                my %tempClientValues = getClient($Data->{'client'});
                #$tempClientValues{currentLevel} = $tempClientValues{authLevel};
                $tempClientValues{currentLevel} = getLastEntityLevel($Data->{'clientValues'}) || $tempClientValues{authLevel};
                my $tempClient= setClient(\%tempClientValues);

                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$tempClient&$back_screen";
            }
            else {
                $Data->{'RedirectTo'} = "$Defs::base_url/" . $Data->{'target'} . "?client=$Data->{'client'}&a=P_HOME";
            }
          }
        }
        if($action eq 'PE_')    {
          my ($output, undef, $headJS, undef) = $obj->build($permissions,'edit',1);
          $body .= qq[
            <div class="col-md-12">
            <form id = "flowFormID" action = "$Data->{'target'}" method = "POST">
                $output
                $headJS
                <div class="txtright">
                <input type = "hidden" name = "client" value = "].unescape($client).qq["> 
                <input type = "hidden" name = "a" value = "PE_U"> 
                <input type = "hidden" name = "e_a" value = "$e_action"> 
                <input type = "hidden" name = "bscrn" value = "$back_screen"> 
                <input type = "submit" value = "].$Data->{'lang'}->txt('Save').qq[" class = "btn-main"> 
                </div>
            </form>
            </div>
          ];
        }
    }

    my $pageHeading = 'Edit Person';
    return ($body, $pageHeading);
}

sub triggerRule {

    my ($Data, $prevValues, $currPersonObj) = @_;

    my $personID = $currPersonObj->getValue('intPersonID') || return;

    my @fieldsToTriggerWF = split /\|/, $Data->{'SystemConfig'}{'triggerWorkFlowPersonDataUpdate'};

    if(scalar(@fieldsToTriggerWF)) {
        my $triggerWFPersonUpdate = 0;
        foreach (@fieldsToTriggerWF) {
            my $field = $_;
            next if !$field || $triggerWFPersonUpdate;

            my $currVal = $currPersonObj->getValue($field);
            my $prevVal = $prevValues->{$field};

            $triggerWFPersonUpdate = 1 if($currVal and $currVal ne $prevVal);
        }

        if($triggerWFPersonUpdate){
            
            $currPersonObj->setValues({'strStatus' => $Defs::PERSON_STATUS_PENDING});
            $currPersonObj->write();

            my $originEntityID = getID($Data->{'clientValues'},$Data->{'clientValues'}{'authLevel'}) || getLastEntityID($Data->{'clientValues'});

            my $rc = WorkFlow::addWorkFlowTasks(
                $Data,
                'PERSON',
                'AMENDMENT',
                $Data->{'clientValues'}{'authLevel'} || 0,
                $originEntityID,
                $personID,
                0,
                0,
		$currPersonObj->getValue('intInternationalTransfer')
            );
        }

    }

    return 1;
}
