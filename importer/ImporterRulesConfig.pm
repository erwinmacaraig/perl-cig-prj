package ImporterRulesConfig;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    importRulesConfigFile
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);
use ImporterCommon;

use Log;
use Data::Dumper;

sub runRulesConfig  {
    my ($db) = @_:

    my $stDEL = "DELETE FROM tblWFRule";
    my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute();
    $stDEL = "DELETE FROM tblWFRuleDocuments";
    $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute();
    $stDEL = "DELETE FROM tblWFRulePreReq";
    $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute();

    my $st_INS_RULE = qq[
        INSERT INTO tblWFRule
            (
                intRealmID,
                intSubRealmID,
                intOriginLevel,
                strWFRuleFor,
                strEntityType,
                intEntityLevel,
                strRegistrationNature,
                strPersonType,
                strPersonLevel,
                strSport,
                strAgeLevel,
                intApprovalEntityLevel,
                intProblemResolutionEntityLevel,
                strTaskType,
                strTaskStatus,
                intRemoveTaskOnPayment,
                intLockTaskUntilGatewayResponse,
                intLockTaskUntilPaid,
                intAutoActivateOnPayment,
                strPersonEntityRole,
                strISOCountry_IN,
                strISOCountry_NOTIN,
                intUsingITCFilter,
                intNeededITC,
                intCopiedFromRuleID,
                intUsingPersonLevelChangeFilter,
                intPersonLevelChange,
                intDocumentTypeID
            )
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                0
            )
                
    ];
    my $qINS_RULE= $db->prepare($st_INS_RULE) or query_error($st_INS_RULE);

    my $st_INS_PREREQ = qq[
        INSERT INTO tblWFRulePreReq
        (intWFRuleID, intPreReqWFRuleID)
        VALUES (?, ?) 
    ];
    my $qINS_PREREQ= $db->prepare($st_INS_PREREQ) or query_error($st_INS_PREREQ);

    my $st = qq[
        SELECT * FROM _tblRuleConfig
        ORDER BY intRuleConfigID
    ];
    my $q= $db->prepare($st) or query_error($st);
    $q->execute();

    my $lastRuleID = 0;
    my $count = 0;
    while (my $dref = $q->fetchrow_hashref())   {

       $qINS_RULE->execute(
            $dref->{'intRealmID'},
            $dref->{'intSubRealmID'},
            $dref->{'intOriginLevel'},
            $dref->{'strWFRuleFor'},
            $dref->{'strEntityType'},
            $dref->{'intEntityLevel'},
            $dref->{'strRegistrationNature'},
            $dref->{'strPersonType'},
            $dref->{'strPersonLevel'},
            $dref->{'strSport'},
            $dref->{'strAgeLevel'},
            $dref->{'intApprovalEntityLevel'},
            $dref->{'intProblemResolutionEntityLevel'},
            $dref->{'strTaskType'},
            $dref->{'strTaskStatus'},
            $dref->{'intRemoveTaskOnPayment'},
            $dref->{'intLockTaskUntilGatewayResponse'},
            $dref->{'intLockTaskUntilPaid'},
            $dref->{'intAutoActivateOnPayment'},
            $dref->{'strPersonEntityRole'},
            $dref->{'strISOCountry_IN'},
            $dref->{'strISOCountry_NOTIN'},
            $dref->{'intUsingITCFilter'},
            $dref->{'intNeededITC'},
            $dref->{'intCopiedFromRuleID'},
            $dref->{'intUsingPersonLevelChangeFilter'},
            $dref->{'intPersonLevelChange'}
        );


        my $ID = $qINS_RULE->{mysql_insertid} || 0;
        
        if ($dref->{'strTaskStatus'} eq 'PENDING')  {
            $qINS_PREREQ->execute(
                $ID,
                $lastRuleID
            );
        }
        $count++;
        $lastRuleID = $ID;

    }

    print "RULES INSERTED: $count\n";
}
    
