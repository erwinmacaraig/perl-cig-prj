#
# $Header: svn://svn/SWM/trunk/web/PassportChangeover.pm 10051 2013-12-01 22:36:25Z tcourt $
#

package PassportChangeover;
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(show_passport_changeover_screen);
@EXPORT_OK    = qw(show_passport_changeover_screen);

use strict;

use lib '.', '..';

use Defs;
use Utils;
use CGI qw(escape);

sub show_passport_changeover_screen {
	my($Data)=@_;

	return '' if $Data->{'clientValues'}{'passportID'};

	my $body=qq[
	<div id = "passport_changeover" style = "display:none;">
		<div class="pp-logo"><img src="images/sp_membership.png" width="300"></div>
		<p class="changeover-title">On December 5, your <span class="sp-membership">SP Membership</span> login will change</p>
		<p>After this date your current Username/Code & Password will be replaced with a <span class="sp-passport">SP Passport</span> which will provide you access to all your SP products.</p>
		<p>There's no need to wait, get a head start and register for your <span class="sp-passport">SP Passport</span> by clicking Register below.</p>
		<p><a href="https://passport.sportingpulse.com" target="_blank"><span class="sp-passport">Need more info? Click here to see the benefits of SP Passport</span></a></p>
		<div id="pp-prompt-btns">
			<span class="button special-button"><a href="$Defs::base_url/authlist.cgi">Register for SP Passport</a></span>
			<span class="button generic-button"><a href="" id = "passport_changeover_cancel">Continue to Membership</a></span>
		</div>
		<p class="pc-disclaim">After November 30 <span class="sp-passport">SP Passport</span> will be required to access <span class="sp-membership">SP Membership</span>. <span class="sp-passport">SP Passport</span> members do not see this reminder.</p>
	</div>
  <script language="JavaScript1.1" type="text/javascript">
		jQuery(document).ready(function() {
			pp_change_dialog = jQuery( "#passport_changeover" ).dialog({
				modal: true,
				title: "SP Membership",
				width: 600
			});
			jQuery( "#passport_changeover_cancel" ).click(function (event) {
				event.preventDefault();
				jQuery(pp_change_dialog).dialog('close');
			});
		});
	</script>
	];
	return $body;
}

1;
