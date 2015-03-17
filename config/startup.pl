use CGI ();
CGI->compile();
use Apache::DBI ();
use DBI ();


use lib qw(
/u/current
/u/current/web
/u/current/web/Reports
/u/current/web/RegoForm
/u/current/web/RegoFormBuilder
/u/current/web/ajax
/u/current/web/user

/u/current/web/dashboard
/u/current/web/gendropdown
/u/current/web/user
/u/current/web/BusinessRules
/u/current/web/Clearances
/u/current/web/ExternalGateways
/u/current/web/Mail
/u/current/web/PaymentSplit
/u/current/web/admin
/u/current/web/Registration
/u/current/web/Registration/user

);
#Other Perl Libs
use Date::Calc;

use Lang;
use Reg_common;
use PageMain;
use Navbar;
use Defs;
use Utils;
use SystemConfig;
use Search;
use ReportManager;
use ConfigOptions;
use Clearances;
use ClearanceSettings;
use Duplicates;
use AuditLog;
use Welcome;

use Entity;
use Club;
use Person;
use Changes;
use MemberCard;

use Venues;
use Notifications;
use MCache;
use Documents;
use Logo;

use FieldConfig;
use EntitySettings;

use AddToPage;
use AuthMaintenance;
use Dashboard;
use CheckOnLogin;
use DashboardConfig;

1;
