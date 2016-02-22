package Flow_BaseObj;

use strict;
use CGI qw(:cgi escape);

use lib "..","../..";
use strict;
use ConfigOptions;
use TTTemplate;
use Reg_common;
use Flow_DisplayFields;
use HTML::FillInForm;
use Log;
use Data::Dumper;
use JSON;
sub new {

  my $this   = shift;
  my $class  = ref($this) || $this;
  my %params = @_;
  my $self   = {};
  ##bless selfhash to class
  bless $self, $class;

    #Set Defaults
    $self->{'db'}             = $params{'db'};
    $self->{'Data'}           = $params{'Data'};
    $self->{'Lang'}           = $params{'Lang'};
    $self->{'CarryFields'}    = $params{'CarryFields'}   || ();
    $self->{'SystemConfig'}   = $params{'SystemConfig'};

    $self->{'Permissions'}    = $params{'Permissions'};
    $self->{'ClientValues'}   = $params{'ClientValues'};
    $self->{'Target'}         = $params{'Target'}        || '';
    $self->{'cgi'}            = $params{'cgi'}           || new CGI;
    $self->{'AllowSaveState'} = $params{'AllowSaveState'}|| 0;
    $self->{'SavedFlowURL'}   = $params{'SavedFlowURL'} || '';
    $self->{'CancelFlowURL'}  = $params{'CancelFlowURL'} || '';
    $self->{'DefaultTemplate'}   = $params{'DefaultTemplate'} || 'flow/default.templ';
    $self->{'RunDetails'}     = {};
    $self->{'RunParams'}      = {};
    $self->{'CookiesToWrite'} = ();
    $self->{'FieldSets'} = {};
    $self->{'ID'} = $params{'ID'} || 0;
    $self->{'UserID'} = $params{'UserID'} || 0;

    $self->{'DEBUG'} ||= 0;

    return undef if !$self->{'db'};
 
    return $self;
}

# --- Placeholder functions - may be overridden

sub run {
    my $self = shift;

    #Setup the variables and values we are going to need
    $self->_setupRun();
    $self->setupValues();

    #Call function based on current process index
    my $next = 1;
    my $retvalue = '';
    my $body = '';
    ($body, $next) = $self->_handleCancelSave();
    while($next) {
        if($self->isLastPage() and $self->{'AllowSaveState'}) {
            $self->clearState();
        }
        ($retvalue, $next) = $self->runNextFunction();
        $body .= $retvalue;
        if($next == 1)  {
            $next = $self->incrementCurrentProcessIndex();
            $self->saveState() if $self->{'AllowSaveState'};
        }
    }
    
    return ($body, $self->{'CookiesToWrite'});
}

sub _setupRun   {
    my $self = shift;

    my $cgi = $self->{'cgi'};
    $self->{'RunParams'} = {};
    for my $param (keys %{$cgi->Vars()}) {
        $self->{'RunParams'}{$param} = join(',', $cgi->param($param));
    }
    $self->_reloadCarryFields();
    if($self->{'RunParams'}{'e'})   {
        $self->{'ID'} = $self->{'RunParams'}{'e'};
    }
    $self->addCarryField('e', $self->ID());
    if($self->{'RunParams'}{'_ss'})   {
        $self->addCarryField('_ss', $self->{'RunParams'}{'_ss'});
    }
    $self->getProcessOrder();
    $self->setCurrentProcessIndex($self->{'RunParams'}->{'rfp'});

    return 1;
}

sub _handleCancelSave {
    my $self = shift;

    my $rfp = $self->{'RunParams'}{'rfp'} || '';
    if(
        $rfp eq '_cancel'
        or $rfp eq '_save'
    )   {
        if($rfp eq '_cancel')   {
            $self->clearState();
            $self->cancelFlow();
        }
        my $body = $self->display({
            action => $rfp,
            SavedFlowURL => $self->{'SavedFlowURL'},
            CancelFlowURL => $self->{'CancelFlowURL'},
        },'flow/flow_cancelsave.templ');
        return ($body,0);
    }
    return ('',1);
}


