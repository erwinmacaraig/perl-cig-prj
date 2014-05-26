#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/rebuild_stats.pl 8250 2013-04-08 08:24:36Z rlee $
#

#use lib "RegoForm";
use strict;
use lib '..','../web','../web/comp','../web/RegoForm','../web/courtside','../web/sportstats',"../web/SMS","../web/dashboard", '../web/gendropdown';
use Getopt::Long;
use Defs;
use Utils;
use Data::Dumper;
use Lang;
use DBUtils;
use Payments;
use SystemConfig;
use ConfigOptions;
use Reg_common;
use Products;
use Gateway_Common;
use RegoForm_MemberFunctions qw(rego_addRealMember);
use RegoForm_TeamFunctions qw(rego_addRealTeam);
use RegoForm::RegoFormFactory;


my %Data=();
my $db = connectDB();
$Data{db} = $db;

#Temp:: 63603 TransLog:: 3198347 REAL :: 163569
#Temp:: 82847 TransLog : 3303555 REAL :: 0
my $assoc;
my $tempID;
my $logID;
my $formID; 
my $clubID = 0;
my $RegoType;
my $intRealID;
my $json;
my @dataset;

@dataset =(
[128220,3540344],
[129492,3547713],
[129502,3547835],

[129511,3547899],
[129534,3548006],
[129535,3548009],

[129536,3548017],
[129537,3548019],
[129538,3548029],
[129542,3548074],
[129543,3548079],
[129547,3548098],
[129548,3548110],
[129549,3548134],
[129565,3548228],
[129574,3548254],
[129578,3548280],
[129580,3548296],
[129585,3548314],
[129588,3548339],

[129591,3548352],
[129592,3548359],
[129601,3548437],
[129605,3548442],
[129611,3548465],
[129616,3548494],
[129620,3548509],
[129630,3548542],
[129632,3548578],
[129639,3548608],
[129640,3548610],
[129643,3548631],
[129659,3548695],
[129662,3548704],
[129664,3548707],
[129669,3548723],
[129673,3548733],
[129675,3548743],
[129678,3548758],

[129681,3548777],
[129682,3548781],
[129689,3548815],
[129699,3548880],
[129700,3548893],

[129701,3548894],
[129727,3549007],
[129732,3549021],
[129745,3549102],
[129746,3549110],
[129762,3549157],
[129775,3549205],

[129781,3549230],
[129782,3549239],
[129782,3549239],

[129795,3549326],
[129797,3549345],
[129826,3549736],
[129829,3549740],
[129833,3549749],

[129835,3549782],
[129854,3549918],
[129857,3549938],
[129864,3549977],
[129869,3550007],
[129892,3550129],
[129932,3550410],
[129938,3550515],

[129939,3550546],
[129950,3550720],
[129960,3550804],
[129967,3550872],
[129984,3551045],
[129988,3551063],

[129997,3551114],

[130000,3551150],

[130004,3551176],
[130005,3551177],

[130008,3551224],
[130009,3551225],

[130013,3551233],

[130021,3551270],

[130031,3551298],
[130042,3551365],
[130060,3551484],
[130063,3551503],
[130072,3551601],

[130074,3551604],
[130084,3551689],
[130092,3551722],
[130095,3551731],
[130096,3551732],

[130106,3551773],
[130123,3551981],
[130144,3552310],
[130153,3552451],
[130187,3552692],
[130189,3552697],


[130199,3552758],

[130206,3552822],
[130209,3552838],
[130244,3553166],
[130246,3553175],
[130250,3553238],
[130250,3553238],
[130255,3553255],

[130267,3553399],
[130269,3553412],

[130275,3553452],
[130276,3553459],
[130276,3553459],

[130281,3553473],
[130288,3553543],

[130297,3553674],
[130306,3553807],

[130326,3554042],
[130333,3554084],
[130364,3554289],
[130379,3554378],
[130388,3554444],
[130431,3554706],
[130450,3554834],

[130458,3554908],

[130469,3554997],

[130477,3555050],
[130485,3555180],

[130488,3555201],
[130526,3555545],
[130595,3556005],

[130631,3556252],
[130662,3556417],
[130680,3556463],

[130687,3556510],
[130738,3556870],
[130754,3556964],
[130763,3557020],
[130764,3557023],
[130791,3557203],
[130796,3557278],
[130802,3557318],
[130809,3557376],
[130811,3557381],
[130819,3557454],
[130830,3557534],
[130841,3557590],
[130885,3557928],
[130900,3558038],
[130901,3558046],
[130940,3558297],
[130942,3558302],
[130964,3558557],
[130973,3558643],
[130990,3558804],
[131011,3559064],
[131018,3559099],
[131028,3559212],
[131054,3559439],
[131058,3559487],
[131061,3559494],
[131069,3559588],
[131074,3559608],
[131078,3559706],
[131083,3559773],
[131103,3560019],
[131109,3560089],
[131122,3560151],
[131137,3560270],
[131142,3560284],
[131192,3560734],
[131205,3560862],
[131213,3560903],
[131228,3561009],
[131269,3561467],
[131298,3561695],
[131353,3562096],
[131369,3562263],
[131391,3562402],
[131392,3562408],
[131447,3563057],
[131451,3563083],
[131463,3563248],
[131476,3563362],
[131503,3563799],
);
for my $dataArray  (@dataset){
    $tempID =  $dataArray->[0];
    $logID = $dataArray->[1];
    warn "Temp:: $tempID--->  LOGID ::  $logID";


my $sql =qq[SELECT intFormID, strJson,intLevel,intAssocID, intClubID,strSessionKey, intTempMemberID,intRealID, intFormID,intTranslogID,intTeamID,TM.intStatus
            FROM tblTempMember as TM 
            where 
            intTempMemberID = ?
];
my $q = $db->prepare($sql);
$q->execute($tempID);

while (my $href = $q->fetchrow_hashref()) {
    $RegoType = $href->{intLevel};
    $intRealID = $href->{intRealID};
    $json = $href->{strJson};
    my $j = new JSON;
    my $deserial = JSON::from_json($json);

    my @params = $deserial->{'afteraddParams'};
    my $hash = $params[0];
    my $client =  $hash->{'client'};
    
    $assoc = $href->{'intAssocID'};
    $clubID = $href->{'intClubID'};
    $formID = $href->{'intFormID'};
    $Data{'formID'} = $formID;
    warn "assoc :: $assoc";
    warn "Club :: $clubID";

    my $lang= Lang->get_handle() || ''; #die "Can't get a language handle!";
    $Data{'lang'}=$lang;
    my %clientValues = getClient($client);
    $clientValues{'assocID'} = $assoc;
    $clientValues{'clubID'} = $clubID;
    $Data{'client'}=$client;
    $Data{'spAssocID'} = $assoc;
    $Data{'spClubID'} = $clubID;

    $Data{'clientValues'} = \%clientValues;
    my $realm;
    my $st = qq[
                SELECT intRealmID FROM tblAssoc WHERE intAssocID = ?
           ];
    my $qry= $db->prepare($st);
    $qry->execute($assoc);
    $realm = $qry->fetchrow_array() || 0;
    $Data{'Realm'}= $realm;

    getDBConfig(\%Data);
    $Data{'SystemConfig'}=getSystemConfig(\%Data);
    my $paymentSettings = getPaymentSettings(\%Data,0);
    
    $Data{'SystemConfig'}{'PaymentConfigID'} = $Data{'SystemConfig'}{'PaymentConfigUsedID'} ||  $Data{'SystemConfig'}{'PaymentConfigID'};
    #print STDERR Dumper(\%Data);
    my $formObj = getRegoFormObj(
            $formID,
            \%Data,
            $Data{'db'},
        );
    $Data{'RealmSubType'} = $formObj->{'DBData'}{'intSubRealmID'}; 
    $formObj->{'clientValues'}{'assocID'} = $assoc;
    my $session = $href->{strSessionKey} ;
    #print STDERR Dumper($formObj);
    my ($intRealID,undef) = rego_addRealTeam(\%Data,$db,$tempID,$session, $formObj) ;
    warn "REAL Team ID: $intRealID";
    my $st_update_temp = qq[
                UPDATE
                    tblTempMember
                SET
                    intRealID = ?,
                    intStatus = ?,
                    intTransLogID = ?
                 WHERE
                    intTempMemberID =?
                ];
     my $st_update_session = qq[
                UPDATE
                    tblRegoFormSession
                SET
                    intMemberID = ?
                 WHERE
                    intTempID =?
                ];
    my $st_update = qq[
                    UPDATE tblTransactions
                    SET
                        intID = ?
                    WHERE
                        intTempID = ?
                    ];
            # update transaction table
    my $update_qry = $db->prepare($st_update) or query_error($st_update);
    $update_qry->execute($intRealID,$tempID);

            # keep  the RealID and intTransLogID  in temp table
    $update_qry = $db->prepare($st_update_temp) or query_error($st_update_temp);

    $update_qry->execute($intRealID,1,$logID,$tempID);

    $update_qry = $db->prepare($st_update_session) or query_error($st_update_session);
    $update_qry->execute($intRealID,$tempID);

    #update_real_member($assoc,$db,$deserial,$intRealID);
    product_apply_transaction(\%Data,$logID);
    EmailPaymentConfirmation(\%Data, $paymentSettings, $logID, $client);

}#end of while
}#end of for
print "\nCompleted\n\n";

