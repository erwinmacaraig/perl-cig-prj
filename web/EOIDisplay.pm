#
# $Header: svn://svn/SWM/trunk/web/EOIDisplay.pm 11238 2014-04-04 06:41:14Z apurcell $
#

package EOIDisplay;

require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleEOI);
@EXPORT_OK=qw(handleEOI);

use strict;
use Reg_common;
use Utils;
use HTMLForm;
use AuditLog;
use List qw(list_row list_headers);
use Mail::Sendmail;
#use EOI;
use Club;
use Assoc;
use HTML::Entities;
use CGI qw(url param escape unescape);
use Contacts;
use ServicesContacts;
use Log;

require ProgramObj;

sub handleEOI{
	my ($action, $Data)=@_;
    my $resultHTML='';
    my $title='';
    my $clubID    = param('clubID')  || 0;
    my $programID = param('programID')  || 0;
    my $assocID   = param('assocID') || 0;
    my $eoiID     = param('eoiID');
    my $program_obj;
    
    # If we have a programID, then get it's assocID
    if ($programID){
        # Load program obj
        $program_obj = ProgramObj->new(
            'ID' => $programID,
            'db' => $Data->{'db'},
        );
        $program_obj->load();
        
        $assocID = $program_obj->get_assoc_id();
    }
    
    return unless $assocID;
  
    if ($action =~/^EOI_DT/) {
        ($resultHTML,$title) = eoi_details($action, $Data, $assocID, $clubID, $eoiID, $program_obj);
	}
    elsif ($action eq 'EOI_L') {
        ($resultHTML,$title)=list_eoi($Data, $assocID, $clubID);
	}
	return ($resultHTML,$title);
}

sub list_eoi {
  my ($Data, $assocID, $clubID) = @_;
  my $resultHTML = '';
  my $title;
  return ($resultHTML,$title);
}

