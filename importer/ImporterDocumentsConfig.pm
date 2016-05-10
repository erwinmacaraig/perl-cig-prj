package ImporterDocumentsConfig;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    importDocConfigFile
    runDocConfig
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

sub runDocConfig    {

    my ($db) = @_;

    my $st = qq[ DELETE FROM tblRegistrationItem WHERE strRuleFor='REGO' and strItemType='DOCUMENT'];
    $db->do($st);

    $st = qq[ DELETE FROM tblWFRuleDocuments ];
    $db->do($st);
    
    $st = qq[
        INSERT INTO tblRegistrationItem SELECT 0,1,0,?,'REGO', '',?, strRegistrationNature, strPersonType, strPersonLevel, strSport, strAgeLevel, strItemType, intID, intUseExisting, intUseExisting, NOW(), intRequired, '', strISOCountry_IN, strISOCountry_NOTIN, intFilterFromAge, intFilterToAge, intItemNeededITC, intItemUsingITCFilter, 0,'',0, 0,'',0, intItemForInternationalTransfer, intItemForInternationalLoan , '' FROM _tblDocumentConfig WHERE strPersonType=?
    ];
    my @L100types = ('MAOFFICIAL', 'REFEREE');
    foreach my $type (@L100types)   {
        my $q= $db->prepare($st) or query_error($st);
        $q->execute(100,100,$type);
    }
        

    my @L20types = ('RAOFFICIAL');
    my @Levels = (
        {   
            100=>20, 
        },
        {
            20=>20,
        }
    );
    foreach my $type (@L20types)   {
        for my $href ( @Levels ) {
            for my $origin ( keys %$href ) {
                my $q= $db->prepare($st) or query_error($st);
                $q->execute(
                    $origin,
                    $href->{$origin},
                    $type
                );
            }
        }
    }

    my @Ltypes = ('TEAMOFFICIAL', 'CLUBOFFICIAL');
    @Levels = (
        {   
            100=>3, 
        },
        {
            20=>3,
        },
        {
            3=>3,
        },
        {
            1=>3,
        }
    );
    foreach my $type (@Ltypes)   {
        for my $href ( @Levels ) {
            for my $origin ( keys %$href ) {
                my $q= $db->prepare($st) or query_error($st);
                $q->execute(
                    $origin,
                    $href->{$origin},
                    $type
                );
            }
        }
    }

    @Ltypes = ('PLAYER');
    @Levels = (
        {
            100=>100,
        },
        {   
            100=>20, 
        },
        {   
            100=>3, 
        },
        {
            20=>20,
        },
        {
            20=>3,
        },
        {
            3=>3,
        },
        {
            1=>3,
        },
        {
            1=>20,
        },
        {
            1=>100,
        }
    );
    foreach my $type (@Ltypes)   {
        for my $href ( @Levels ) {
            for my $origin ( keys %$href ) {
                my $q= $db->prepare($st) or query_error($st);
                $q->execute(
                    $origin,
                    $href->{$origin},
                    $type
                );
            }
        }
    }


    @Ltypes = ('COACH');
    @Levels = (
        {
            100=>100,
        },
        {   
            100=>20, 
        },
        {   
            100=>3, 
        },
        {
            20=>20,
        },
        {
            20=>3,
        },
        {
            3=>3,
        },
        {
            1=>3,
        },
        {
            1=>20,
        },
        {
            1=>100,
        }
    );
    foreach my $type (@Ltypes)   {
        for my $href ( @Levels ) {
            for my $origin ( keys %$href ) {
                my $q= $db->prepare($st) or query_error($st);
                $q->execute(
                    $origin,
                    $href->{$origin},
                    $type
                );
            }
        }
    }


    my @Ltypes = ('REFEREE');
    @Levels = (
        {
            100=>100,
        },
        {   
            100=>20, 
        },
        {   
            100=>3, 
        },
        {
            20=>20,
        },
        {
            20=>3,
        },
        {
            3=>3,
        },
        {
            1=>3,
        },
        {
            1=>20,
        },
        {
            1=>100,
        }
    );
    foreach my $type (@Ltypes)   {
        for my $href ( @Levels ) {
            for my $origin ( keys %$href ) {
                my $q= $db->prepare($st) or query_error($st);
                $q->execute(
                    $origin,
                    $href->{$origin},
                    $type
                );
            }
        }
    }


    $st = qq[
        INSERT INTO tblWFRuleDocuments 
        SELECT 0, R.intWFRuleID, RI.intID, 1,1,1,1,NOW() 
        FROM tblWFRule as R 
        INNER JOIN tblRegistrationItem as RI ON (
            RI.intOriginLevel=R.intOriginLevel 
            AND RI.intEntityLevel=R.intEntityLevel 
            AND RI.strRegistrationNature=R.strRegistrationNature 
            AND RI.strPersonType=R.strPersonType 
            AND RI.strPersonLevel IN('',R.strPersonLevel) 
            AND RI.strSport IN ('',R.strSport) 
            AND RI.strAgeLevel IN ('',R.strAgeLevel) 
            AND (
                (
                    R.strISOCountry_IN = '' 
                    AND R.strISOCountry_NOTIN = ''
                ) 
                OR (
                    RI.strISOCountry_IN = R.strISOCountry_IN 
                    AND RI.strISOCountry_NOTIN = R.strISOCountry_NOTIN
                )
            ) 
        )
        WHERE R.strWFRuleFor='REGO'
    ];
    $db->do($st);
 

    my $est = qq[
        INSERT INTO tblWFRuleDocuments
        SELECT 0, wr.intWFRuleID, ri.intID, 1, 1, 1, 1, NOW() 
        FROM tblRegistrationItem ri INNER JOIN tblWFRule wr ON
            (wr.strWFRuleFor = ri.strRuleFor AND wr.strRegistrationNature = ri.strRegistrationNature AND wr.intOriginLevel = ri.intOriginLevel)
        WHERE
            wr.strWFRuleFor = 'ENTITY'
            AND ri.strItemType = 'DOCUMENT'
            AND ri.intRealmID = 1
    ];
    $db->do($est);

}

