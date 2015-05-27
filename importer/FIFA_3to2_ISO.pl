#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/moneylogInsert.pl 8250 2013-04-08 08:24:36Z rlee $
#

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    
    my @dbFields = qw(strISOCountryOfBirth strISOCountry strISOMotherCountry strISOFatherCountry strISONationality);

    my %Countries = ();
## Jervy, as we look at the Data after 1st run, we will update below hash
    $Countries{'SGP'} = 'SG';
    $Countries{'MYS'} = 'MY';
    $Countries{'SINGAPORE'} = 'SG';
    $Countries{'MAR'} = 'MA';
    $Countries{'GIN'} = 'GN';
    $Countries{'IND'} = 'IN';
    $Countries{'GUY'} = 'GY';
    $Countries{'JAP'} = 'JP';
    $Countries{'GBR'} = 'GB';
    $Countries{'THA'} = 'TH';
    $Countries{'FRA'} = 'FR';
    $Countries{'KOR'} = 'KR';
    $Countries{'PRT'} = 'PT';
    $Countries{'HRV'} = 'HR';
    $Countries{'LTU'} = 'LT';
    $Countries{'PHL'} = 'PH';
    $Countries{'SRB'} = 'RS';
    $Countries{'NGA'} = 'NG';
    $Countries{'TTO'} = 'TT';
    $Countries{'URY'} = 'UY';
    $Countries{'USA'} = 'US';
    $Countries{'MKD'} = 'MK';
    $Countries{'NZL'} = 'NZ';
    $Countries{'IRL'} = 'IE';
    $Countries{'SVK'} = 'SK';
    $Countries{'NLD'} = 'NL';
    $Countries{'SWE'} = 'SE';
    $Countries{'LBN'} = 'LB';
    $Countries{'ITA'} = 'IT';
    $Countries{'NPL'} = 'NP';
    $Countries{'ESP'} = 'ES';
    $Countries{'IDN'} = 'ID';
    $Countries{'ROU'} = 'RO';
    $Countries{'MNE'} = 'ME';
    $Countries{'VNM'} = 'VN';
    $Countries{'DEU'} = 'DE';
    $Countries{'DUE'} = 'DE';
    $Countries{'Freanch'} = 'FR';
    $Countries{'JPN'} = 'JP';
    $Countries{'DZA'} = 'DZ';
    $Countries{'BRN'} = 'BN';
    $Countries{'CAN'} = 'CA';
    $Countries{'DNK'} = 'DK';
    $Countries{'BIH'} = 'BA';
    $Countries{'AUS'} = 'AU';
    $Countries{'COL'} = 'CO';
    $Countries{'ARG'} = 'AR';
    $Countries{'CHN'} = 'CN';
    $Countries{'BRA'} = 'BR';
    $Countries{'CMR'} = 'CM';
    $Countries{'EGY'} = 'EG';
    $Countries{'TUN'} = 'TN';
    $Countries{'Mali'} = 'ML';
    $Countries{'India'} = 'IN';
    $Countries{'CHL'} = 'CL';
    $Countries{'TUN'} = 'TN';

## FINLAND ADDED ONES

$Countries{'AFGHA'} = "AF";
$Countries{'ALBAN'} = "AL";
$Countries{'ALGER'} = "DZ";
$Countries{'ANGOL'} = "AO";
$Countries{'AMERI'} = "US";
$Countries{'AUST'} = "AU";
$Countries{'AUSTR'} = "AT";
$Countries{'ARGEN'} = "AR";
$Countries{'BANGL'} = "BD";
$Countries{'BELAR'} = "BY";
$Countries{'BELGI'} = "BE";
$Countries{'BOLIV'} = "BO";
$Countries{'BOSNI'} = "BA";
$Countries{'BRAZI'} = "BR";
$Countries{'BRITI'} = "GB";
$Countries{'BULGA'} = "BG";
$Countries{'BURKI'} = "BF";
$Countries{'BURME'} = "BF";
$Countries{'CAMER'} = "CM";
$Countries{'CANAD'} = "CA";
$Countries{'CAPE '} = "CV";
$Countries{'CAPE'} = "CV";
$Countries{'CHILE'} = "CL";
$Countries{'CHINE'} = "CN";
$Countries{'COLOM'} = "CO";
$Countries{'CONGO'} = "CG";
$Countries{'COSTA'} = "CR";
$Countries{'CROAT'} = "HR";
$Countries{'CUBAN'} = "CU";
$Countries{'CYPRI'} = "CY";
$Countries{'CZECH'} = "CZ";
$Countries{'DANIS'} = "DK";
$Countries{'DUTCH'} = "NL";
$Countries{'ECUAD'} = "EC";
$Countries{'EGYPT'} = "EG";
$Countries{'EQUAT'} = "CQ";
$Countries{'ESTON'} = "EE";
$Countries{'ETHIO'} = "ET";
$Countries{'FRENC'} = "FR";
$Countries{'GUINE'} = "GN";
$Countries{'HERZE'} = "BA";
$Countries{'IRISH'} = "IE";
$Countries{'IVOIR'} = "CI";
$Countries{'PERUV'} = "PE";
$Countries{'POLIS'} = "PL";
$Countries{'SCOTTISH'} = "GN";
$Countries{'KOREA'} = "KR";