sub update_real_member {
    my ($assocID,$db, $input_array,$intRealID) = @_;
    my ( @values, @values_placeholder ) = ();
    my $valuelist ='';
    my $fieldlist ='';
     while (my ($key, $value) = each(%$input_array)) {
        next if $key eq 'afteraddParams';
        $valuelist.=',' if $valuelist;
        $fieldlist.=',' if $fieldlist;
        $fieldlist.= $key;
        $valuelist.=$db->quote($value);
    }
     my $placeholders = join( ", ", @values_placeholder );

    #print STDERR Dumper(\@values);
    #print $placeholders;
    my $st = qq[
            UPDATE tblMember, tblMember_Associations
            SET --VAL--
            WHERE tblMember.intMemberID=$intRealID
                AND tblMember_Associations.intMemberID=$intRealID
                AND tblMember_Associations.intAssocID=$assocID
                AND tblMember.intStatus != -1
            ];
    $st =~ s/--VAL--/$placeholders/;
#    warn $st;
#    my $query = exec_sql( $st, @values );
    if ($DBI::err) {
                return ( 0,
                       '<div class="warningmsg"></div>' );
            }
     else {
    }
    return 1;
}
sub usage {
    my $error = shift;
    print "\nERROR:\n";
    print "\t$error\n";
    print "\tusage:./Stats_SG.pl --realm realm_id --assoc assoc_id --comp comp_id\n\n";
    exit;
}