sub importDocConfigFile {
    my ($db, $countOnly, $infile) = @_;
    
    open INFILE, "<$infile" or die "Can't open Input File";

    my $count = 0;
                                                                                                            
    seek(INFILE,0,0);
    $count=0;
    my $insCount=0;
    my $NOTinsCount = 0;

    my %cols = ();
    my $stDEL = "DELETE FROM _tblDocumentConfig";
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

        $parts{'DOC_ID'} = $fields[0] || '';
        $parts{'TYPE'} = $fields[1] || '';
        $parts{'REGONATURE'} = $fields[2] || '';
        $parts{'LEVEL'} = $fields[3] || '';
        $parts{'SPORT'} = $fields[4] || '';
        $parts{'AGE'} = $fields[5] || '';
        $parts{'NATIONALITY_IN'} = $fields[6] || '';
        $parts{'NATIONALITY_NOTIN'} = $fields[7] || '';
        $parts{'REQUIRED'} = $fields[8] || 0;
        $parts{'EXISTING'} = $fields[9] || 0;
        $parts{'FROMAGE'} = $fields[10] || 0;
        $parts{'TOAGE'} = $fields[11] || 0;
        $parts{'INT_TRANSFER_NEW'} = $fields[12] || 0;
        $parts{'INT_LOAN_NEW'} = $fields[13] || 0;
        $parts{'USING_ITC_FILTER'} = $fields[14] || 0;
        $parts{'ITC_FLAG'} = $fields[15] || 0;
        if (! $parts{'DOC_ID'}) { next; }
        if (! $parts{'REGONATURE'}) { next; }
        if ($countOnly)	{
            $insCount++;
            next;
        }

        my $st = qq[
            INSERT INTO _tblDocumentConfig
            (
                strRuleFor,
                strRegistrationNature,
                strPersonType,
                strPersonLevel,
                strPersonEntityRole,
                strSport,
                strAgeLevel,
                strItemType,
                intID,
                intUseExisting,
                intRequired,
                strISOCountry_IN,
                strISOCountry_NOTIN,
                intFilterFromAge,
                intFilterToAge,
                intItemForInternationalTransfer,
                intItemForInternationalLoan,
                intItemUsingITCFilter,
                intItemNeededITC
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
                ?
            )
                
        ];
        my $query = $db->prepare($st) or query_error($st);
        $query->execute(
            'REGO',
            $parts{'REGONATURE'},
            $parts{'TYPE'},
            $parts{'LEVEL'},
            '',
            $parts{'SPORT'},
            $parts{'AGE'},
            'DOCUMENT',
            $parts{'DOC_ID'},
            $parts{'EXISTING'},
            $parts{'REQUIRED'},
            $parts{'NATIONALITY_IN'},
            $parts{'NATIONALITY_NOTIN'},
            $parts{'FROMAGE'},
            $parts{'TOAGE'},
            $parts{'INT_TRANSFER_NEW'},
            $parts{'INT_LOAN_NEW'},
            $parts{'USING_ITC_FILTER'},
            $parts{'ITC_FLAG'}
            
        ) or print "ERROR";
}
$count --;
print STDERR "COUNT CHECK ONLY !!!\n" if $countOnly;

close INFILE;

}
1;
