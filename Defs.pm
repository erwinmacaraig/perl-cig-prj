package Defs;
require Exporter;
@ISA = qw(Exporter);
#use DBIx::Profile;

no warnings;

# Log Configuration
$LOG_CONF = q/
log4perl.oneMessagePerAppender = 1

log4perl.rootLogger = ERROR, Screen

# an example to open debug log for one package
log4perl.logger.Utils = DEBUG, Screen

log4perl.appender.Logfile = Log::Log4perl::Appender::File
log4perl.appender.Logfile.filename = website.log
log4perl.appender.Logfile.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Logfile.layout.ConversionPattern = %r %F %L %m%n

log4perl.appender.Screen = Log::Log4perl::Appender::Screen
log4perl.appender.Screen.stderr = 1
log4perl.appender.Screen.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Screen.layout.ConversionPattern=%M %m%n
# log4perl.appender.Screen.layout = Log::Log4perl::Layout::SimpleLayout
/;

@MemCacheServers = (
 {
   address => '127.0.0.1:11211',
   weight => 30000,
 },
);

## DB ACCESS INFO

$DB_DSN = "DBI:mysql:fifasponlinedevel"; ##CONFIG
$DB_USER = "root"; ##CONFIG
$DB_PASSWD = 'password'; ##CONFIG
$DB_DSN_REPORTING = "DBI:mysql:fifasponlinedevel"; ##CONFIG

$DevelMode = 1;

#Passport Defs
$PassportURL = 'http://192.168.200.160/passport/trunk/web/';
$PassportSignature = 'swmkey';
$PassportPublicKey = 'swmpubkey';
$PassportMembershipKey = 'fn0534753405758047578'; #Used for passport talking to SWM

$version='4.0';
$base_url = 'http://192.168.56.101'; ##CONFIG
$duplicate_url = 'http://elwood/FIFASPOnline/web'; ##CONFIG
$sync_logs = 'http://elwood/FIFASPOnline/sync/logs'; ##CONFIG
$helpurl='http://support.sportingpulse.com';
$sitename="SportingPulse";
$page_title='Sportzware Membership';

$admin_email_name="Admin";
$admin_email='warren@sportingpulse.com';
$global_mail_debug='bruce@sportingpulse.com';
$null_email = 'DoNotReply@sportingpulse.com';
$null_email_name = 'SportingPulse';
$fs_base="/home/administrator/src/FIFASPOnline";
$fs_webbase="$fs_base/web";

$SWOL_teamsheet_template_path = "$fs_base/teamplates/teamsheets";

$fs_upload_dir="$fs_base/uploaded";
$uploaded_url="$base_url/../uploaded";
$formimage_url="$base_url/formsimg";
$salesimage_url = "$base_url/../salesimg";
$fs_formdir="$fs_base/forms";
$fs_salesimage_dir = "$fs_base/salesimg";
$fs_customreports_dir="$fs_base/customreports";

$mail_log_file="/var/log/sp-mail/mail.log";

$cookie_domain="192.168.56.101"; ##CONFIG
$COOKIE_MEMBER="reg_m";
$COOKIE_LOGIN="_SP_M";
$COOKIE_ENTITY ="_SP_M_E";
$COOKIE_EVENT="reg_e";
$COOKIE_ACTSTATUS = 'SWOMREC';
$COOKIE_MCSTATUS = 'SWOMMCREC';
$COOKIE_CLR_ACTSTATUS = 'SWOMCLRREC';
$COOKIE_MTYPEFILTER = 'SWOMMTF';
$COOKIE_CLR_ACTSTATUS = 'SWOMCLRREC';
$COOKIE_CLR_MEMNAME= 'SWOMCLRREC_mn';
$COOKIE_CLR_FROMCLUB= 'SWOMCLRREC_fromclub';
$COOKIE_CLR_TOCLUB= 'SWOMCLRREC_toclub';
$COOKIE_CLR_YEAR= 'SWOMCLRREC_year';
$COOKIE_TXN_ACTSTATUS = 'SWOMTXNREC';
$COOKIE_PRODSTATUS = 'SWOMPRODREC';
$COOKIE_FGRID = 'SWOMFGRID';
$COOKIE_REGFORMSESSION = 'SWOMRFSID';

$USER_STATUS_INVALID = 0,
$USER_STATUS_NOTCONFIRMED = 1,
$USER_STATUS_CONFIRMED = 2,
$USER_STATUS_DELETED = 3,
$USER_STATUS_SUSPENDED = 5,
$USER_STATUS_EMAILSUSPENDED = 6,


## SEASONS
$COOKIE_SEASONFILTER = 'SWOMSNFILTER';
$COOKIE_AGEGROUPFILTER = 'SWOMAGEGRPFILTER';