sub eoi_details {
  my ($action, $Data, $assocID, $clubID, $eoiID, $program_obj) = @_;
  my $dbh = $Data->{'db'};
  my $postcode = param('postcode') || '';
  my $club_search_all = param('club_search_all') || '';
  my $yob = param('yob') || '';
  my $realm = param('r') || 0;    
  my $subrealm = param('sr') || 0;  
  my $option = '';
  if ($action eq 'EOI_DTA'){
    $eoiID = 0;
    $option = 'add';
  }
  else {
    return undef;
  }
  
  my $programID = 0;
  
  if (ref $program_obj){
      $programID = $program_obj->ID();
  }

#  my $eoi =  new EOI('db'=>$dbh,'ID'=>$eoiID);
#  $eoi->load() if $eoiID;
  my $txtName =  &txtName();
  my $txtNames = &txtName('plural');
  my $client = setClient($Data->{'clientValues'}) || '';
  my $url = url(-relative=>1);
  
  my @url_params;
  
  foreach my $param ( qw/ r sr type postcode search_value yob club_search_all / ){
      my $value = param($param);
      next unless $value;
      
      push @url_params, "$param=$value";
  }
  
  my $params = '?' . join( '&', @url_params);

  my $back_url = $url .  HTML::Entities::encode_entities($params);
  my $optIn = 'I wish to receive the latest League & Club news';
  $optIn = 'I wish to receive the latest AFL & Club news' if ($realm == 2);

  my $eoi_success_txt = qq[<p>Your interest has been registered with the selected organisation.</p><p><a href="$back_url">Click here to register interest with additional clubs</a></p>];
  
  if ($Data->{SystemConfig}{eoi_success_txt}){
      $eoi_success_txt = $Data->{SystemConfig}{eoi_success_txt};
      
      # We can add a back link if they have provided custom text for the link
      if ($Data->{SystemConfig}{eoi_success_back_link_txt}){
          $eoi_success_txt .= qq[<p><a href="$back_url">$Data->{SystemConfig}{eoi_success_back_link_txt}</a></p>];
      }
  }
  
  my $compulsory_note = '<p><strong>Note:</strong> All boxes marked with a <img src="images/compulsory.gif" alt="Compulsory Field" title="Compulsory Field"/> are compulsory and must be filled in.</p>';
  
  my @intro_lines = (
    '<p class="introtext">Please complete the following form in the boxes below and when you have finished press the <b>Send Expression of Interest</b> button.</p>',
    $compulsory_note,
  );
 
  my @order = qw/ strFirstName strSurname strPostalCode dtDOB strPhone strEmail /;
  
  if (ref $program_obj){
      
      #TODO: At some stage maybe do a check on the program to see if it takes minors and then add Parent/Guardian fields
      @order = qw/ strFirstName strSurname strPostalCode dtDOB strP1FName strP1SName strP1Phone strP1Email /;
      
      $optIn = ''; # we dont need opt in's for Programs at this stage
      
      # If program full...
      if ($program_obj->is_full()){
          if ($Data->{SystemConfig}{eoi_full_program_intro_txt}){
              @intro_lines = (
                  qq[<p class="introtext">$Data->{SystemConfig}{eoi_full_program_intro_txt}</p>],
                  $compulsory_note,
              );
          }
          else{
              # Keep the existing text, just prepend a reason why they have been brought to this EOI form
              unshift @intro_lines, '<p class="introtext">The program is currently full. More capacity may be added.</p>';
          }
      }
      else {
          # We have someone who doesn't take online regos
          if ($Data->{SystemConfig}{eoi_no_online_rego_intro_txt}){
              @intro_lines = (
                  qq[<p class="introtext">$Data->{SystemConfig}{eoi_no_online_rego_intro_txt}</p>],
                  $compulsory_note,
              );
          }
      }
  }
  
  if ($optIn){
      push @order, 'intOptIn';
  }

  my %FieldDefinitions = (
    fields => {
      strFirstName => {
        label => 'First Name',
        value =>  '',
        type  => 'text',
        size  => 30,
        maxsize => 50,
        compulsory => 1,
      },
      strSurname => {
        label => 'Surname',
        value =>  '',
        type  => 'text',
        size  => 30,
        maxsize => 50,
        compulsory =>1,
      },
      strPostalCode => {
        label => 'Postcode',
        value =>  '',
        type  => 'text',
        size  => 4,
        maxsize => 4,
        compulsory =>1,
      },
      dtDOB => {
        label => 'Date of Birth',
        value =>  '',
        type  => 'date',
        datetype => 'dropdown',
      compulsory =>1,
	},
      strPhone => {
        label => 'Phone',
        value =>  '',
        type  => 'text',
        size  => 20,
        maxsize => 20,
        compulsory =>1,
      },
      strEmail => {
        label => 'Email Address',
        value =>  '',
        type  => 'text',
        validate => 'EMAIL',
        size  => 40,
        maxsize => 100,
        compulsory =>1,
      },
      intOptIn => {
        label => $optIn,
        value => '',
        type  => 'checkbox',
        default => 1,
        displaylookup => {1 => 'Yes', 0 => 'No'},
      },  
      strP1FName => {
        label => 'Parent/Guardian First Name',
        value =>  '',
        type  => 'text',
        size  => 30,
        maxsize => 50,
        compulsory => 1,
      },
      strP1SName => {
        label => 'Parent/Guardian Surname',
        value =>  '',
        type  => 'text',
        size  => 30,
        maxsize => 50,
        compulsory => 1,
      },
      strP1Phone => {
        label => 'Parent/Guardian Phone',
        value =>  '',
        type  => 'text',
        size  => 20,
        maxsize => 20,
        compulsory => 1,
      },
      strP1Email => {
        label => 'Parent/Guardian Email Address',
        value =>  '',
        type  => 'text',
        validate => 'EMAIL',
        size  => 40,
        maxsize => 100,
        compulsory => 1,
      },
    }, # End of Field Definitions.
    order => \@order,
    options => {
      labelsuffix => ':',
      hideblank => 1,
      target => $Data->{'target'},
      formname => 'n_form',
      submitlabel => "Send $txtName",
      introtext => 'auto',
      NoHTML => 1,
      stopAfterAction => 1,
      addSQL => qq[
        INSERT INTO tblEOI
        (intRealmID, dtCreated, intAssocID, intClubID, intProgramID,  --FIELDS-- )
        VALUES ($realm, NOW(), $assocID, $clubID, $programID, --VAL-- )
		  ],
      afteraddFunction => \&postAddEOI,
      afteraddParams => [$Data, $realm, $eoiID],
      addOKtext=> $eoi_success_txt,
      introtext=> join ("\n", @intro_lines) || '',
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Create',
        'EOI',
      ],
      auditEditParams => [
        $clubID,
        $Data,
        'Update',
        'EOI',
      ],
      LocaleMakeText => $Data->{'lang'},
    },
    carryfields => {
      client => $client,
      a => $action,
      eoiID => $eoiID,
      assocID => $assocID,
      clubID => $clubID,
      programID => $programID,
      postcode => $postcode,
      club_search_all => $club_search_all,
      r => $realm,
      sr => $subrealm,
      yob => $yob,
      type => param('type') || '',
      search_value => param('search_value') || $postcode || '',
    },
  );
  my $resultHTML = '';
  ($resultHTML,undef) = handleHTMLForm(\%FieldDefinitions,undef,$option, '',$Data->{'db'});
  my $title = $txtName;
  return ($resultHTML,$title);
}


