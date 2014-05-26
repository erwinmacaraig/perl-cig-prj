package TagManagement;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getTagManager);
@EXPORT_OK = qw(getTagManager);

use strict;
use lib "..",".", "comp/", "../comp";
use Defs;
use RealmObj;
use Utils;


sub getTagManager {
        my (
                $Data,
                $params,
        ) = @_;
        $params ||= {};
	$Data->{'Realm'}||= 1;
	$Data->{'db'} ||= connectDB();
	my $RealmObj =  new RealmObj(db=>$Data->{'db'}, ID=>$Data->{'Realm'});
        my $realmInfo = $RealmObj->load();

	my %TagData = (
                ss_sp_pagename => 'SP Membership',
                ss_sp_pagetype => $Data->{'PageType'} || 'membership',
                ss_sp_ads => 1,
                ss_sp_ads_string => 'advertising,ads',
                ss_sp_ga_account =>  'UA-144085-2',
                net_site=>'sportingpulse',
                net_section=>'spmem',
		ss_sp_sportname=> $realmInfo->{'strRealmAdType'} || 'nosport',
        );

 my $tag_data = '';
 for my $k (keys %TagData)       {
                my $v = $TagData{$k} || next;
                $v =~ s/'/\\'/g;
                $tag_data .= "utag_data.$k = '$v';\n";
        }



my $insert_tag = qq[
 (function(a,b,c,d){
  a='//$Defs::TealiumURLBase/utag.js';
  b=document;c='script';d=b.createElement(c);d.src=a;d.type='text/java'+c;d.async=true;
  a=b.getElementsByTagName(c)[0];a.parentNode.insertBefore(d,a);
  })();
];

 $insert_tag = qq[
 (function() {
    var tealium1 = document.createElement('script'); tealium1.type = 'text/javascript';
    tealium1.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + 'tealium.hs.llnwd.net/o43/utag/newsltd/sportingpulse/dev/utag.js';
    var tealium2 = document.createElement('script'); tealium2.type = 'text/javascript';
    tealium2.src = ('https:' == document.location.protocol ? 'https://' : 'http://') + '//tealium.hs.llnwd.net/o43/utag/newsltd/sportingpulse/dev/utag.footer.js';
    document.getElementsByTagName('body')[0].appendChild(tealium1);
    document.getElementsByTagName('body')[0].appendChild(tealium2);
  })();
] if($Data->{'OverwriteProdType'});



  my $tag = qq~
<!-- START Tealium -->
  utag_data = window.utag_data || {};
  $tag_data
  $insert_tag
<!-- END Tealium -->
  ~;
#<script type="text/javascript" src="//$Defs::TealiumURLBase/utag.footer.js"></script>
  return $tag;
}
1;