$SECRET_SALT="62tfdxcgf68dvxcgvxc9gvg9d9esgsdeg9rgdcxvgcxivgd9f7efiiu";
$expiryseconds = 60 * 400;

 # ACCESS LEVEL CODES
  $LEVEL_NONE = -1;
  $LEVEL_PERSON = 1;
  $LEVEL_MEMBER= 1;
  $LEVEL_TEAM = 2;
  $LEVEL_CLUB = 3;
  $LEVEL_COMP = 4;
  $LEVEL_ASSOC = 5;
  $LEVEL_ZONE = 10;
  $LEVEL_REGION = 20;
  $LEVEL_STATE = 30;
  $LEVEL_NATIONAL = 100;
  $LEVEL_INTZONE = 110;
  $LEVEL_INTREGION = 120;
  $LEVEL_INTERNATIONAL = 200;
  $LEVEL_TOP = 400;
	$LEVEL_VENUE = -47;
  $LEVEL_EVENT_TRANSPORT= -48;
  $LEVEL_EVENT_ACCRED= -49;
  $LEVEL_EVENT= -50;
  $LEVEL_PROGRAM = -57;

  #$LEVEL_EDU        = -150;
  $LEVEL_EDU_ADMIN  = -150;
  $LEVEL_EDU_DA     = -151;
  $LEVEL_EDU_MODULE = -152;

   
$INVALID_ID = -1;

$NODE_HIDE=0;
$NODE_SHOW=1;

## GENERAL STATUS VALUES

$PERSONSTATUS_ACTIVE=1;
$PERSONSTATUS_POSSIBLE_DUPLICATE=2;
$PERSONSTATUS_DELETED=-1;

$RECSTATUS_DELETED=-1;
$RECSTATUS_ACTIVE=1;
$RECSTATUS_INACTIVE=0;

## GENDER INFO

$GENDER_NONE=0;
$GENDER_MALE=1;
$GENDER_FEMALE=2;
$GENDER_MIXED=3;

%genderInfo = (
		$GENDER_NONE => "None Specified",
		$GENDER_MALE => "Male",
		$GENDER_FEMALE => "Female",
		$GENDER_MIXED => "Mixed"
);

%PersonGenderInfo = (
		$GENDER_NONE => "None Specified",
		$GENDER_MALE => "Male",
		$GENDER_FEMALE => "Female",
);
%genderEventInfo = (
    $GENDER_MALE => "Men",
    $GENDER_FEMALE => "Women",
    $GENDER_MIXED => "Mixed"
);


## DATA ACCESS STATUS

$DATA_ACCESS_NONE = 0;
$DATA_ACCESS_STATS = 1;
$DATA_ACCESS_READONLY = 5;
$DATA_ACCESS_FULL = 10;

%DataAccessNames	= (
	$DATA_ACCESS_NONE => 'No Access',
	$DATA_ACCESS_STATS => 'Statistical Access',
	$DATA_ACCESS_FULL => 'Full Access', 
	$DATA_ACCESS_READONLY => 'Read Only Access',
);

## CONFIG INFO USED IN HIDING FIELDS & IMPORTER

$CONFIG_PERMISSIONS= 1;
$CONFIG_DISPLAY= 2;
$CONFIG_ASSOCUP_DISPLAY= 3;
$CONFIG_OTHEROPTIONS = 4;
$CONFIG_EXTREGODISPLAY= 5;
$CONFIG_EXTTEAMREGODISPLAY= 6;
$CONFIG_MEMBERLISTFIELDS=7;
$CONFIG_ASSOCUP_PERMISSIONS= 8;
$CONFIG_STATEANDUP_DISPLAY= 9;
$CONFIG_STATEANDUP_PERMISSIONS= 10;


$CONFIG_FIELD_SHOW=1;
$CONFIG_FIELD_RO=2;
$CONFIG_FIELD_HIDE=3;
$CONFIG_FIELD_COMPUL=4;
$CONFIG_FIELD_ADDONLY=5;

$CONFIG_DEFCODES_MODIFY_BOTH= 0;
$CONFIG_DEFCODES_MODIFY_ADD= 1;
$CONFIG_DEFCODES_MODIFY_DEL= 2;
$CONFIG_DEFCODES_MODIFY_NONE= 3;


## TRUE FALSE VALUES

$FALSE = 0;
$TRUE = 1;

%tfInfo = (
		$FALSE => "No",
		$TRUE => "Yes"
);


# Member types
$MEMBER_TYPE_PLAYER = 1;
$MEMBER_TYPE_COACH = 2;
$MEMBER_TYPE_UMPIRE = 3;
$MEMBER_TYPE_OFFICIAL = 4;
$MEMBER_TYPE_MISC = 5;
$MEMBER_TYPE_VOLUNTEER = 6;
$MEMBER_SUBTYPE_PLAYER_DISCIPLINES = 1;
$MEMBER_SUBTYPE_ACCRED = 1;
$MEMBER_SUBTYPE_POS = 2;

%memberTypeName = (
    $MEMBER_TYPE_PLAYER => 'Player',
    $MEMBER_TYPE_COACH => 'Coach',
    $MEMBER_TYPE_UMPIRE => 'Match Official',
    $MEMBER_TYPE_OFFICIAL => 'Official',
    $MEMBER_TYPE_MISC => 'Misc',
    $MEMBER_TYPE_VOLUNTEER => 'Volunteer',
);

