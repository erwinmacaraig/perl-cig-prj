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
