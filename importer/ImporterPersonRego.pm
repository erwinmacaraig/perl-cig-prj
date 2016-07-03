package ImporterPersonRego;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    insertPersonRegoRecord
    linkPRNationalPeriods
    linkPRProducts
    linkPRPeople
    linkPRClubs
    linkEntityTypeRoles
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
use NationalReportingPeriod;

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
        $certs{'HKFA D Coaching Certificate'} = 61;
        $certs{'AFC C Coaching Certificate'} = 57;
        $certs{'Class 1 Referee'} = 39;
        $certs{'Class 3 Referee'} = 41;
        $certs{'Class 2 Referee'} = 40;
        $certs{'HKFA Youth Football Leader Certificate Level 2'} = 64;
        #$certs{'HKFA Goalkeeper Trainer'} = ;
        $certs{'New Referee'} = 42;
        #$certs{'AFC Goalkeeper Coaching Certificate Level 1'} = ;
        $certs{'AFC B Coaching Certificate'} = 56;
        $certs{'HKFA Futsal Coaching Certificate'} = 62;
        $certs{'HKFA Youth Football Leader Certificate Level 1'} = 64;
        $certs{'AFC A Coaching Certificate'} = 55;
        $certs{'AFC Futsal Coaching Certificate Level 1'} = 58;
        $certs{'AFC Pro Diploma Coaching Certificate'} = 54;
        #$certs{'AFC Fitness Coaching Certificate Level 1'} = ;
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
            intOriginLevel,
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
            100,
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

    my $orderBy;
    my $selectWeight;
    if ($maCode eq 'HKG')   {
        $selectWeight = qq[, IF(strStatus = 'ACTIVE', 2, 1) AS statusWeight];
        $orderBy = qq[ ORDER BY intPersonID, statusWeight DESC ];
    }
    if ($maCode eq 'GHA' or $maCode eq 'AZE')   {
    #    $selectWeight = qq[, IF(strStatus = 'ACTIVE', 2, 1) AS statusWeight];
        $orderBy = qq[ ORDER BY dtFrom ASC, dtTo ASC];
    #    $orderBy = qq[ ORDER BY intPersonID, statusWeight DESC ];
    }

    my $st = qq[
        SELECT
            *
            $selectWeight
        FROM
            tmpPersonRego
        $orderBy
    ];