%FieldPermWeights = ( 
    Hidden            => 1,
    ReadOnly          => 2,
    Editable          => 3,
    Compulsory        => 4,
    AddOnlyCompulsory => 5,
);

$MEMBER_LINK_STATUS_DELETED=-1;
$MEMBER_LINK_STATUS_ACTIVE=1;
$MEMBER_LINK_STATUS_INACTIVE=2;
$MEMBER_LINK_STATUS_CLEAREDOUT_DATA=3;
$MEMBER_LINK_STATUS_CLEAREDOUT_NODATA=4;

# ENTITY TYPES
$TYPE_LEAGUE = 1; 
$TYPE_CLUB = 2;
$TYPE_TEAM = 3;
$TYPE_COMPETITION = 4;
$TYPE_VENUE = 5;
 
%entityInfo = ( 
    $TYPE_LEAGUE => 'League',
    $TYPE_CLUB => 'Club',
    $TYPE_TEAM => 'Team',
    $TYPE_COMPETITION => 'Competition',
    $TYPE_VENUE => 'Venue',
);

%NationalityType	= (
	1 => 'National',
	2 => 'Indigene',
	3 => 'Ex Patriot',
);

%CompAgeLevel = (
	S => 'Senior',
	J => 'Junior',
	V => 'Veteran',
);

$SELECTION_STATUS_OK=0;
$SELECTION_STATUS_LOCKED_BY_GOV=1;
$SELECTION_STATUS_LOCKED_BY_EVENT=2;

$EXPORT_FORMAT_SPORTZWARE=1;
$EXPORT_FORMAT_TAB=2;
$EXPORT_FORMAT_OMEGA=3;
$EXPORT_FORMAT_MEETMANAGER=4;

### Import Flags
$MAINTENANCE_FLAG=0;
$OVERLOAD_FLAG=0;
$CREATED_BY_ONLINE = 0;
$CREATED_BY_SYNC = 1;
$CREATED_BY_AUSKICK= 200;
$CREATED_BY_REGOFORM= 200;
$CREATED_BY_OTHER= -1;
$CREATED_BY_SWCIMPORTER = 2;
$CREATED_BY_MANUALENTRY = 3;


$TXN_PAID = 1;
$TXN_CANCELLED = 2;
$TXN_UNPAID = 0;
$TXN_SHOWALL = -1;
%ProdTransactionStatus	=	(
	$TXN_UNPAID => 'Unpaid',
	$TXN_CANCELLED => 'Cancelled',
	$TXN_PAID => 'Paid', 
);
%TransactionStatus	=	(
	$TXN_UNPAID => 'Unpaid',
	$TXN_CANCELLED => 'Cancelled',
	$TXN_PAID => 'Paid', 
);

$TXNLOG_SUCCESS=1;
$TXNLOG_CANCELLED=2;
$TXNLOG_PENDING=0;
$TXNLOG_FAILED= -1;

%TransLogStatus =       (
        $TXNLOG_SUCCESS => 'Paid',
        $TXNLOG_CANCELLED => 'Cancelled',
        $TXNLOG_PENDING => 'Pending',
        $TXNLOG_FAILED => 'Failed',
);

$PAYMENT_NONE = '';
$PAYMENT_ONLINECREDITCARD= 1;
$PAYMENT_PERSONALCHEQUE = 2;
$PAYMENT_CASH = 3;
$PAYMENT_INTERNATIONALCHEQUE = 4;
$PAYMENT_MONEYORDER = 5;
$PAYMENT_BANKCHEQUE = 6;
$PAYMENT_EFTPOSMASTERCARD = 7;
$PAYMENT_EFTPOSVISA = 8;
$PAYMENT_EFTPOSBANKCARD = 9;
$PAYMENT_EFTPOSSAVINGS = 10;
$PAYMENT_ONLINEPAYPAL= 11;
$PAYMENT_BANKTRANSFER= 12;
$PAYMENT_ONLINENAB= 13;
$PAYMENT_MIXED = 14;
$PAYMENT_BARTER = 20;

%paymentTypes = (
        $PAYMENT_NONE => '[none]',
        $PAYMENT_ONLINECREDITCARD=> 'Online Credit Card',
        $PAYMENT_PERSONALCHEQUE => 'Personal Cheque',
        $PAYMENT_CASH => 'Cash',
        $PAYMENT_INTERNATIONALCHEQUE =>'International Cheque',
        $PAYMENT_MONEYORDER => 'Money Order',
        $PAYMENT_BANKCHEQUE => 'Bank Cheque',
        $PAYMENT_EFTPOSMASTERCARD => 'Eftpos - Mastercard',
        $PAYMENT_EFTPOSVISA => 'Eftpos - Visa',
        $PAYMENT_EFTPOSBANKCARD => 'Eftpos - Bankcard',
        $PAYMENT_EFTPOSSAVINGS => 'Eftpos - Savings',
        $PAYMENT_ONLINEPAYPAL=> 'Online PayPal',
        $PAYMENT_BANKTRANSFER=> 'Bank Transfer',
        $PAYMENT_BARTER => 'Other / Barter',
);

