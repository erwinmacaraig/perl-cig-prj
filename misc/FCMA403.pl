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
use Data::Dumper;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
    my $originID = 19;
    my $originLevel = 3;
    my $pRegID = 1;
	$Data{'db'} = $db;
	$Data{'Realm'} = 1;
	$Data{'RealmSubType'} = 0;

    my $stINS = qq[
        INSERT INTO tblWFRule
        SET 
            intRealmID =1, 
            intSubRealmID = 0, 
            strWFRuleFor = 'REGO', 
            strEntityType = '', 
            strPersonType = 'COACH',  
            strTaskType = 'APPROVAL',
            strTaskStatus = 'PENDING',
            intOriginLevel = ?,
            intEntityLevel = ?,
            strRegistrationNature = ?,
            strPersonLevel = ?,
            strSport = ?,
            strAgeLevel = ?,
            intApprovalEntityLevel = ?,
            intProblemResolutionEntityLevel = ?,
            intCopiedFromRuleID = ?,
            strISOCountry_IN= ?,
            strISOCountry_NOTIN = ? 
    ];
    my $qINS= $db->prepare($stINS);

    my $stINS_PREREQ = qq[
        INSERT INTO tblWFRulePreReq
        (intWFRuleID, intPreReqWFRuleID)
        VALUES (?,?)
    ];
    my $qINS_PREREQ= $db->prepare($stINS_PREREQ);
    
    my $st = qq[
        SELECT
            *
        FROM
            tblWFRule
        WHERE
            intRealmID=1
            AND strWFRuleFor = 'REGO'
            AND strPersonType = 'COACH'
            AND strTaskStatus = 'ACTIVE'
            AND intOriginLevel IN (1,3, 20, 100)
            AND intEntityLevel IN (1,3)
    ];
    my $q= $db->prepare($st);
    $q->execute();

    my $stINSDOC = qq[
        INSERT INTO tblWFRuleDocuments
        (
            intWFRuleID, 
            intDocumentTypeID, 
            intAllowApprovalEntityAdd, 
            intAllowApprovalEntityVerify,
            intAllowProblemResolutionEntityAdd,
            intAllowProblemResolutionEntityVerify
        )
        SELECT 
            ?, 
            intDocumentTypeID,
            1,
            1,
            1,
            1
        FROM 
            tblWFRuleDocuments 
        WHERE 
            intWFRuleID = ?
    ];
    my $qINSDOC= $db->prepare($stINSDOC);


    ## Lets cleanup the Approval for ORIGIN = SELF
    my $stUPD = qq[
        UPDATE tblWFRule 
        SET 
            intApprovalEntityLevel = 3 
        WHERE  
            intRealmID=1             
            AND strWFRuleFor = 'REGO'             
            AND strPersonType = 'COACH'             
            AND strTaskStatus = 'ACTIVE'             
            AND intOriginLevel IN (1)             
            AND intEntityLevel=3
    ];
    $db->do($stUPD);


    ## Lets cleanup the Approval for ORIGIN = system and DESTINATION = CLUB
    $stUPD = qq[
        UPDATE tblWFRule 
        SET 
            intApprovalEntityLevel =20
        WHERE  
            intRealmID=1             
            AND strWFRuleFor = 'REGO'             
            AND strPersonType = 'COACH'             
            AND strTaskStatus = 'ACTIVE'             
            AND intOriginLevel IN (3,20,100)
            AND intEntityLevel=3
    ];
    $db->do($stUPD);
    
    while (my $dref = $q->fetchrow_hashref())   {
        
        if ($dref->{'intEntityLevel'} == 3 and $dref->{'intOriginLevel'} == 1) {
            $qINS->execute(
                $dref->{'intOriginLevel'}, 
                $dref->{'intEntityLevel'},
                $dref->{'strRegistrationNature'},
                $dref->{'strPersonLevel'},
                $dref->{'strSport'},
                $dref->{'strAgeLevel'},
                20,
                $dref->{'intOriginLevel'},
                $dref->{'intWFRuleID'},
                $dref->{'strISOCountry_IN'},
                $dref->{'strISOCountry_NOTIN'}
            );
            my $id20=  $qINS->{mysql_insertid} || 0;
            $qINS_PREREQ->execute($id20, $dref->{'intWFRuleID'});
            $qINSDOC->execute($id20, $dref->{'intWFRuleID'});

            $qINS->execute(
                $dref->{'intOriginLevel'}, 
                $dref->{'intEntityLevel'},
                $dref->{'strRegistrationNature'},
                $dref->{'strPersonLevel'},
                $dref->{'strSport'},
                $dref->{'strAgeLevel'},
                100,
                $dref->{'intOriginLevel'},
                $dref->{'intWFRuleID'},
                $dref->{'strISOCountry_IN'},
                $dref->{'strISOCountry_NOTIN'}
            );
            my $id100=  $qINS->{mysql_insertid} || 0;
            $qINS_PREREQ->execute($id100, $id20);
            $qINSDOC->execute($id100, $dref->{'intWFRuleID'});

        }

        if ($dref->{'intEntityLevel'} == 3 and $dref->{'intOriginLevel'} > 1) {
            $qINS->execute(
                $dref->{'intOriginLevel'}, 
                $dref->{'intEntityLevel'},
                $dref->{'strRegistrationNature'},
                $dref->{'strPersonLevel'},
                $dref->{'strSport'},
                $dref->{'strAgeLevel'},
                100,
                $dref->{'intOriginLevel'},
                $dref->{'intWFRuleID'},
                $dref->{'strISOCountry_IN'},
                $dref->{'strISOCountry_NOTIN'}
            );
            my $id100=  $qINS->{mysql_insertid} || 0;
            $qINS_PREREQ->execute($id100, $dref->{'intWFRuleID'});
            $qINSDOC->execute($id100, $dref->{'intWFRuleID'});
        }
    }

}