$Countries{'GAMBI'} = "GM";
$Countries{'GEORG'} = "GE";
$Countries{'GERMA'} = "DE";
$Countries{'GHANA'} = "GH";
$Countries{'GREEK'} = "GR";
$Countries{'GUYAN'} = "GY";
$Countries{'HONDU'} = "HN";
$Countries{'HUNGA'} = "HU";
$Countries{'INDON'} = "ID";
$Countries{'IRANI'} = "IR";
$Countries{'IRAQI'} = "IQ";
$Countries{'ISRAE'} = "IL";
$Countries{'ITALI'} = "IT";
$Countries{'JAMAI'} = "JM";
$Countries{'JAPAN'} = "JP";
$Countries{'JORDA'} = "JO";
$Countries{'KENYA'} = "KE";
$Countries{'LEBAN'} = "LB";
$Countries{'LIBER'} = "LR";
$Countries{'LITHU'} = "LT";
$Countries{'LUXEM'} = "LU";
$Countries{'MACED'} = "MK";
$Countries{'MEXIC'} = "MX";
$Countries{'MOLDO'} = "MD";
$Countries{'MONGO'} = "MN";
$Countries{'MOROC'} = "MA";
$Countries{'NAMIB'} = "NA";
$Countries{'NEPAL'} = "NP";
$Countries{'NEWZ'} = "NZ";
$Countries{'NICAR'} = "NI"; $Countries{'NIGER'} = "NE"; $Countries{'NIGERI'} = "NG"; $Countries{'NORWE'} = "NO";
$Countries{'PAKIS'} = "PK";
$Countries{'PARAG'} = "PY";
$Countries{'PORTU'} = "PT";
$Countries{'ROMAN'} = "RO";
$Countries{'RUSSI'} = "RU";
$Countries{'RWAND'} = "RW";
$Countries{'SENEG'} = "SN";
$Countries{'SERB'} = "RS";
$Countries{'SIERR'} = "SL";
$Countries{'SLOVE'} = "SI";
$Countries{'SOMAL'} = "SO";
$Countries{'SPANI'} = "ES";
$Countries{'SRIL'} = "LK";
$Countries{'SUDAN'} = "SD";
$Countries{'SWEDI'} = "SE";
$Countries{'SWISS'} = "CH";
$Countries{'SYRIA'} = "SY";
$Countries{'TANZA'} = "TZ";
$Countries{'THAI'} = "TH";
$Countries{'TOGOL'} = "TG";
$Countries{'TRINI'} = "TT";
$Countries{'TUNIS'} = "TN";
$Countries{'TURKI'} = "TR";
$Countries{'UGAND'} = "UG";
$Countries{'UKRAI'} = "UA";
$Countries{'URUGU'} = "UY";
$Countries{'VENEZ'} = "VE";
$Countries{'VIETN'} = "VN";
$Countries{'WALLI'} = "WF";
$Countries{'YEMEN'} = "YE";
$Countries{'ZAMBI'} = "ZM";


$Countries{'KOSOVA'} = "";
$Countries{'INDIA'} = "IN";
$Countries{'MAHOR'} = "";
$Countries{'SLOVA'} = "SK";
$Countries{'LATVI'} = "LV";
$Countries{'UZBEK'} = "UZ";
$Countries{'ERITR'} = "ER";
$Countries{'KYRGY'} = "KG";
$Countries{'MALAY'} = "MY";
$Countries{'Chechenian'} = "";
$Countries{'TAJIK'} = "TJ";
$Countries{'BENIN'} = "BJ";
$Countries{'FALKL'} = "FK";
$Countries{'TONGA'} = "TO";
$Countries{'ZIMBA'} = "ZW";
$Countries{'CAMBO'} = "KH";
$Countries{'DOMIN'} = "DM";
$Countries{'MALAW'} = "MW";
$Countries{'KAZAK'} = "KZ";
$Countries{'SOUTH'} = "";
$Countries{'ICELA'} = "IS";
$Countries{'PUERT'} = "PR";
$Countries{'TAIWA'} = "TW";
$Countries{'ARMEN'} = "AM";
$Countries{'MONTE'} = "ME";
$Countries{'GUATE'} = "GT";
$Countries{'AZERB'} = "AZ";
$Countries{'SAUDI'} = "SA";
$Countries{'MALTE'} = "MT";
$Countries{'PHILI'} = "PH";
$Countries{'EMIRA'} = "AE";
$Countries{'STVIN'} = "";
$Countries{'FIJIA'} = "";
$Countries{'GABON'} = "GA";
$Countries{'MALIA'} = "";
$Countries{'HAITI'} = "HT";
$Countries{'MOZAM'} = "MZ";
$Countries{'SINGA'} = "SG";
$Countries{'BVI'} = "";
$Countries{'SALVA'} = "";
$Countries{'NED'} = "";

    for my $field (@dbFields)   {
        my $st = qq[
            UPDATE tblPerson SET $field=? WHERE $field=? AND intRealmID=?
        ];
        my $qryField= $db->prepare($st);
        foreach my $key (keys %Countries)   {
            $qryField->execute(
                $Countries{$key}, 
                $key, 
                $Data{'Realm'}
            ); 
        }
    }
print "PERSON RECORDS DONE\n";

## Now do tblEntity
    @dbFields = qw(strContactISOCountry strISOCountry);

    for my $field (@dbFields)   {
        my $st = qq[
            UPDATE tblEntity SET $field=? WHERE $field=? AND intRealmID=?
        ];
        my $qryField= $db->prepare($st);
        foreach my $key (keys %Countries)   {
            $qryField->execute(
                $Countries{$key}, 
                $key, 
                $Data{'Realm'}
            ); 
        }
    }
print "ENTITY RECORDS DONE\n";
}