%manualPaymentTypes = (
        $PAYMENT_NONE => '[none]',
        $PAYMENT_PERSONALCHEQUE => 'Personal Cheque',
        $PAYMENT_CASH => 'Cash',
        $PAYMENT_INTERNATIONALCHEQUE =>'International Cheque',
        $PAYMENT_MONEYORDER => 'Money Order',
        $PAYMENT_BANKCHEQUE => 'Bank Cheque',
        $PAYMENT_EFTPOSMASTERCARD => 'Eftpos - Mastercard',
        $PAYMENT_EFTPOSVISA => 'Eftpos - Visa',
        $PAYMENT_EFTPOSBANKCARD => 'Eftpos - Bankcard',
        $PAYMENT_EFTPOSSAVINGS => 'Eftpos - Savings',
        $PAYMENT_BARTER => 'Other / Barter',
);


#Schools
$SCHOOL_SEARCH_LIMIT=50;
$SCHOOL_COOKIE='regspsch';


#EDU
$EDU_IMAGE_COUNT = 2;
@EDU_IMAGE_DIMENSIONS = qw(300x300 300x300);
@EDU_IMAGE_LABELS = qw(Logo Signature);


$DA_IMAGE_COUNT = 2;
@DA_IMAGE_DIMENSIONS = qw(300x300 300x300);
@DA_IMAGE_LABELS = qw(Logo Signature);


$CS_FAILED=-1;
$CS_NOT_COMPLETED=0;
$CS_COMPLETED=1;
%mmtCompletedStatus = (
        $CS_FAILED =>        'Not yet competent',
        $CS_NOT_COMPLETED => 'Pending',
        $CS_COMPLETED =>     'Competent',
);

%mmCompletedStatus = (
        $CS_FAILED =>        'Not yet competent',
        $CS_NOT_COMPLETED => 'Pending',
        $CS_COMPLETED =>     'Competent',
);


$MM_A_REJECTED=-1;
$MM_A_PENDING=0;
$MM_A_ACCEPTED=1;
%mmApprovalStatus = (
        $MM_A_REJECTED=>   'Rejected',
        $MM_A_PENDING=>    'Pending',
        $MM_A_ACCEPTED=>         'Approved',
);


$MM_R_FAILED=-1;
$MM_R_NA=0;
$MM_R_PASSED=1;
%mmResult = (
        $MM_R_FAILED=>    'Failed',
        $MM_R_NA=>        'Not Available',
        $MM_R_PASSED=>   'Passed',
);


$TABLE_TYPE_MEMBERMODULE = 1;



%tableTypeName = (
    $TABLE_TYPE_MEMBERMODULE => 'tblMemberModule',
);


$MODULE_STATUS_CANCELLED=-1;
$MODULE_STATUS_ACTIVE=1;
%moduleStatus = (
        $MODULE_STATUS_CANCELLED=>   'Cancelled',
        $MODULE_STATUS_ACTIVE=>      'Active',
);

$TEMPLATE_CODE_PREFIX='T';
$COURSE_CODE_PREFIX='C';
$MODULE_CODE_PREFIX='M';

$STAFF_MODULE_TEMPLATE_STATUS_UNQUALIFIED=0;
$STAFF_MODULE_TEMPLATE_STATUS_QUALIFIED=1;
%staff_module_template_status = (
        $STAFF_MODULE_TEMPLATE_STATUS_UNQUALIFIED => 'Unqualified',
        $STAFF_MODULE_TEMPLATE_STATUS_QUALIFIED => 'Qualified',
);


#Clearances
$DIRECTION_FROM_SOURCE=1;
$DIRECTION_TO_DESTINATION=2;
$CLUB_LEVEL_CLEARANCE=1;
$ASSOC_LEVEL_CLEARANCE=2;
$NODE_LEVEL_CLEARANCE=3;

#Event Def Codes
$EVENTDEFCODES_HOTELS =1;
$EVENTDEFCODES_HOTELTRANSPORT =2;
$EVENTDEFCODES_AIRLINE=3;
$EVENTDEFCODES_INTERDOMESTIC=4;
$EVENTDEFCODES_AIRPORT=5;

$EVENTUNIFORM_DEFCODES_1 = 1;
$EVENTUNIFORM_DEFCODES_2 = 2;
$EVENTUNIFORM_DEFCODES_3 = 3;
$EVENTUNIFORM_DEFCODES_4 = 4;