sub Navigation {
    #May need to be overriden in child class to define correct order of steps
  my $self = shift;

    my $navstring = '';
    my $meter = '';
    my @navoptions = ();
    my $step = 1;
    my $step_in_future = 0;
    my $noNav = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'NoNav'} || 0;
    my $noGoingBack = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'NoGoingBack'} || 0;
    return '' if $noNav;
    my $startingStep = $self->{'RunParams'}{'_ss'} || '';
    my $includeStep = 1;
    $includeStep = 0 if $startingStep;
    my $lastDisplayIndex = 0;
    for my $i (0 .. $#{$self->{'ProcessOrder'}})    {
        my $current = 0;
        my $name = $self->{'Lang'}->txt($self->{'ProcessOrder'}[$i]{'label'} || '');
        if($startingStep and $self->{'ProcessOrder'}[$i]{'action'} eq $startingStep)   {
            $includeStep = 1;
        }
        next if !$includeStep;
        next if($self->{'ProcessOrder'}[$i]{'NoNav'});
        next if($self->{'ProcessOrder'}[$i]{'NoDisplayInNav'});
        if($name)   {
            $current = 1 if $i == $self->{'CurrentIndex'};
            push @navoptions, [
                $name,
                $current || $step_in_future || 0,
            ];
            my $currentclass = '';
            $currentclass = 'current' if $current;
            $currentclass = 'next' if $step_in_future;
            $currentclass ||= 'previous';
            $meter = $step if $current;
            my $showlink = 0;
            $showlink = 1 if(!$current and !$step_in_future);
            $showlink = 0 if($self->{'ProcessOrder'}[$i]{'noRevisit'});
            $showlink = 0 if $noGoingBack;
            my $linkURL = $self->{'Target'}."?rfp=".$self->{'ProcessOrder'}[$i]{'action'}."&".$self->stringifyURLCarryField();
            $self->{'RunDetails'}{'DirectLinks'}[$i] = $linkURL;

			my $link = $showlink
                #? qq[<a href="$linkURL" class = "stepname">$step. $name</a>]
                #: qq[<span class = "stepname">$step. $name</span>];

                ? qq[<a href="$linkURL" class = "stepname">$step. $name</a>]
                : qq[<span class = "stepname">$step. $name</span>];
            
			#$navstring .= qq[ <li class = "$currentclass step step-$step"><span class="$currentclass step-num">$link</li> ];
            $navstring .= qq[ <div class = "col-md-2 $currentclass step step-$step"><span class="$currentclass step-num">$link</span></div> ];
            $step_in_future = 2 if $current;
            $step++;
            $lastDisplayIndex = $i;
        }
    }
    #my $returnHTML = '';
    #$returnHTML .= qq[<ul class = "playermenu list-inline form-nav">$navstring</ul><div class="meter"><span class="meter-$meter"></span></div> ] if $navstring;
    #$returnHTML .= qq[<div class = "progressFlow">$navstring</div><div class="meter"><span class="meter-$meter"></span></div> ] if $navstring;           

    my $onLastStep = $self->{'CurrentIndex'} >= $lastDisplayIndex;
    my $completeClass = $onLastStep ? 'progressComplete' : '';
    my $returnHTML = '';
    
    $returnHTML .= qq[<div class = "progressFlow $completeClass ">$navstring</div><div class="meter"><span class="meter-$meter"></span></div> ] if $navstring;        
    

    if(wantarray)   {
        return ($returnHTML, \@navoptions);
    }
    return $returnHTML || '';
}

# ------------------  Process Order Management Functions

sub incrementCurrentProcessIndex    {
  my $self = shift;

    if($self->{'CurrentIndex'} < $#{$self->{'ProcessOrder'}})   {
        $self->{'CurrentIndex'}++;
        return 1;
    }
    return 0;
}

sub decrementCurrentProcessIndex    {
  my $self = shift;

    if($self->{'CurrentIndex'} > 0)   {
        $self->{'CurrentIndex'}--;
        return 1;
    }
    return 0;
}

