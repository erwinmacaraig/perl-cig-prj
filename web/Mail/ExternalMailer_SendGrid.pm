#
# $Header: svn://svn/SWM/trunk/web/Mail/ExternalMailer_SendGrid.pm 9570 2013-09-20 05:52:40Z tcourt $
#

package Mail::ExternalMailer_SendGrid;

use strict;
use lib "..","../..";

use Mail::ExternalMailer_BaseObj;
our @ISA =qw(Mail::ExternalMailer_BaseObj);

use POSIX qw(strftime);
use JSON;
use CGI qw(escape);
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
	my %params=@_;
  my $self ={};
  ##bless selfhash to class
  bless $self, $class;
	$self->{'APIUsername'} = $Defs::SendGrid_API_Username || return undef;
	$self->{'APIPassword'} = $Defs::SendGrid_API_Password || return undef;

  return $self;
}

sub send {
	my $self = shift;
	my %params=@_;

	my @options = (qw(
		HTMLMessage
		TEXTMessage
		MessageID
		Subject
		FromName
		FromAddress
		ReplyToAddress
		BCCRecipients
		CCRecipients
		ToAddress
		ToName
		MessageCategory
	));
	for my $o (@options)	{
		$params{$o} ||= '';
	}
	my %compulsory = (
		Subject => 1,
		FromAddress => 1,
		ToAddress => 1,
	);

	my $error = '';
	if (!$params{'HTMLMessage'}
		and !$params{'TextMessage'}
	)	{
		return (0,'Need Message');
	}
	for my $k (keys %compulsory)	{
		return (0,'Need '.$k) if !$params{$k};
	}

	my %outputparams = (
		api_user => $self->{'APIUsername'},
		api_key => $self->{'APIPassword'},

	);
	$outputparams{'to'} = $params{'ToAddress'};
	$outputparams{'subject'} = $params{'Subject'};
	$outputparams{'from'} = $params{'FromAddress'};

	if($params{'FromName'})	{
		$outputparams{'fromname'} = $params{'FromName'};
	}
	if($params{'ToName'})	{
		$outputparams{'toname'} = $params{'ToName'};
	}
	if($params{'TextMessage'})	{
		$outputparams{'text'} = $params{'TextMessage'};
	}
	if($params{'HTMLMessage'})	{
 		$outputparams{'html'} = $params{'HTMLMessage'};
	}
	if($params{'ReplyToAddress'})	{
		$outputparams{'replyto'} = $params{'ReplyToAddress'};
	}

	$outputparams{'date'} = strftime("%a, %d %b %Y %H:%M:%S %z", localtime(time()));

	my %options_to_json = (
		unique_args => {
			msgID => $params{'MessageID'},
			category => $params{'MessageCategory'} || '',
		},
	);
	$outputparams{'x-smtpapi'} = to_json(\%options_to_json);
	if(
        $params{'BCCRecipients'} 
        and ref($params{'BCCRecipients'}) eq 'ARRAY' 
        and scalar(@{$params{'BCCRecipients'}})
    )    {
        my @addresses = ();
        my %address_seen = ();
        for my $email (@{ $params{'BCCRecipients'}})	{
            next if $address_seen{$email};
            next if $email !~/\@/;
            next if $email !~/\./;
            push @addresses, $email;
            $address_seen{$email} = 1;
        }
        return (0, 'No Recipients') if !scalar(@addresses);

        $outputparams{'bcc'} = \@addresses;
    }

	if(
        $params{'CCRecipients'} 
        and ref($params{'CCRecipients'}) eq 'ARRAY' 
        and scalar(@{$params{'CCRecipients'}})
    )    {
        my @addresses = ();
        my %address_seen = ();
        for my $email (@{ $params{'CCRecipients'}})	{
            next if $address_seen{$email};
            next if $email !~/\@/;
            next if $email !~/\./;
            push @addresses, $email;
            $address_seen{$email} = 1;
        }
        return (0, 'No Recipients') if !scalar(@addresses);

        $outputparams{'cc'} = \@addresses;
    }

    my $content = '';
    for my $k (keys %outputparams) {
        $content .= qq[------------------------------400f182a9360\r\nContent-Disposition: form-data; name="$k"\r\nContent-Type: text/html\r\n\r\n$outputparams{$k}\r\n];
    }
    $content .= qq[------------------------------400f182a9360\r\n];
    $content .= qq[------------------------------400f182a9360------------------------------\r\n];

    my $url = 'https://sendgrid.com/api/mail.send.json';
    my $ua = LWP::UserAgent->new();
    #my $req = POST $url, \%outputparams;
    my $req = POST $url;
    $req->content_type("multipart/form-data; boundary=----------------------------400f182a9360");
    $req->content($content);
    $req->content_length(length($content));

    my $res= $ua->request($req);
	my $retvalue = $res->content() || '';
	my $retvalues = from_json($retvalue);

	return (1, $retvalues->{'message'} || '') if $retvalues->{'message'};
	return (0, $retvalues->{'error'} || '') if $retvalues->{'error'};
}


1;