sub txtName {
  my $plural = shift;
  my $name = $plural ? 'Expressions of Interest' : 'Expression of Interest';
  return $name;
}

sub postAddEOI {
  my ($eoiID,$params,$Data, $realm) = @_;
  my $assocID   = $params->{'assocID'};
  my $clubID    = $params->{'clubID'}; 
  my $programID = $params->{'programID'};
  my $dbh = $Data->{db};
  my $clubAssocName = '';  
  my $email_to; 
  my $dobFORMATTED  =  $params->{'d_dtDOB_year'} . '-' . $params->{'d_dtDOB_mon'} . '-' . $params->{'d_dtDOB_day'};
  my $st = qq[
    SELECT 
      COUNT(intMemberID) as Count
    FROM 
      tblMember
    WHERE
      intRealmID = $realm
      AND intStatus >= 0
      AND strFirstname = ?
      AND strSurname = ?
      AND dtDOB = ?
  ];
  my $qry= $Data->{'db'}->prepare($st) or query_error($st);
  $qry->execute($params->{'d_strFirstName'}, $params->{'d_strSurname'}, $dobFORMATTED) or query_error($st);
  my $count = $qry->fetchrow_array() || 0;
  if ($count)	{
    $st = qq[
      UPDATE tblEOI
      SET intEOIStatus=2
      WHERE intEOIID = $eoiID
    ];
    $Data->{'db'}->do($st);
  } 

  ### -------
  $Data->{'clientValues'}{'assocID'} =  $assocID;
  $Data->{'clientValues'}{'clubID'} = $clubID;
  $Data->{'Realm'} = $realm || 0;
  #my $contacts = getLocatorContacts($Data);
  #for my $href (@{$contacts}) {
  #  next unless($href->{'Email'});
  #  $email_to .= $href->{'Email'} . ';' if ($href->{'PrimaryContact'} or $href->{'Clearances'});
  #}
	my $assocEmail = '';
	if ($clubID and $clubID > 0)	{
		$email_to = getServicesContactsEmail($Data, $Defs::LEVEL_CLUB, $clubID, $Defs::SC_CONTACTS_CLEARANCES);
	}
	$email_to .= qq[;] if $email_to;
	$email_to.= getServicesContactsEmail($Data, $Defs::LEVEL_ASSOC, $assocID, $Defs::SC_CONTACTS_CLEARANCES);


  ### ------
  my @content;
  my $pre_text = '';
  if ($programID){
      # Load program obj
      my $program_obj = ProgramObj->new(
          'ID' => $programID,
          'db' => $Data->{'db'},
      );
      $program_obj->load();
      $clubAssocName = $program_obj->name();
      my $facility_obj = $program_obj->get_facility_obj();
      
      # Get programs email contact
      $email_to = $program_obj->get_contact_email($Data);
      
      #TODO: Future if on program for age groups

      push @content, "\n" . 'Parent/Guardian details';
      push @content, '- First Name:  ' . HTML::Entities::encode(param('d_strP1FName')) if param('d_strP1FName');
      push @content, '- Surname:  ' . HTML::Entities::encode(param('d_strP1SName')) if param('d_strP1SName');
      push @content, '- Phone: ' . HTML::Entities::encode(param('d_strP1Phone'));
      push @content, '- Email: ' . HTML::Entities::encode(param('d_strP1Email'));
      
      push @content, "\n" . 'Program details';
      push @content, '- Program Name: ' . $program_obj->name();
      push @content, '- Facility:     ' . $facility_obj->name();
      push @content, '- Start Date:   ' . $program_obj->getValue('dtStartDate');
      push @content, '- Day:          ' . $program_obj->display_day_of_week();
      push @content, '- Time:         ' . $program_obj->getValue('tmStartTime');

      if ( ( not $program_obj->get_rego_form_id() ) && $Data->{SystemConfig}{eoi_no_online_rego_warning_txt} ){
          # Push warning about how they should switch to using online registrations
          $pre_text = $Data->{SystemConfig}{eoi_no_online_rego_warning_txt};
      }
      
      if( $program_obj->is_full() && $program_obj->get_rego_form_id() && $Data->{SystemConfig}{eoi_full_program_warning_txt} ){
          $pre_text = $Data->{SystemConfig}{eoi_full_program_warning_txt};
      }
      
      if( $Data->{SystemConfig}{eoi_program_footer_txt} ){
          push @content, "\n\n" . $Data->{SystemConfig}{eoi_program_footer_txt};
      }
      
  }
  elsif ($clubID) {
    my $club = loadClubDetails($dbh, $clubID, $assocID); 
    #$email_to = $club->{strEmail};
    $clubAssocName = $club->{strName};
  }
  else {
    my $assoc = loadAssocDetails($dbh, $assocID);
    #$email_to = $assoc->{'strEmail'};
    $clubAssocName = $assoc->{'strName'};
  }

  my $subject = "Expression of Interest to $clubAssocName";  
  my $name =  $params->{'d_strFirstName'} . ' ' .  $params->{'d_strSurname'};
  my $dob  =  $params->{'d_dtDOB_day'} . '/' . $params->{'d_dtDOB_mon'} . '/' . $params->{'d_dtDOB_year'};      
  $name = HTML::Entities::encode($name);
  $dob  = HTML::Entities::encode($dob);
  my $phone = HTML::Entities::encode(param('d_strPhone'));
  my $email = HTML::Entities::encode(param('d_strEmail')); 
  
  my $email_from      = $Data->{SystemConfig}{eoi_reply_email}      || $Defs::donotreply_email;
  my $email_from_name = $Data->{SystemConfig}{eoi_reply_email_name} || $Defs::donotreply_email_name;
  
  my $message_contents  = "You have received an expression of interest for $clubAssocName.\n\n";
  $message_contents .= "$pre_text\n\n" if $pre_text;
  $message_contents .= "- From:          $name\n";
  $message_contents .= "- Date Of Birth: $dob\n";
  $message_contents .= "- Phone:         $phone\n" if $phone; 
  $message_contents .= "- Email:         $email\n" if $email;    
  $message_contents .= join("\n", @content) . "\n";  
  my $boundary="====SportingPulse-r53q6w8sgydixlgfxzdkgkh====";
	my $contenttype=qq[text/plain; charset="us-ascii" boundary="$boundary"];
  my %mail = (
    'To' => "$email_to",
    'From'  => "$email_from_name <$email_from>",
    'Subject' => $subject,
    'Message' => $message_contents,
    'Content-Type' => $contenttype,
    'Content-Transfer-Encoding' => "binary"
  );
  my $error=1;    
  if($mail{To}) {
    if($Defs::global_mail_debug)  { $mail{To}=$Defs::global_mail_debug;}
      open MAILLOG, ">>$Defs::mail_log_file" or print STDERR "Cannot open MailLog $Defs::mail_log_file\n";
      if (sendmail %mail) {
        print MAILLOG (scalar localtime()).":CLR:$mail{To}:Sent OK.\n" ;
        $error=0;
      }
      else {
        print MAILLOG (scalar localtime())." CLR:$mail{To}:Error sending mail: $Mail::Sendmail::error \n" ;
      }
      close MAILLOG;
  }
  return;
}

1;