sub getNextAction {
  my $self = shift;

    my $index = $self->{'CurrentIndex'} + 1;
    if($index <= $#{$self->{'ProcessOrder'}})   {
        return $self->{'ProcessOrder'}[$index]{'action'} || '';
    }
    return '';
}

sub getCurrentAction {
  my $self = shift;

    my $index = $self->{'CurrentIndex'};
    if($index <= $#{$self->{'ProcessOrder'}})   {
        return $self->{'ProcessOrder'}[$index]{'action'} || '';
    }
    return '';
}

sub isLastPage {
    my $self = shift;

    my $index = $self->{'CurrentIndex'};
    if($index == $#{$self->{'ProcessOrder'}})   {
        return 1;
    }
    return 0;
}

sub setCurrentProcessIndex {
  my $self = shift;
    my($index) = @_;

    if($index and $index =~ /^[a-zA-Z]+$/ and $self->{'ProcessOrderLookup'}{$index})   {
        $self->{'CurrentIndex'} = $self->{'ProcessOrderLookup'}{$index};
        return 1;
    }
    $self->{'CurrentIndex'} = 0;
    return 0;
}


sub getProcessOrder {
  my $self = shift;

    $self->setProcessOrder();
    for my $i (0 .. $#{$self->{'ProcessOrder'}})    {
        $self->{'ProcessOrderLookup'}{$self->{'ProcessOrder'}[$i]{'action'}} = $i;
    }
}


sub runNextFunction {
  my $self = shift;

    my $retvalue = '';
    my $next = 0;
    if($self->{'ProcessOrder'}[$self->{'CurrentIndex'}]) {
        my $sub_name = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'function'};
        my $sub_ref = $self->can($sub_name);
        if ($sub_ref){
            ($retvalue, $next) = &$sub_ref($self); 
        }
    }
    return ($retvalue, $next);  
}

# --------------- Utility functions

sub ID  {
  my $self = shift;
  return $self->{'ID'} || 0;
}

sub title {
  my $self = shift;
  my $title = $self->{'Lang'}->txt($self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'title'} || '');
  return $title || '';
}

sub setID  {
  my $self = shift;
  my($ID) = @_;
  $self->{'ID'} = $ID || 0;
  $self->addCarryField('e', $self->ID());
  return 1;
}

sub display {
  my $self = shift;
  my($templateData, $templateName) = @_;

  $templateData ||= {};
  $templateName ||= $self->{'DefaultTemplate'};
  if(!$templateData->{'FlowNextAction'})  {
      $templateData->{'FlowNextAction'} = $self->getNextAction();
  }
  if(!$templateData->{'Navigation'})  {
      $templateData->{'Navigation'} = $self->Navigation();
      $templateData->{'PageTitle'} = $self->title();
  }
  $templateData->{'AllowSaveState'} ||= $self->{'AllowSaveState'} || 0;
  if(exists($templateData->{'AllowSaveStateOverride'})) {
    $templateData->{'AllowSaveState'} = $self->{'AllowSaveStateOverride'};
  }
  $templateData->{'ContinueButtonText'} ||= 'Continue';
  $templateData->{'CancelButtonURL'} ||= $self->{'Target'}."?rfp=_cancel&amp;".$self->stringifyURLCarryField();
  $templateData->{'SaveButtonURL'} = $self->{'Target'}."?rfp=_save&amp;".$self->stringifyURLCarryField();
  if($self->isLastPage() and $self->{'AllowSaveState'}) {
      $templateData->{'CancelButtonURL'} = '';
      $templateData->{'SaveButtonURL'} = '';
  }
	if(exists($templateData->{'BackButtonURLOverride'})){
		$templateData->{'BackButtonURL'} = $templateData->{'BackButtonURLOverride'};
	}	
    else {
		($templateData->{'BackButtonURL'}, $templateData->{'BackButtonDestination'}) = $self->buildBackButton();
	}
  my $output = runTemplate($self->{'Data'}, $templateData, $templateName);
  if($templateData->{'Errors'} and scalar(@{$templateData->{'Errors'}})) {
    my $filledin = HTML::FillInForm->fill(\$output, $self->{'RunParams'});
    $output = $filledin;
  }
  return $output;
}

