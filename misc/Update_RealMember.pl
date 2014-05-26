#!/usr/bin/perl

#
# $Header: svn://svn/SWM/trunk/misc/rebuild_stats.pl 8250 2013-04-08 08:24:36Z rlee $
#

use lib "RegoForm";
use strict;
use lib '..','../web','../web/comp','../web/RegoForm','../web/courtside','../web/sportstats';
use Getopt::Long;
use Defs;
use Utils;
use Data::Dumper;
use Lang;
use DBUtils;
use Utils;
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
[   113937   ,   3461649 ],
#[   114078   ,   3462597 ],
#[   114081   ,   3462597 ],
#[   114089   ,   3462617 ],
#[   114092   ,   3462621 ],
#[   114094   ,   3462631 ],
#[   114108   ,   3462733 ],
#[   114109   ,   3462745 ],
#[   114112   ,   3462745 ],
#[   114166   ,   3462913 ],
#[   114209   ,   3463132 ],
#[   114211   ,   3463132 ],
#[   114213   ,   3463141 ],
#[   114275   ,   3463460 ],
#[   114277   ,   3463460 ],
);

for my $dataArray  (@dataset){
    $tempID =  $dataArray->[0];
    $logID = $dataArray->[1];
    warn "Temp:: $tempID--->  LOGID ::  $logID";


my $sql =qq[SELECT intFormID, strJson,intLevel,intAssocID, intClubID,strSessionKey, intTempMemberID,intRealID, intFormID,intTranslogID,TM.intStatus
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
    warn "Realm::". $Data{"Realm"};

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
    my ($intRealID,undef) = rego_addRealMember(\%Data,$db,$tempID,$session, $formObj) ;
    warn "REALmember ID: $intRealID";
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