#print "\n WARNING: INSERT HAS BEEN LIMITED FOR TEST -- PLEASE REMOVE WHEN READY\n\n\n";
    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
    my %existingRecord;

    while (my $dref= $qry->fetchrow_hashref())    {
        #next if (! $dref->{'intPersonID'} or ! $dref->{'intEntityID'} or ! $dref->{'intNationalPeriodID'});
        $dref->{'strRegoNature'} = uc($dref->{'strRegoNature'});

        my $dtFrom = $dref->{'dtFrom'};
        my $dtTo   = $dref->{'dtTo'};
        my $onLoan = 0; 
        my $isLoanedOut= 0; 
        my $status = $dref->{'strStatus'};

        if ($dref->{'strRegoNature'} eq 'LOAN' or $dref->{'isLoan'} eq 'YES')    {
        #$status eq 'ONLOAN' and 
            $onLoan = 1;
            #$dtTo = $dref->{'dtTransferred'};
            $status = 'PASSIVE'; ## We need to set current ones to active in import_loans script
        }
        if (uc($dref->{'strRegoNature'}) eq 'BACK LOAN')    {
            $isLoanedOut=1;
            $dref->{'strRegoNature'} = 'NEW';
        }
        if ($dref->{'dtTransferred'} and $dref->{'dtTransferred'} ne '0000-00-00')  {
            $dtTo = $dref->{'dtTransferred'};
        }
        my $personRole = $dref->{'strPersonRole'};
        if ($maCode eq 'HKG')   {
            ## Config here for HKG
            my $certification = $dref->{'strCertifications'};
            $certification =~ s/^\s+//;
            $certification =~ s/\s+$//;

            if($certification ne 'AFC Goalkeeper Coaching Certificate Level 1') {
                insertCertification($db, $dref->{'intPersonID'}, $certification, $dref->{'dtFrom'}, $dref->{'dtTo'});
            }

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

        my $ID = 0;
        my $personLevel = $dref->{'strPersonLevel'} || "_PERSON_LEVEL_";

        if($maCode eq 'HKG'
                and !$existingRecord{$dref->{'intPersonID'}}{$dref->{'strPersonType'}}{$dref->{'strSport'}}{$personLevel}{$dref->{'intNationalPeriodID'}}
        ) {
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
            $ID = $qryINS->{mysql_insertid} || 0;
            $existingRecord{$dref->{'intPersonID'}}{$dref->{'strPersonType'}}{$dref->{'strSport'}}{$personLevel}{$dref->{'intNationalPeriodID'}} = $ID;
        }
        elsif($maCode ne 'HKG') {
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
            $ID = $qryINS->{mysql_insertid} || 0;       
        }

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

    print STDERR Dumper $existingRecord{'370'};
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

sub linkEntityTypeRoles {
    my ($db) = @_;

    my $st = qq[
        UPDATE tmpPersonRego
        INNER JOIN tblEntityTypeRoles on tblEntityTypeRoles.strEntityRoleName = tmpPersonRego.strPersonRole 
        SET tmpPersonRego.strPersonRole = tblEntityTypeRoles.strEntityRoleKey;
    ];

    my $qry = $db->prepare($st) or query_error($st);
    $qry->execute();
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

my %existingNationalPeriod = ();
while (<INFILE>)	{
	my %parts = ();
	$count ++;
	next if $count == 1;
	chomp;
	my $line=$_;
	$line=~s///g;
	#$line=~s/,/\-/g;
	$line=~s/"//g;
	#my @fields=split /;/,$line;
	my @fields=split /\t/,$line;

    #:PersonCode;OrganisationCode;Status;RegistrationNature;PersonType;Role;Level;Sport;AgeLevel;DateFrom;DateTo;Transferred;IsLoan;NationalSeason;ProductCode;Amount;IsPaid;PaymentReference
    if ($maCode eq 'HKG')   {
        $fields[0] = "MAOFFICIAL" if $fields[0] eq 'MA Official';
        $fields[0] = "TEAMOFFICIAL" if $fields[0] eq 'Team Official';
        $fields[0] = "CLUBOFFICIAL" if $fields[0] eq 'Club Official';
        $fields[0] = "PLAYER" if $fields[0] eq 'Player';
        $fields[0] = "COACH" if $fields[0] eq 'Coach';
        $fields[0] = "REFEREE" if $fields[0] eq 'Referee';

        $fields[1] = "MAREFASSESSOR" if $fields[1] eq 'Referee Assessor';
        $fields[1] = "MABALLBOY" if $fields[1] eq 'Ballboy';
        $fields[1] = "MADUTYOFCR" if $fields[1] eq 'Duty Officer';
        $fields[1] = "MAGRNDSTAFF" if $fields[1] eq 'Ground Staff';
        $fields[1] = "MASELLER" if $fields[1] eq 'Seller';
        $fields[1] = "MAOFFICIAL" if $fields[1] eq 'Supervisor';

        $fields[13] = "ACTIVE" if $fields[13] eq 'Active';
        $fields[13] = "PASSIVE" if $fields[13] eq 'Passive';

        $fields[15] = "NEW" if $fields[15] eq 'New';
        $fields[15] = "RENEWAL" if $fields[15] eq 'Renewal';
        $fields[15] = "TRANSFER" if $fields[15] eq 'Transfer';

        $fields[16] = "AMATEUR" if $fields[16] eq 'Amateur';
        $fields[16] = "PROFESSIONAL" if $fields[16] eq 'Professional';

        $fields[17] = "FOOTBALL" if $fields[17] eq 'Football';
        $fields[17] = "FUTSAL" if $fields[17] eq 'Futsal';
        $fields[17] = "WOMENSFOOTBALL" if $fields[17] eq 'Women\'s Football';

        $fields[18] = "ADULT" if $fields[18] eq 'senior';
        $fields[18] = "MINOR" if $fields[18] eq 'minor';

        if($fields[19] and $fields[20]) {
            my @dtFrom = split("\/", $fields[19]);
            my @dtTo = split("\/", $fields[20]);

            $fields[19] = (scalar(@dtFrom)) ? $dtFrom[2] . '-' . $dtFrom[0] . '-' . $dtFrom[1] : $fields[19];
            $fields[20] = (scalar(@dtTo)) ? $dtTo[2] . '-' . $dtTo[0] . '-' . $dtTo[1] : $fields[20];
        }

        #print STDERR Dumper @fields;
        my $natPeriod = '';
        my $sportFill = (!$fields[17] || $fields[0] eq 'MAOFFICIAL' || $fields[0] eq 'CLUBOFFICIAL') ? '_SPORT_' : $fields[17];
        my $sport = ($sportFill eq '_SPORT_') ? '' : $fields[17];

        if($fields[21]) {
            my @nationalPeriod = split('-', $fields[21]);

            if(! $existingNationalPeriod{$nationalPeriod[0]}{$sportFill}) {
                my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($db, 1, 0, $sport, $fields[0], $fields[15]);
                $existingNationalPeriod{$nationalPeriod[0]}{$sportFill} = $nationalPeriodID;
                $natPeriod = $nationalPeriodID;
            } else {
                $natPeriod = $existingNationalPeriod{$nationalPeriod[0]}{$sportFill};
            }
        }

        #Person;Role;Code;Organization ID;Level;Status;Current;RegistrationNature;Level;Sport;AgeLevel;DateFrom;DateTo;National Season
        $parts{'PERSONCODE'} = $fields[2];
	    $parts{'ENTITYCODE'} = $fields[9];
        $parts{'STATUS'} = $fields[13];
        $parts{'REGNATURE'} = $fields[15];
        $parts{'PERSONTYPE'} = $fields[0];
        $parts{'PERSONROLE'} = $fields[1];
        $parts{'PERSONLEVEL'} = $fields[16];
        $parts{'SPORT'} = $fields[17];
        $parts{'AGELEVEL'} = $fields[18];
        $parts{'DATEFROM'} = $fields[19];
        $parts{'DATETO'} = $fields[20];
        $parts{'DATETRANSFERRED'} = '';
        $parts{'ISLOAN'} = '';
        $parts{'NATIONALPERIOD'} = $fields[21] || '';
        $parts{'NATIONALPERIODID'} = $natPeriod;
        $parts{'PRODUCTCODE'} = '';
        $parts{'PRODUCTAMOUNT'} = '';
        $parts{'ISPAID'} = '';
        $parts{'TRANSACTIONNO'} = '';
        $parts{'DATEPAID'} = '';
        $parts{'CERTIFICATIONS'} = $fields[12] || '';

        ## Update field mapping for HKG 
    }
    elsif ($maCode eq 'FIN')   {
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
	    $parts{'NATIONALPERIODID'} = 0;
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

        $parts{'CERTIFICATIONS'} = '';
        
    }
    elsif ($maCode eq 'AZE')    {
    	$parts{'PERSONCODE'} = $fields[4] || '';
	    $parts{'ENTITYCODE'} = $fields[5] || '';
	    $parts{'STATUS'} = uc($fields[12]) || '';
        #$parts{'REGNATURE'} = uc($fields[27]) || '';
	    $parts{'PERSONTYPE'} = uc($fields[14]) || '';
	    $parts{'PERSONROLE'} = uc($fields[15]) || '';
	    $parts{'PERSONLEVEL'} = uc($fields[16]) || '';
	    $parts{'SPORT'} = uc($fields[17]) || '';
	    $parts{'AGELEVEL'} = uc($fields[18]) || 'ADULT';
	    $parts{'DATEFROM'} = $fields[21] || '0000-00-00';
	    $parts{'DATETO'} = $fields[22] || '0000-00-00';
	    $parts{'NATIONALPERIOD'} = $fields[24] || '';
	    $parts{'NATIONALPERIODID'} = 0;
	    $parts{'PRODUCTCODE'} = '';
	    $parts{'CLIENTPRIMPORTCODE'} = $fields[0] || '';

	    $parts{'ISLOAN'} = '';
	    $parts{'DATETRANSFERRED'} = '0000-00-00';
	    $parts{'PRODUCTAMOUNT'} = 0;
	    $parts{'ISPAID'} = '';
	    $parts{'TRANSACTIONNO'} = ''; #$fields[17] || '';
	    $parts{'DATEPAID'} = '';
        
        $parts{'AGELEVEL'} = 'ADULT' if $parts{'AGELEVEL'} eq 'SENIOR';
        $parts{'PERSONTYPE'} = 'MAOFFICIAL' if $parts{'PERSONTYPE'} eq 'MA OFFICIAL';
        $parts{'PERSONTYPE'} = 'RAOFFICIAL' if $parts{'PERSONTYPE'} eq 'RA OFFICIAL';
        $parts{'PERSONTYPE'} = 'TEAMOFFICIAL' if $parts{'PERSONTYPE'} eq 'TEAM OFFICIAL';
        $parts{'PERSONTYPE'} = 'CLUBOFFICIAL' if $parts{'PERSONTYPE'} eq 'CLUB OFFICIAL';
        $parts{'PERSONTYPE'} = 'SCHOOLTEACHER' if $parts{'PERSONTYPE'} eq 'SCHOOL TEACHER';

        if ($parts{'PERSONTYPE'} eq 'RAOFFICIAL')    {
            $parts{'PERSONROLE'} = 'RA_DEL' if $parts{'PERSONROLE'} eq 'DELEGATE';
            $parts{'PERSONROLE'} = 'RA_RO' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER';
            $parts{'PERSONROLE'} = 'RA_SCOUT' if $parts{'PERSONROLE'} eq 'SCOUT';
        }

        if ($parts{'PERSONTYPE'} eq 'MAOFFICIAL')    {
            $parts{'PERSONROLE'} = 'MA_DEL' if $parts{'PERSONROLE'} eq 'DELEGATE';
            $parts{'PERSONROLE'} = 'MA_RO' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER';
            $parts{'PERSONROLE'} = 'MA_SCOUT' if $parts{'PERSONROLE'} eq 'SCOUT';
        }

        if($parts{'PERSONROLE'} eq 'PHYSIOTHERAPEUT') {
            $parts{'PERSONROLE'} = 'TO_PH';
        }

        (my $dtFrom = $parts{'DATEFROM'}) =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d)/$3-$2-$1/;
        $parts{'DATEFROM'} = $dtFrom;

        (my $dtTo = $parts{'DATETO'}) =~ s/(\d\d)\/(\d\d)\/(\d\d\d\d)/$3-$2-$1/;
        $parts{'DATETO'} = $dtTo;

        $parts{'PERSONTYPE'} = '' if $parts{'PERSONTYPE'} eq 'NULL';
        $parts{'PERSONROLE'} = '' if $parts{'PERSONROLE'} eq 'NULL';
        $parts{'PERSONLEVEL'} = '' if $parts{'PERSONLEVEL'} eq 'NULL';
        $parts{'SPORT'} = '' if $parts{'SPORT'} eq 'NULL';

        $parts{'SPORT'} = 'RECREATIONAL' if $parts{'SPORT'} eq 'RECREATIONAL FOOTBALL';

        $parts{'CERTIFICATIONS'} = '';

        my @regNatureColumn = split(',', $fields[26]);
        $parts{'REGNATURE'} = uc($regNatureColumn[1]);
        $parts{'REGNATURE'} = 'NEW' if $parts{'REGNATURE'} eq 'NEW REGISTRATION'; 

	    $parts{'ISLOAN'} = 1 if ($parts{'REGNATURE'} eq "LOAN");

        #print STDERR Dumper %parts;
        #print STDERR Dumper '-----------------------';
        #die;
        
    }
    elsif ($maCode eq 'GHA')    {
        ## Finland at moment
    	$parts{'PERSONCODE'} = $fields[0] || '';
	    $parts{'ENTITYCODE'} = $fields[1] || '';
	    $parts{'STATUS'} = uc($fields[2]) || '';
	    $parts{'REGNATURE'} = uc($fields[3]) || '';
	    $parts{'PERSONTYPE'} = uc($fields[4]) || '';
	    $parts{'PERSONROLE'} = uc($fields[5]) || '';
	    $parts{'PERSONLEVEL'} = uc($fields[6]) || '';
	    $parts{'SPORT'} = uc($fields[7]) || '';
	    $parts{'AGELEVEL'} = uc($fields[8]) || 'ADULT';
	    $parts{'DATEFROM'} = $fields[9] || '0000-00-00';
	    $parts{'DATETO'} = $fields[10] || '0000-00-00';
	    $parts{'NATIONALPERIOD'} = $fields[11] || '';
	    $parts{'NATIONALPERIODID'} = 0;
	    $parts{'PRODUCTCODE'} = $fields[12] || '';
	    $parts{'CLIENTPRIMPORTCODE'} = $fields[16] || '';

	    $parts{'ISLOAN'} = '';
	    $parts{'ISLOAN'} = 1 if ($parts{'REGNATURE'} eq "LOAN");
	    $parts{'DATETRANSFERRED'} = '0000-00-00';
	    $parts{'PRODUCTAMOUNT'} = 0;
	    $parts{'ISPAID'} = '';
	    $parts{'TRANSACTIONNO'} = ''; #$fields[17] || '';
	    $parts{'DATEPAID'} = '';
        
        $parts{'AGELEVEL'} = 'ADULT' if $parts{'AGELEVEL'} eq 'SENIOR';
        $parts{'PERSONTYPE'} = 'MAOFFICIAL' if $parts{'PERSONTYPE'} eq 'MA OFFICIAL';
        $parts{'PERSONTYPE'} = 'RAOFFICIAL' if $parts{'PERSONTYPE'} eq 'RA OFFICIAL';
        if ($parts{'PERSONTYPE'} eq 'MATCH OFFICIAL')    {
            $parts{'PERSONTYPE'} = 'MAOFFICIAL';
        }
        if ($parts{'PERSONTYPE'} eq 'RAOFFICIAL')    {
            $parts{'PERSONROLE'} = 'RAREFOBDIST' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER DISTRICT';
            $parts{'PERSONROLE'} = 'RAREFOBFAF' if $parts{'PERSONROLE'} eq 'REFEREE OBSERVER FAF';
        }

        $parts{'CERTIFICATIONS'} = '';
        
    }
	if ($countOnly)	{
		$insCount++;
		next;
	}

	my $st = qq[
		INSERT INTO tmpPersonRego
		(strFileType, strPersonCode, strEntityCode, strStatus, strRegoNature, strPersonType, strPersonRole, strPersonLevel, strSport, strAgeLevel, dtFrom, dtTo, dtTransferred, isLoan, strNationalPeriodCode, intNationalPeriodID, strProductCode, curProductAmount, strPaid, strTransactionNo, dtPaid, strCertifications, strClientPRImportCode)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
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
        $parts{'NATIONALPERIODID'},
        $parts{'PRODUCTCODE'},
        $parts{'PRODUCTAMOUNT'},
        $parts{'ISPAID'},
        $parts{'TRANSACTIONNO'},
        $parts{'DATEPAID'},
        $parts{'CERTIFICATIONS'},
        $parts{'CLIENTPRIMPORTCODE'}
    ) or print "ERROR";
}

print STDERR Dumper %existingNationalPeriod;
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" . $count if $countOnly;

close INFILE;

}
1;
