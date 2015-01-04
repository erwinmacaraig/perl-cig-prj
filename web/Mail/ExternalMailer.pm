package Mail::ExternalMailer;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getMailer);
@EXPORT_OK = qw(getMailer);

use strict;

use lib "..", "../..";
use Defs;

use Mail::ExternalMailer_SendGrid;
#use Mail::ExternalMailer_BulkMail;

sub getMailer	{
	my ($type ) = @_;

	my $obj = new Mail::ExternalMailer_SendGrid;
	#my $obj = new Mail::ExternalMailer_BulkMail;
	

	return $obj || undef;
}
