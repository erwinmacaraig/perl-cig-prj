#
# $Header: svn://svn/SWM/trunk/web/ValidateAuth.pm 10868 2014-03-04 01:30:51Z eobrien $
#

#This file is no longer used, and can be deleted.

package ValidateAuth;
require Exporter;

use POSIX qw(strftime);
use Digest::MD5 qw(md5_base64);

@ISA = qw(Exporter);

@EXPORT = qw(
	ValidateAuth
);
$SHARED_SECRET = '7B031BA4-311A-4B1A-BE6C-3055E3B50DEF';

sub ValidateAuth {
	my ($auth, $ts) = @_;
	my $result = 0;

	my $now = strftime  '%Y%m%d%H%M', gmtime;
	if (($ts > ($now - 2)) && $ts < ($now + 2))
	{
		my $digest = md5_base64($SHARED_SECRET . $ts);
		if ($digest eq $auth) {
			$result = 1;
		}
	}
	$result;
}