sub displayFields {
  my $self = shift;
  my($permissions, $fieldSet, $fieldMessages) = @_;
  $fieldSet ||= $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'fieldset'};
  $permissions ||= {};
  $fieldMessages ||= '';
  return '' if !$fieldSet;
  my $obj = new Flow_DisplayFields(
    Data => $self->{'Data'},
    Lang => $self->{'Lang'},
    SystemConfig => $self->{'SystemConfig'},
    Fields => $self->{'FieldSets'}{$fieldSet},
    FieldMessages => $fieldMessages,
  );
  my $action = $self->ID() ? 'edit' : 'add';
  return $obj->build($permissions,$action,1);
}

sub gatherFields {
  my $self = shift;
  my($permissions, $fieldSet) = @_;
  $fieldSet ||= $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'fieldset'};
  $permissions ||= {};
  return ({},[]) if !$fieldSet;
  my $obj = new Flow_DisplayFields(
    Data => $self->{'Data'},
    Lang => $self->{'Lang'},
    SystemConfig => $self->{'SystemConfig'},
    Fields => $self->{'FieldSets'}{$fieldSet},
  );

  my $action = $self->ID() ? 'edit' : 'add';
  return $obj->gather($self->{'RunParams'},$permissions, $action);
}


sub error_message   {
  my $self = shift;
    my ($msg) = @_;
    my $msg_lang = $self->{'Lang'}->txt($msg) || return '';
    return qq[
        <div class = "msg-error">$msg_lang</div>
    ];
}

sub setCarryFields {
  my $self = shift;
    my($fields) = @_;
    $self->{'CarryFields'} = $fields;
    $self->_refreshCarryFieldIndex();
}

sub deleteCarryField {
  my $self = shift;
    my($fieldname) = @_;
    return $self->addCarryField($fieldname,'');
}

sub addCarryField {
  my $self = shift;
    my($fieldname, $value) = @_;
    return 0 if !$fieldname;
    if($value)  {
        $self->{'CarryFields'}{$fieldname} = $value;
        $self->{'RunParams'}{$fieldname} = $value;
    }
    else    {
        delete $self->{'CarryFields'}{$fieldname};
    }
    $self->_refreshCarryFieldIndex();
    return 1;
}

sub stringifyCarryField {
  my $self = shift;
    my $string = '';
    for my $k (keys %{$self->{'CarryFields'}})  {
        my $name = $k;
        my $value = $self->{'CarryFields'}{$k};
        $value = '' if !defined $value;
        $name =~s/"/\"/g;
        $value =~s/"/\"/g;
        $string .=qq[<input type = "hidden" name = "$name" value = "$value">];
    }
    return $string;
}

sub stringifyURLCarryField {
  my $self = shift;
    my $string = '';
    for my $k (keys %{$self->{'CarryFields'}})  {
        my $name = $k;
        my $value = escape($self->{'CarryFields'}{$k});
        $string .= "$name=$value&amp;";
    }
    return $string;
}

sub _refreshCarryFieldIndex {
  my $self = shift;
    my $string = '';
    my @keys= ();
    for my $k (keys %{$self->{'CarryFields'}})  {
        if($k and $k ne '__cf')    {
            push @keys, $k;
        }
    }
    $self->{'CarryFields'}{'__cf'} = join('|',@keys);
    return $self->{'CarryFields'}{'__cf'};
}


sub _reloadCarryFields {
  my $self = shift;
  if($self->{'RunParams'} and $self->{'RunParams'}{'__cf'}) {
    my $fieldlist = $self->{'RunParams'}{'__cf'} || '';
    for my $k (split /\|/,$fieldlist)   {
        $self->{'CarryFields'}{$k} = $self->{'RunParams'}{$k};
    }
  }
  $self->_refreshCarryFieldIndex();
}