sub importRulesConfigFile {
    my ($db, $countOnly, $infile) = @_;
    
    open INFILE, "<$infile" or die "Can't open Input File";

    my $count = 0;
                                                                                                            
    seek(INFILE,0,0);
    $count=0;
    my $insCount=0;
    my $NOTinsCount = 0;

    my %cols = ();
    my $stDEL = "DELETE FROM _tblRuleConfig";
    my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
    $qDEL->execute();

    while (<INFILE>)	{
        my %parts = ();
        $count ++;
        next if $count == 1;
        chomp;
        my $line=$_;
        $line=~s///g;
        #$line=~s/,/\-/g;
        $line=~s/"//g;
    #	my @fields=split /;/,$line;
        my @fields=split /\t/,$line;

        $parts{'ORIGIN_LEVEL'} = $fields[0] || 0;
        $parts{'RULEFOR'} = $fields[1] || '';
        $parts{'ENTITY_LEVEL'} = $fields[2] || 0;
        $parts{'REGONATURE'} = $fields[3] || '';
        $parts{'PERSONTYPE'} = $fields[4] || '';
        $parts{'LEVEL'} = $fields[5] || '';
        $parts{'SPORT'} = $fields[6] || '';
        $parts{'AGE'} = $fields[7] || '';
        $parts{'APPROVAL_LEVEL'} = $fields[8] || 0;
        $parts{'REJECT_LEVEL'} = $fields[9] || 0;
        $parts{'TASK_TYPE'} = $fields[10] || '';
        $parts{'TASK_STATUS'} = $fields[11] || '';
        $parts{'REMOVE_ON_PAYMENT'} = $fields[12] || 0;
        $parts{'LOCK_UNTIL_GATEWAYRESPONSE'} = $fields[13] || 0;
        $parts{'LOCK_UNTIL_PAID'} = $fields[14] || 0;
        $parts{'AUTO_ACTIVATE_ON_PAID'} = $fields[15] || 0;
        $parts{'ENTITYROLE'} = $fields[16] || '';
        $parts{'NATIONALITY_IN'} = $fields[17] || '';
        $parts{'NATIONALITY_NOTIN'} = $fields[18] || '';
        $parts{'USING_ITC_FILTER'} = $fields[19] || 0;
        $parts{'ITC_FLAG'} = $fields[20] || 0;
        $parts{'USING_CHANGELEVEL_FILTER'} = $fields[21] || 0;
        $parts{'CHANGELEVEL_FLAG'} = $fields[22] || 0;

        if (! $parts{'RULEFOR'} or ! $parts{'REGONATURE'}) { next; }
        if ($countOnly)	{
            $insCount++;
            next;
        }

        my $st = qq[
            INSERT INTO _tblRuleConfig
            (
                intRealmID,
                intSubRealmID,
                intOriginLevel,
                strWFRuleFor,
                strEntityType,
                intEntityLevel,
                strRegistrationNature,
                strPersonType,
                strPersonLevel,
                strSport,
                strAgeLevel,
                intApprovalEntityLevel,
                intProblemResolutionEntityLevel,
                strTaskType,
                strTaskStatus,
                intRemoveTaskOnPayment,
                intLockTaskUntilGatewayResponse,
                intLockTaskUntilPaid,
                intAutoActivateOnPayment,
                strPersonEntityRole,
                strISOCountry_IN,
                strISOCountry_NOTIN,
                intUsingITCFilter,
                intNeededITC,
                intCopiedFromRuleID,
                intUsingPersonLevelChangeFilter,
                intPersonLevelChange
            )
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?
            )
                
        ];
        my $query = $db->prepare($st) or query_error($st);
        $query->execute(
            1,
            0,
            $parts{'ORIGIN_LEVEL'},
            $parts{'RULEFOR'},
            '',
            $parts{'ENTITY_LEVEL'},
            $parts{'REGONATURE'},
            $parts{'PERSONTYPE'},
            $parts{'LEVEL'},
            $parts{'SPORT'},
            $parts{'AGE'},
            $parts{'APPROVAL_LEVEL'},
            $parts{'REJECT_LEVEL'},
            $parts{'TASK_TYPE'},
            $parts{'TASK_STATUS'},
            $parts{'REMOVE_ON_PAYMENT'},
            $parts{'LOCK_UNTIL_GATEWAYRESPONSE'},
            $parts{'LOCK_UNTIL_PAID'},
            $parts{'AUTO_ACTIVATE_ON_PAID'},
            $parts{'ENTITYROLE'},
            $parts{'NATIONALITY_IN'},
            $parts{'NATIONALITY_NOTIN'},
            $parts{'USING_ITC_FILTER'},
            $parts{'ITC_FLAG'},
            0,
            $parts{'USING_CHANGELEVEL_FILTER'},
            $parts{'CHANGELEVEL_FLAG'}
        ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
