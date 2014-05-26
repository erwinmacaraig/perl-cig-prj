#
# $Header: svn://svn/SWM/trunk/web/passport/PassportMemberCB.pm 10129 2013-12-03 04:05:17Z tcourt $
#

package PassportMemberCB;
require Exporter;
@ISA =	qw(Exporter);
@EXPORT = qw(
	getMemberSignupDetails
);
@EXPORT_OK = qw(
	getMemberSignupDetails
);

use lib "..", "../..";
use Defs;
use strict;
use CGI qw(:cgi escape);
use Reg_common;
use InstanceOf;

sub getMemberSignupDetails {
	my (
		$Data,
		$callbackkey,
	) = @_;

  my ($memberID, $code) = split /f/,$callbackkey,2;

  return (undef, undef) if !$memberID;
  return (undef, undef) if !$code;

  my $newcode = getRegoPassword($memberID);
  return (undef, undef) if $code ne $newcode;

  my $memberObj = getInstanceOf($Data,'member', $memberID);

	my %mdata = (
		email => $memberObj->getValue('strEmail') || '',
		firstname => $memberObj->getValue('strFirstname') || '',
		familyname => $memberObj->getValue('strSurname') || '',
		country => $memberObj->getValue('strCountry') || '',
		state => $memberObj->getValue('strState') || '',
		address1 => $memberObj->getValue('strAddress1') || '',
		address2 => $memberObj->getValue('strAddress2') || '',
		suburb => $memberObj->getValue('strSuburb') || '',
		postalcode => $memberObj->getValue('strPostalCode') || '',
		phonehome => $memberObj->getValue('strPhoneHome') || '',
		phonemobile => $memberObj->getValue('strPhoneMobile') || '',
		dob => $memberObj->getValue('dtDOB_RAW') || '',
	);

	return (\%mdata, undef);
}
