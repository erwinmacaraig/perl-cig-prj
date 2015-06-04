package ImporterPersonRego;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    insertPersonRegoRecord
    linkPRNationalPeriods
    linkPRProducts
    linkPRPeople
    linkPRClubs
    importPRFile
);

use strict;
use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit', "../web/Clearances";

use Defs;
use DBI;
use Utils;
use ConfigOptions qw(ProcessPermissions);
use SystemConfig;
use CGI qw(cookie unescape);
use ImporterTXNs;
use ImporterCommon;

use Log;
use Data::Dumper;

############
#
# COMMENTS:
# - Waiting on your fixes of tblPerson.strImportPersonCode (ie: = SystemID)
# - Some logic needed in insertPersonRegoRecord() for ONLOAN and dtFrom =  dtTransferred etc and intOnLoan
# - Full list of INSERT and VALUE columns needed in insertPersonRegoRecord()
#
############

sub insertCertification {
    my ($db, $personID, $personRole, $dtFrom, $dtTo) = @_;

    ## From tblCertificationTypes
    my $maCode = getImportMACode($db) || '';

    $dtFrom ||= '';
    $dtTo ||= '';

    my %certs=();
    if ($maCode eq 'HKG')   {
        ## HKG Mapping
    }
    else    {
        ## Finland at moment
        $certs{'UEFAPRO'} = 1;
        $certs{'UEFAA'} = 2;
        $certs{'UEFAB'} = 3;

        $certs{'FAF'} = 33;
        $certs{'DISTRICT'} = 34;
    }

    my $certID = $certs{$personRole} || return;
    $personID || return;
    my $st = qq[
        INSERT INTO tblPersonCertifications (intPersonID, intRealmID, intCertificationTypeID, strStatus, dtValidFrom, dtValidUntil)
        VALUES (?,1,?,'ACTIVE', ?, ?)
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute($personID, $certID, $dtFrom , $dtTo);
}
    
sub insertPersonRegoRecord {
    my ($db) = @_;

    my $maCode = getImportMACode($db) || '';

    my $stINS = qq[
        INSERT INTO tblPersonRegistration_1 (
            intRealmID,
            dtAdded,
            dtApproved,
            dtLastUpdated,
            strImportPersonCode,
            intPersonID,
            intEntityID,
            intNationalPeriodID,
            strPersonType,
            strPersonLevel,
            strPersonEntityRole,
            strStatus,
            strSport,
            strAgeLevel,
            strRegistrationNature,
            dtFrom,
            dtTo,
            intIsLoanedOut,
            intOnLoan,
            tmpPaymentRef,
            tmpProductCode,
            tmpProductID,
            tmpAmount,
            tmpisPaid,
            tmpdtPaid
        )
        VALUES (
            1,
            NOW(),
            NOW(),
            NOW(),
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
    my $qryINS= $db->prepare($stINS) or query_error($stINS);

    my $st = qq[
        SELECT * FROM tmpPersonRego
    ];
print "\n WARNING: INSERT HAS BEEN LIMITED FOR TEST -- PLEASE REMOVE WHEN READY\n\n\n";
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        #next if (! $dref->{'intPersonID'} or ! $dref->{'intEntityID'} or ! $dref->{'intNationalPeriodID'});

        my $dtFrom = $dref->{'dtFrom'};
        my $dtTo   = $dref->{'dtTo'};
        my $onLoan = 0; 
        my $isLoanedOut= 0; 
        my $status = $dref->{'strStatus'};

        if ($dref->{'isLoan'} eq 'YES')    {
        #$status eq 'ONLOAN' and 
            $onLoan = 1;
            $dtTo = $dref->{'dtTransferred'};
            $status = 'PASSIVE'; ## We need to set current ones to active in import_loans script
        }
        if ($dref->{'dtTransferred'} and $dref->{'dtTransferred'} ne '0000-00-00')  {
            $dtTo = $dref->{'dtTransferred'};
        }
        my $personRole = $dref->{'strPersonRole'};
        if ($maCode eq 'HKG')   {
            ## Config here for HKG
        }
        else    {
            ## Finland at moment
            if ($dref->{'strPersonType'} eq 'COACH')    {
                ## INSERT INTO tblPersonCertifications or whatever its called -- need an IMPROT CODE
                insertCertification($db, $dref->{'intPersonID'}, $personRole, $dref->{'dtFrom'}, $dref->{'dtTo'});
                $personRole = ''; ## NEEDS CONFIRMATION
            }
            if ($dref->{'strPersonType'} eq 'REFEREE')    {
                insertCertification($db, $dref->{'intPersonID'}, $personRole, $dref->{'dtFrom'}, $dref->{'dtTo'});
                $personRole = '' if ($personRole eq 'FAF' or $personRole eq 'DISTRICT');
            }
        }

        
        $qryINS->execute(
            $dref->{'intID'},
            $dref->{'intPersonID'},
            $dref->{'intEntityID'},
            $dref->{'intNationalPeriodID'},
            $dref->{'strPersonType'},
            $dref->{'strPersonLevel'},
            $personRole,
            $status,
            $dref->{'strSport'},
            $dref->{'strAgeLevel'},
            $dref->{'strRegoNature'},
            $dtFrom,
            $dtTo,
            $isLoanedOut, 
            $onLoan,
            $dref->{'strTransactionNo'},
            $dref->{'strProductCode'},
            $dref->{'intProductID'},
            $dref->{'curProductAmount'},
            $dref->{'strPaid'},
            $dref->{'dtPaid'}
        );
        my $ID = $qryINS->{mysql_insertid} || 0;
        if ($dref->{'strProductCode'})  {
            my $st_up = qq[
                UPDATE tblPersonRegistration_1
                SET strShortNotes=CONCAT(IF(tmpPaymentRef, CONCAT(tmpPaymentRef, " "), ""), IF(tmpdtPaid, CONCAT(tmpdtPaid, " "), ""), tmpProductCode, " ",  tmpAmount, " ", tmpisPaid)
                WHERE intPersonRegistrationID = ?
            ];
            my $qry_up = $db->prepare($st_up) or query_error($st_up);
            $qry_up->execute($ID);
        }
    }
}
 sub linkPRNationalPeriods{
    my ($db) = @_;
    my $st = qq[
        SELECT intNationalPeriodID, strImportPeriodCode
        FROM tblNationalPeriod
        WHERE intRealmID=1 AND strImportPeriodCode<> ''
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $stUPD = qq[
            UPDATE tmpPersonRego
            SET intNationalPeriodID= ?
            WHERE strNationalPeriodCode= ?
        ];
        my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
        $qryUPD->execute(
            $dref->{'intNationalPeriodID'},
            $dref->{'strImportPeriodCode'} 
        );
    }

}


sub linkPRProducts {
    my ($db) = @_;
    my $st = qq[
        SELECT intProductID, strProductCode
        FROM tblProducts
        WHERE intRealmID=1 AND strProductCode <> ''
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $stUPD = qq[
            UPDATE tmpPersonRego
            SET intProductID= ?
            WHERE strProductCode = ?
        ];
        my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
        $qryUPD->execute(
            $dref->{'intProductID'},
            $dref->{'strProductCode'} 
        );
         my $stUPD2 = qq[
            UPDATE tmpPersonRego
            SET intProductID = ?
            WHERE
                CONCAT(strProductCode, strPersonType, strSport) = ?
                AND strSport <> ''
                AND strPersonType <> ''
        ];
         my $qryUPD2 = $db->prepare($stUPD2) or query_error($stUPD2);
        $qryUPD2->execute(
            $dref->{'intProductID'},
            $dref->{'strProductCode'}
        );
    }

}

sub linkPRPeople {
    my ($db) = @_;
    my $st = qq[
        SELECT intPersonID, strImportPersonCode
        FROM tblPerson
        WHERE strImportPersonCode <> ''
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $stUPD = qq[
            UPDATE tmpPersonRego
            SET intPersonID = ?
            WHERE strPersonCode = ?
        ];
        my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
        $qryUPD->execute(
            $dref->{'intPersonID'},
            $dref->{'strImportPersonCode'} 
        );
    }
}


sub linkPRClubs {
    my ($db) = @_;
    my $st = qq[
        SELECT intEntityID, strImportEntityCode
        FROM tblEntity
        WHERE strImportEntityCode <> ''
    ];
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    while (my $dref= $qry->fetchrow_hashref())    {
        my $stUPD = qq[
            UPDATE tmpPersonRego
            SET intEntityID = ?
            WHERE strEntityCode = ?
        ];
        my $qryUPD = $db->prepare($stUPD) or query_error($stUPD);
        $qryUPD->execute(
            $dref->{'intEntityID'},
            $dref->{'strImportEntityCode'} 
        );
    }
}


sub importPRFile  {
    my ($db, $countOnly, $type, $infile) = @_;
    
    my $maCode = getImportMACode($db) || '';

open INFILE, "<$infile" or die "Can't open Input File";

my $count = 0;
                                                                                                        
seek(INFILE,0,0);
$count=0;
my $insCount=0;
my $NOTinsCount = 0;

my %cols = ();
my $stDEL = "DELETE FROM tmpPersonRego WHERE strFileType = ?";
my $qDEL= $db->prepare($stDEL) or query_error($stDEL);
$qDEL->execute($type);

while (<INFILE>)	{
	my %parts = ();
	$count ++;
	next if $count == 1;
	chomp;
	my $line=$_;
	$line=~s///g;
	#$line=~s/,/\-/g;
	$line=~s/"//g;
	my @fields=split /;/,$line;

    #:PersonCode;OrganisationCode;Status;RegistrationNature;PersonType;Role;Level;Sport;AgeLevel;DateFrom;DateTo;Transferred;IsLoan;NationalSeason;ProductCode;Amount;IsPaid;PaymentReference
    if ($maCode eq 'HKG')   {
        ## Update field mapping for HKG 
    }
    else    {
        ## Finland at moment
    	$parts{'PERSONCODE'} = $fields[0] || '';
	    $parts{'ENTITYCODE'} = $fields[1] || '';
	    $parts{'STATUS'} = $fields[2] || '';
	    $parts{'REGNATURE'} = $fields[3] || '';
	    $parts{'PERSONTYPE'} = $fields[4] || '';
	    $parts{'PERSONROLE'} = $fields[5] || '';
	    $parts{'PERSONLEVEL'} = $fields[6] || '';
	    $parts{'SPORT'} = $fields[7] || '';
	    $parts{'AGELEVEL'} = $fields[8] || '';
	    $parts{'DATEFROM'} = $fields[9] || '0000-00-00';
	    $parts{'DATETO'} = $fields[10] || '0000-00-00';
	    $parts{'DATETRANSFERRED'} = $fields[11] || '0000-00-00';
	    $parts{'ISLOAN'} = $fields[12] || '';
	    $parts{'NATIONALPERIOD'} = $fields[13] || '';
	    $parts{'PRODUCTCODE'} = $fields[14] || '';
	    $parts{'PRODUCTAMOUNT'} = $fields[15] || 0;
	    $parts{'ISPAID'} = $fields[16] || '';
	    $parts{'TRANSACTIONNO'} = ''; #$fields[17] || '';
	    $parts{'DATEPAID'} = $fields[17] || '';
        
        $parts{'AGELEVEL'} = 'ADULT' if $parts{'AGELEVEL'} eq 'SENIOR';
        $parts{'PERSONTYPE'} = 'MAOFFICIAL' if $parts{'PERSONTYPE'} eq 'MA OFFICIAL';
        $parts{'PERSONTYPE'} = 'RAOFFICIAL' if $parts{'PERSONTYPE'} eq 'RA OFFICIAL';
        if ($parts{'PERSONTYPE'} eq 'MAOFFICIAL')    {
            $parts{'PERSONROLE'} = 'MAREFOBDIST' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER DISTRICT';
            $parts{'PERSONROLE'} = 'MAREFOBFAF' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER FAF';
        }
        if ($parts{'PERSONTYPE'} eq 'RAOFFICIAL')    {
            $parts{'PERSONROLE'} = 'RAREFOBDIST' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER DISTRICT';
            $parts{'PERSONROLE'} = 'RAREFOBFAF' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER FAF';
        }
        
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpPersonRego
		(strFileType, strPersonCode, strEntityCode, strStatus, strRegoNature, strPersonType, strPersonRole, strPersonLevel, strSport, strAgeLevel, dtFrom, dtTo, dtTransferred, isLoan, strNationalPeriodCode, strProductCode, curProductAmount, strPaid, strTransactionNo, dtPaid)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
	];
	my $query = $db->prepare($st) or query_error($st);
 	$query->execute(
        $type,
        $parts{'PERSONCODE'},
	    $parts{'ENTITYCODE'},
        $parts{'STATUS'},
        $parts{'REGNATURE'},
        $parts{'PERSONTYPE'},
        $parts{'PERSONROLE'},
        $parts{'PERSONLEVEL'},
        $parts{'SPORT'},
        $parts{'AGELEVEL'},
        $parts{'DATEFROM'},
        $parts{'DATETO'},
        $parts{'DATETRANSFERRED'},
        $parts{'ISLOAN'},
        $parts{'NATIONALPERIOD'},
        $parts{'PRODUCTCODE'},
        $parts{'PRODUCTAMOUNT'},
        $parts{'ISPAID'},
        $parts{'TRANSACTIONNO'},
        $parts{'DATEPAID'}
    ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
