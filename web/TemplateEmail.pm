package TemplateEmail;
require Exporter;
@ISA =	qw(Exporter);
@EXPORT = qw(sendTemplateEmail);
@EXPORT_OK = qw(sendTemplateEmail);

use strict;
use lib "..";
use Defs;
use Utils;
use TTTemplate;
use Mail::ExternalMailer;

$ENV{'PATH'} = '/bin';

sub sendTemplateEmail	{
	#Returns 1 on success 0 on failure
	my(
		$Data,
		$templatefile,
		$templatedata,
		$toaddress,
		$subject,
		$fromaddress,
		$ccaddress,
		$bccaddress,
	) = @_;

	my $templateblob = runTemplate(
		$Data,
		$templatedata,
		"emails/$templatefile",
	);

	return wantarray ? (0,'') : 0 if !$templateblob;
	return wantarray ? (0,'') : 0 if (!$toaddress and !$ccaddress and !$bccaddress);
	return wantarray ? (0,'') : 0 if !$subject;
	$fromaddress ||= $Defs::admin_email;
    $fromaddress = $Defs::admin_email if  $fromaddress eq ';';
    my $fromname = '';

    if($Data->{'SystemConfig'}{'AdminEmailSenderName'}) {
        $fromname = $Data->{'SystemConfig'}{'AdminEmailSenderName'};
    }
    elsif($fromaddress eq $Defs::admin_email)  {
        $fromname = $Defs::admin_email_name;
    }

	#fix email addresses if no toaddress, but we have cc address or bcc address
	if($toaddress eq '' and $ccaddress) {
		$toaddress = $ccaddress;
		$ccaddress = '';
	} 
	
	open MAILLOG, ">>$Defs::mail_log_file" or warn("Cannot open MailLog\n");
    my $message = $templateblob;

    if($toaddress ne "") {
        my $mailer = getMailer();
        if($Defs::global_mail_debug)    {
            $toaddress = $Defs::global_mail_debug;
            $ccaddress = '';
            $bccaddress = '';
        }
        if($mailer) {
            my ($ok, $msg) = $mailer->send(
                HTMLMessage => $templateblob || '',
                Subject => $subject,
                ToAddress => $toaddress,
                FromAddress => $fromaddress,
                FromName => $fromname,
                BCCRecipients => (split /\s*,\s*/, $bccaddress) || [],
                CCRecipients => (split /\s*,\s*/, $ccaddress) || [],
            );
            if($ok) {
                print MAILLOG (scalar localtime()).":Template:$subject:$toaddress: FROM $fromaddress Sent OK\n";
                warn(scalar localtime().":Template:$subject:$toaddress: FROM $fromaddress Sent OK\n");
                return 1;
                return wantarray ? (1,$message) : 1;
            }
            else {
                print MAILLOG (scalar localtime()).":Template:$subject:$toaddress:Error sending mail: $msg\n";
                warn(scalar localtime().":Template:$subject:$toaddress:Error sending mail: $msg\n");
                return wantarray ? (0,$message) : 0;
            }
        }
        else    {
            warn("Cannot initialise Mailer");

        }
    }
}

1;

