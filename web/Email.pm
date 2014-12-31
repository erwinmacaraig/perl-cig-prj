package Email;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(sendEmail);
@EXPORT_OK = qw(sendEmail);
use lib "..";
use strict;
use Mail::ExternalMailer;
#use Utils;
use DeQuote;


sub sendEmail {
#Sends an email with both html and text parts

    my ($to, $from, $subject, $header, $htmlMsg, $textMsg, $maillog_text, $BCC) = @_;

    $from ||= $Defs::donotreply_email;
    $from = $Defs::donotreply_email if ($from eq ";");
    $htmlMsg= qq[
        <html>
            <head>
                <META http-equiv=Content-Type content="text/html; charset=us-ascii">
            </head>
            <body style="font-family:Arial, Sans-Serif">
                <h1>$header</h1>
                $htmlMsg	
            </body>
        </html>
    ];

    my $headerLength= length($header);
    my $headerLine= '';
    for (my $i=0;  $i<$headerLength; $i++) {
        $headerLine.='-';
    }

    $textMsg ||= 'This email has been sent as HTML.';
    $textMsg= qq[
        $textMsg\n\n

        $headerLine\n
    ];

	open MAILLOG, ">>$Defs::mail_log_file" or print STDERR "Cannot open MailLog $Defs::mail_log_file\n";
	if($to ne "") {
        my $mailer = getMailer();
        $to = $Defs::global_mail_debug if $Defs::global_mail_debug;
		if($mailer) {
            my ($ok, $msg) = $mailer->send(
                TextMessage => $textMsg || '',
                HTMLMessage => $htmlMsg || '',
                Subject => $subject,
                ToAddress => $to,
                FromAddress => $from,
            );
            if($ok) {
                print MAILLOG (scalar localtime()).":$maillog_text :$to: FROM $from Sent OK\n";
                print scalar localtime().":$maillog_text :$to: FROM $from Sent OK\n";
                return 1;
            }
            else {
                print MAILLOG (scalar localtime()).":$maillog_text:$to:Error sending mail: $msg\n"; 
                print scalar localtime().":$maillog_text:$to:Error sending mail: $msg\n";
                return 0;
            }
        }
        else    {
            warn("Cannot initialise Mailer");

        }
    }
}

1;

