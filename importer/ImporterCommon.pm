package ImporterCommon;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    getImportMACode
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);

use Log;
use Data::Dumper;

sub getImportMACode {
    my ($db) = @_;

    my $st = qq[
        SELECT
            strValue
        FROM
            tblSystemConfig
        WHERE
            strOption = 'ImporterMACode'
            AND intRealmID = 1
        LIMIT 1
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    my $code = $qry->fetchrow_array() || '';
    return $code || '';
}
1;