%LevelNames = (
  $LEVEL_NONE => 'None',
  $LEVEL_MEMBER => 'Member',
  $LEVEL_TEAM =>'Team',
  $LEVEL_CLUB => 'Club',
  $LEVEL_COMP => 'Comp',
  $LEVEL_ASSOC => 'Association',
  $LEVEL_ZONE => 'Zone',
  $LEVEL_REGION => 'Region',
  $LEVEL_STATE => 'State',
  $LEVEL_NATIONAL => 'National',
  $LEVEL_INTZONE => 'Inter Zone',
  $LEVEL_INTREGION => 'Inter Regional',
  $LEVEL_INTERNATIONAL => 'International',
  $LEVEL_TOP => 'Top',
  $LEVEL_EVENT=> 'Event',
  $LEVEL_VENUE => 'Venue',
  $LEVEL_PROGRAM => 'Program',
);

%AgeType = (
  1 => 'Junior',
  2 => 'Senior',
  3 => 'All Ages',
);

%ClubType = (
  1 => 'Normal',
  2 => 'Non-Association',
  3 => 'Non-Playing',
);

%AssocType = (
  1 => 'Junior',
  2 => 'Senior',
  3 => 'Both',
);

$REGO_FORM_SALT = "1234";

$bank_export_dir="/u/web/swm/trunk/web/banksplits/";
$bank_export_dir_web="banksplits/";

#EDU
$LEVEL_EDU_ADMIN  = -150;
  $LEVEL_EDU_DA     = -151;
  $LEVEL_EDU_MODULE = -152;
$EDU_IMAGE_COUNT = 2;
@EDU_IMAGE_DIMENSIONS = qw(300x300 300x300);
@DA_IMAGE_LABELS = qw(Logo Signature);


$DA_IMAGE_COUNT = 2;
@DA_IMAGE_DIMENSIONS = qw(300x300 300x300);
@DA_IMAGE_LABELS = qw(Logo Signature);


$CS_FAILED=-1;
$CS_NOT_COMPLETED=0;
$CS_COMPLETED=1;
%mmtCompletedStatus = (
        $CS_FAILED =>        'Not yet competent',
        $CS_NOT_COMPLETED => 'Pending',
        $CS_COMPLETED =>     'Competent',
);

%mmCompletedStatus = (
        $CS_FAILED =>        'Not yet competent',
        $CS_NOT_COMPLETED => 'Pending',
        $CS_COMPLETED =>     'Competent',
);


$MM_A_REJECTED=-1;
$MM_A_PENDING=0;
$MM_A_ACCEPTED=1;
%mmApprovalStatus = (
        $MM_A_REJECTED=>   'Rejected',
        $MM_A_PENDING=>    'Pending',
        $MM_A_ACCEPTED=>         'Approved',
);


$MM_R_FAILED=-1;
$MM_R_NA=0;
$MM_R_PASSED=1;
%mmResult = (
        $MM_R_FAILED=>    'Failed',
        $MM_R_NA=>        'Not Available',
        $MM_R_PASSED=>   'Passed',
);


$TABLE_TYPE_MEMBERMODULE = 1;



%tableTypeName = (
    $TABLE_TYPE_MEMBERMODULE => 'tblMemberModule',
);

$MODULE_STATUS_CANCELLED=-1;
$MODULE_STATUS_ACTIVE=1;
%moduleStatus = (
        $MODULE_STATUS_CANCELLED=>   'Cancelled',
        $MODULE_STATUS_ACTIVE=>      'Active',
);

$TEMPLATE_CODE_PREFIX='T';
$COURSE_CODE_PREFIX='C';
$MODULE_CODE_PREFIX='M';

$STAFF_MODULE_TEMPLATE_STATUS_UNQUALIFIED=0;
$STAFF_MODULE_TEMPLATE_STATUS_QUALIFIED=1;
%staff_module_template_status = (
        $STAFF_MODULE_TEMPLATE_STATUS_UNQUALIFIED => 'Unqualified',
        $STAFF_MODULE_TEMPLATE_STATUS_QUALIFIED => 'Qualified',
);



#MySport Stuff
$COOKIE_MYSPORT="spulse_lg";
$RegoServerKey='df09s8h5w498y5209^&%*&T*#';
$MySportCheckURL='http://localhost';

## CLEARANCES:
$DIRECTION_FROM_SOURCE=1;
$DIRECTION_TO_DESTINATION=2;
$CLUB_LEVEL_CLEARANCE=1;
$ASSOC_LEVEL_CLEARANCE=2;
$NODE_LEVEL_CLEARANCE=3;

$CLR_STATUS_PENDING = 0;
$CLR_STATUS_APPROVED= 1;
$CLR_STATUS_DENIED = 2;
$CLR_STATUS_CANCELLED= -1;
%clearance_status= (
                $CLR_STATUS_PENDING => "Pending",
                $CLR_STATUS_APPROVED => "Approved",
                $CLR_STATUS_DENIED => "Denied",
                $CLR_STATUS_CANCELLED => "Cancelled",
);
%clearance_status_approvals= (
                $CLR_STATUS_APPROVED => "Approved",
                $CLR_STATUS_DENIED => "Denied",
);