sub getCarryFields {
  my $self = shift;
    my ($fieldname) = @_;
    if($fieldname)  {
        return $self->{'CarryFields'}{$fieldname};
    }
    my %tempcarry = %{$self->{'CarryFields'}};
    delete($tempcarry{'__cf'});
    return  \%tempcarry;
}

sub buildBackButton {
  my $self = shift;

  my $currentIndex = $self->{'CurrentIndex'} || 0;
  my $noGoingBack = $self->{'ProcessOrder'}[$self->{'CurrentIndex'}]{'NoGoingBack'} || 0;
  if(!$currentIndex or $noGoingBack)  {
    return ('','');
  }
  my $backIndex = $currentIndex - 1 ;
  my $text = '';
  while($backIndex >= 0 and $text eq '')    {
    if(!$self->{'ProcessOrder'}[$backIndex]{'NoNav'})   {
        $text = $self->{'ProcessOrder'}[$backIndex]{'label'} || '';
    }
    $backIndex-- if !$text;
  }
  return ('','') if !$text;
  
  my $url = $self->{'RunDetails'}{'DirectLinks'}[$backIndex] || '';
  return ($url, $text);
}


#--------- State Management

sub saveState   {
    my $self = shift;
    my $id = $self->ID();

    my $st = qq[
        INSERT INTO tblRegoState (
            userEntityID,
            userID,
            regoType,
            entityID,
            regoID,
            parameters,
            ts
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?,
            NOW()
        )
        ON DUPLICATE KEY UPDATE
            userID = ?,
            parameters = ?,
            ts = NOW()
    ];

    my ( $type, $userEntityID, $entityID, $regoID, $userID) = $self->getStateIds();
    return 0 if !$type;
    my %params = %{$self->{'RunParams'}};
    $params{'rfp'} = $self->getCurrentAction();

    #Get updated carry fields
    my $cf = $self->getCarryFields();
    for my $k (keys %{$cf})    {
        $params{$k} = $cf->{$k};
    }
    $params{'__cf'} = $self->_refreshCarryFieldIndex();

    my $q = $self->{'db'}->prepare($st);
    $q->execute(
        $userEntityID,
        $userID,
        $type,
        $entityID,
        $regoID,
        encode_json(\%params),
        $userID,
        encode_json(\%params),
    );
    if($regoID) {
        # Handle the case where the state is saved and now added regoID
        my $st_d = qq[
            DELETE FROM 
                tblRegoState
            WHERE
                userEntityID = ?
                AND userID = ?
                AND regoType = ?
                AND entityID = ?
                AND regoID = 0
        ];
        my $q_d = $self->{'db'}->prepare($st_d);
        $q_d->execute(
            $userEntityID,
            $userID,
            $type,
            $entityID,
        );
    }

    return 1 

}

sub clearState   {
    my $self = shift;
    my $id = $self->ID();

    my ( $type, $userEntityID, $entityID, $regoID, $userID) = $self->getStateIds();
    return 0 if !$type;

    my $st_d = qq[
        DELETE FROM 
            tblRegoState
        WHERE
            userEntityID = ?
            AND userID = ?
            AND regoType = ?
            AND entityID = ?
            AND regoID = ?
    ];
    my $q_d = $self->{'db'}->prepare($st_d);
    $q_d->execute(
        $userEntityID,
        $userID,
        $type,
        $entityID,
        $regoID,
    );

    return 1 

}

# ------------------- Stub Functions ---

sub setupValues { }

sub setProcessOrder {
    my $self = shift;
    $self->{'ProcessOrder'} = [
        {
            'action' => 'd',
            'function' => 'display_form',
            'label'  => 'Full Information',
            'fieldset'  => 'core',
        },
        {
            'action' => 'vd',
            'function' => 'validate_form',
            'fieldset'  => 'core',
        },
        {
            'action' => 'e',
            'function' => 'end',
        },
    ];
    
}

sub cancelFlow{return 1 };
sub getStateIds{ return ('',0,0,0,0); }

sub display_form {return ('',1);}
sub validate_form {return ('',1);}
sub end {return ('',1);}


1;