### New Clearance/Permit fields

$CLR_TYPE_ALL= 0;
$CLR_TYPE_CLR= -99;
$CLR_TYPE_PERMIT_MATCHDAY = 1;
$CLR_TYPE_PERMIT_LOCALINTX= 2;
$CLR_TYPE_PERMIT_TRANSFER = 3;

$CLRPERMIT_MATCHDAY=1;
$CLRPERMIT_LOCALINTX=2;
$CLRPERMIT_TRANSFER=3;

$CLR_MANUAL= 0;
$CLR_AUTO_APPROVE= 1;
$CLR_AUTO_DENY= 2;
%ClearanceApprovals=    (
        $CLR_MANUAL=>'Manual Intervention Required',
        $CLR_AUTO_APPROVE=>'Auto Approve',
        $CLR_AUTO_DENY=>'Deny All',
);

%clearancePermitType=    (
  2 =>  { ##Footy Web
        ''=>'-None-',
        $CLRPERMIT_MATCHDAY =>'1. Match Day',
        $CLRPERMIT_LOCALINTX=>'2. Local Interchange',
        $CLRPERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  3 =>  { ##ARLD
        ''=>'-None-',
  },
  5 =>  { ##
        ''=>'-None-',
        $CLRPERMIT_MATCHDAY =>'1. Match Day',
        $CLRPERMIT_LOCALINTX=>'2. Local Interchange',
        $CLRPERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  6 =>  { ##Footy Web
        ''=>'-None-',
        $CLRPERMIT_MATCHDAY =>'1. Match Day',
        $CLRPERMIT_LOCALINTX=>'2. Local Interchange',
        $CLRPERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  13 => { ##Footy Web
        ''=>'-None-',
        $CLRPERMIT_MATCHDAY =>'1. Match Day',
        $CLRPERMIT_LOCALINTX=>'2. Local Interchange',
        $CLRPERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  27 => { ##Footy Web
        ''=>'-None-',
        $CLRPERMIT_MATCHDAY =>'1. Match Day',
        $CLRPERMIT_LOCALINTX=>'2. Local Interchange',
        $CLRPERMIT_TRANSFER=>'3. Temporary Transfer',
  },
);

%ClearanceRuleTypes=    (
  2 =>  { ## RealmID
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'2. Local Interchange',
        $CLR_TYPE_PERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  3 =>  { ##Footy Web
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'Portability',
        $CLR_TYPE_PERMIT_TRANSFER=>'Temporary Clearance',
  },
  5 =>  { ## RealmID
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'2. Local Interchange',
        $CLR_TYPE_PERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  6 =>  { ## RealmID
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'2. Local Interchange',
        $CLR_TYPE_PERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  13 => { ## RealmID
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'2. Local Interchange',
        $CLR_TYPE_PERMIT_TRANSFER=>'3. Temporary Transfer',
  },
  27 => { ## RealmID
        $CLR_TYPE_CLR=>'Transfers/Clearances Only',
        $CLR_TYPE_PERMIT_LOCALINTX=>'2. Local Interchange',
        $CLR_TYPE_PERMIT_TRANSFER=>'3. Temporary Transfer',
  },
);

%clearance_financial=   (
        1=>'Financial',
        2=>'Unfinancial',
);
%clearance_suspended=   (
        1=>'Suspended',
        2=>'NOT Suspended',
);
%clearance_priority=    (
        0=>'Low',
        1=>'Normal',
        2=>'High',
);

$CLR_OUTWARD= 1;
$CLR_INWARD= 2;
$CLR_BOTH= 3;
%ClearanceDirections=    (
        $CLR_INWARD=>'Inward Only',
        $CLR_OUTWARD=>'Inward Only',
        $CLR_BOTH=>'Both ways',
);

$CLR_TYPE_ONLINE= 0;
$CLR_TYPE_SWC= 1;
$CLR_TYPE_MANUAL= 2;
%ClearanceTypes=    (
        $CLR_TYPE_ONLINE=>'Online Clearance',
        $CLR_TYPE_SWC=>'Created in SWC',
        $CLR_TYPE_MANUAL=>'Manual Clearance History',
);

# Communicator message types
$MESSAGE_TYPE_EMAIL = 1; 
$MESSAGE_TYPE_SMS = 2;

# Payment split fields
$PS_MAX_SPLITS = 5;
$PS_REMAINDER_SPLIT = $PS_MAX_SPLITS + 1;

%PS_FeesType = (
  1 => 'SportingPulse Fees',
  2 => 'Bank Fees',
);

### Venue Types
%VenueTypes=    (
        1=>'Ground',
        2=>'Club House',
        3=>'Tribunal Venue',
);
### Process Log
$PROCESSLOG_COMP_LDR = 1;
$PROCESSLOG_COMP_PLAYER_STATS = 2;
$PROCESSLOG_SWW_UPLOAD = 99;
$PROCESSLOG_MEDIARPT_EMAIL = 3;

%processLogTypes = (
                   $PROCESSLOG_COMP_LDR=>'Competition Ladder Update',
                   $PROCESSLOG_COMP_PLAYER_STATS=>'Competition Player Stats Update',
                   $PROCESSLOG_SWW_UPLOAD=>'Competition Upload to SportingPulse',
                   $PROCESSLOG_MEDIARPT_EMAIL=>'Emailing Media Report',
                   );

### Process Log Statuses
$PROCESSLOG_WAITING = 1;
$PROCESSLOG_RUNNING = 2;
$PROCESSLOG_COMPLETED = 3;
$PROCESSLOG_FAILED = 4;

%processLogStatuses = (
                       $PROCESSLOG_WAITING => 'Waiting',
                       $PROCESSLOG_RUNNING => 'Running',
                       $PROCESSLOG_COMPLETED => 'Completed',
                       $PROCESSLOG_FAILED => 'Failed',
                   );

# Communicator message types
$MESSAGE_TYPE_EMAIL = 1; 
$MESSAGE_TYPE_SMS = 2;

$PRODUCT_AGE_GROUPS = 1;
$PRODUCT_MEMBER_TYPES = 2;

$PRODUCT_PROGRAM_NEW = 5;
$PRODUCT_PROGRAM_RETURNING = 6;


### Media Reporting Member Name Formats
$MEMBER_NAME_FULL = 1;
$MEMBER_NAME_FAMILY_INITIAL = 2;
$MEMBER_NAME_FAMILY = 3;

%memberNameFormat = (
                     $MEMBER_NAME_FULL =>'Full Name',
                     $MEMBER_NAME_FAMILY_INITIAL => 'Family Name and Initial',
                     $MEMBER_NAME_FAMILY => 'Family Name Only',
                 );

$PRODUCTS_MINLEVEL_NATIONAL= 1;

%ProductChangeLevel= (
  $LEVEL_CLUB => 'Club Level',
  $LEVEL_ASSOC => 'Assoc level',
  $LEVEL_NATIONAL => 'National level',
);

### VARIABLES ADDED FOR PAYPAL PAYMENT OPTION
$PAYPAL_CHECKOUT_IMAGE = 'https://fpdbs.paypal.com/dynamicimagesweb?cmd=_dynamic-image';

$PAYPAL_DEMO_URL_EXPRESS= 'https://api-3t.sandbox.paypal.com/nvp';
$PAYPAL_DEMO_URL_REDIRECT = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout';
$PAYPAL_DEMO_URL_MASSPAY = 'https://api-3t.sandbox.paypal.com/nvp';
$PAYPAL_DEMO_USERNAME ="viking_1249435445_biz_api1.sportingpulse.com";
$PAYPAL_DEMO_PASSWORD ="ZKHXCXW5CLB64TYD";
$PAYPAL_DEMO_SIGNATURE="AKYuXVkhF40sNXmNNcLlWmaJDyVGARqyuo3ZsCtrPCYJAJsrcypjK5n2";

$PAYPAL_LIVE_URL_EXPRESS= 'https://api-3t.sandbox.paypal.com/nvp';
$PAYPAL_LIVE_URL_REDIRECT = 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd=_express-checkout';
$PAYPAL_LIVE_URL_MASSPAY = 'https://api-3t.sandbox.paypal.com/nvp';
$PAYPAL_LIVE_USERNAME ="viking_1249435445_biz_api1.sportingpulse.com";
$PAYPAL_LIVE_PASSWORD ="ZKHXCXW5CLB64TYD";
$PAYPAL_LIVE_SIGNATURE="AKYuXVkhF40sNXmNNcLlWmaJDyVGARqyuo3ZsCtrPCYJAJsrcypjK5n2";

$PAYPAL_URL_MASSPAY = 'https://api-3t.sandbox.paypal.com/nvp';
#$PAYPAL_USERNAME ="bruce_1215144384_biz_api1.sportingpulse.com";
#$PAYPAL_PASSWORD ="1215144390";
#$PAYPAL_SIGNATURE="AMfLovvIm6f6ssz0iFfT3tEV5CW8Abgv5Sw42mfEO7HFTPPWNEulmvdN";

$PAYPAL_VERSION ="58.0";
$PAYPAL_RETURN_URL = "http://devel.pnp-local.com.au/swm/trunk/web/paypal.cgi?a=S";
$PAYPAL_CANCEL_URL = "http://devel.pnp-local.com.au/swm/trunk/web/paypal.cgi?a=C";

$GATEWAY_CC=1;
$GATEWAY_PAYPAL=2;

$COMP_ROUND_HOMEAWAY = 0;
$COMP_ROUND_FINALS = 2;
$MESSAGE_TYPE_SMS = 2;

# Payment split fields
$PS_MAX_SPLITS = 5;
$PS_REMAINDER_SPLIT = $PS_MAX_SPLITS + 1;

%PS_FeesType = (
  1 => 'SportingPulse Fees',
  2 => 'Bank Fees',
);



$PROD_TYPE_MINFEE = 2;

$micropay_export_dir="/u/web/swm/trunk/micropay/";
$ML_TYPE_GATEWAYFEES=1;
$ML_TYPE_SPMAX=2;
$ML_TYPE_LPF=3;
$ML_TYPE_SPFINAL=4;
$ML_TYPE_SPORTTOTAL=5;
$ML_TYPE_SPLIT=6;

%CommunicatorMessageCategory = (
  1 => ['Notification',4],
  2 => ['News',2],
);
$SC_MENU_SHORT=1;
$SC_MENU_CURRENT_OPTION_DETAILS=1;
$SC_MENU_CURRENT_OPTION_CONTACTS=2;
$SC_MENU_CURRENT_OPTION_AGREEMENTS=3;
$SC_MENU_CURRENT_OPTION_SERVICES=4;

#Services & Contacts - Contact Sections
$SC_CONTACTS_CLEARANCES=1;
$SC_CONTACTS_PAYMENTS=2;
%timeSlotDays= (
                0=> "Sunday",
                1=> "Monday",
                2=> "Tuesday",
                3=> "Wednesday",
                4=> "Thursday",
                5=> "Friday",
                6=> "Saturday",
);

$REGOFORM_TYPE_MEMBER_ASSOC = 1;
$REGOFORM_TYPE_TEAM_ASSOC = 2;
$REGOFORM_TYPE_MEMBER_TEAM = 3;
$REGOFORM_TYPE_MEMBER_CLUB = 4;
$REGOFORM_TYPE_TEAM_PARTPAY = 5;
$REGOFORM_TYPE_MEMBER_PROGRAM = 6;

%RegoFormTypeDesc = (
    1 => 'Member to Association',
    2 => 'Team to Association',
    3 => 'Member to Team', 
    4 => 'Member to Club',
);

$RFCOPYTYPE_TEMPLATE_TO_ASSOC = 1;
$RFCOPYTYPE_ASSOC_TO_CLUB = 2;
$RFCOPYTYPE_WITHIN_ASSOC = 3;
$RFCOPYTYPE_TEMPLATE_TO_CLUB = 4;
$RFCOPYTYPE_WITHIN_CLUB = 5;

$UPLOADFILETYPE_DOC = 1;
$UPLOADFILETYPE_LOGO = 2;
$UPLOADFILETYPE_PRODIMAGE = 3;
$UPLOADFILETYPE_APPLICATION= 4;

## LOGIN LEVEL
$VENUE_LEVEL = -5;
$ASSOC_LEVEL = 5;
$TEAM_LEVEL = 2;
$CLUB_LEVEL = 3;

%notificationStatus=(
  0=>'Pending',
  1=>'Viewed',
  2=>'Ignored',
  3=>'Accepted',
);

$PROCESSLOG_COURTSIDE_STADIUM_SCORING = '';
$GOVBODY_AUTH_TYPE = '';

$PROCESSLOG_FINALSELIGIBILITY = '';

$PRICING_TYPE_SINGLE = 0;
$PRICING_TYPE_MULTI  = 1;
$PRICING_TYPE_RANGED = 2;

#Registration constants
%personType = (
		'PLAYER'=>'Player',	
		'COACH'=>'Coach',	
		'REFEREE'=>'Referee',	
);

$PERSON_TYPE_PLAYER = 'AMATEUR';
$PERSON_TYPE_COACH = 'COACH';
$PERSON_TYPE_REFEREE = 'REFEREE';
	
%personLevel = (
	'AMATEUR'=>'Amateur',	
	'PROFESSIONAL'=>'Professional',	
);	

$PERSON_LEVEL_AMATEUR = 'AMATEUR';
$PERSON_LEVEL_PROFESSIONAL = 'PROFESSIONAL';

%sportType = (
	'FOOTBALL'=>'Football',	
	'BEACHSOCCER'=>'Beach Soccer',	
	'FUTSAL'=>'Futsal',	
);	

$SPORT_TYPE_FOOTBALL = 'FOOTBALL';
$SPORT_TYPE_BEACHSOCCER = 'BEACHSOCCER';
$SPORT_TYPE_FUTSAL = 'FUTSAL';
	
%registrationNature = (
	'NEW'=>'New Registration',	
	'RENEWAL'=>'Renewal',	
	'AMENDMENT'=>'Amendment',
	'TRANSFER'=>'Transfer'
);

$REGISTRATION_NATURE_NEW = 'NEW';
$REGISTRATION_NATURE_RENEWAL = 'RENEWAL';
$REGISTRATION_NATURE_AMENDMENT = 'AMENDMENT';
$REGISTRATION_NATURE_TRANSFER = 'TRANSFER';

%ageLevel = (
	'SENIOR'=>'Senior',	
	'YOUTH'=>'Youth',	
);

$AGE_LEVEL_SENIOR = 'SENIOR';
$AGE_LEVEL_YOUTH = 'YOUTH';

#End of Registration constants

1;
