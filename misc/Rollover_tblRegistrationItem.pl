#!/usr/bin/perl

#
# $Header: 
#

use strict;
use lib '.', '..','../web';
use Defs;
use Utils;

main();

sub main    {
    my $db = connectDB();

    rolloverRegoItems($db);



}

sub rolloverRegoItems {
    my ($db) = @_;

    my $realmID=2017;
    my $maxOldProductID = 30;
#SELECT COUNT(R.intItemID) FROM tblRegistrationItem as R INNER JOIN tblProducts as P ON (P.intProductID=R.intID) WHERE strItemType ='PRODUCT' AND intID<175 and R.intRealmID=1;

    my ($activeProducts_ref, $activePeriods_ref, $newProductIDs_ref) = setupFINHashes();

    my $st = qq[
        SELECT
            R.*
        FROM
            tblRegistrationItem as R
            INNER JOIN tblProducts as P ON (P.intProductID = R.intID)
        WHERE
            R.strItemType = 'PRODUCT'
            AND R.intID <= $maxOldProductID
            AND R.intRealmID=1
            AND R.strRuleFor = 'REGO'
    ];

    my $stDEL = qq[
        DELETE FROM tblRegistrationItem
        WHERE intRealmID IN (1,$realmID)
            AND intID>$maxOldProductID
            AND strItemType='PRODUCT'
    ];
    $db->do($stDEL);

    my $stINS= qq[
        INSERT INTO tblRegistrationItem
        (
            intRealmID, 
            intSubRealmID, 
            intOriginLevel, 
            strRuleFor, 
            strEntityType, 
            intEntityLevel, 
            strRegistrationNature, 
            strPersonType, 
            strPersonLevel, 
            strSport, 
            strAgeLevel, 
            strItemType, 
            intID, 
            intUseExistingThisEntity, 
            intUseExistingAnyEntity, 
            intRequired, 
            strPersonEntityRole, 
            strISOCountry_IN, 
            strISOCountry_NOTIN,
            intFilterFromAge, 
            intFilterToAge, 
            intItemNeededITC, 
            intItemUsingITCFilter, 
            intItemUsingActiveFilter, 
            strItemActiveFilterPeriods, 
            intItemActive, 
            intItemUsingPaidProductFilter, 
            strItemActiveFilterPaidProducts, 
            intItemPaidProducts, 
            intItemForInternationalTransfer, 
            intItemForInternationalLoan  
        )
        VALUES (
            $realmID, 
            0, 
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
            ?,
            ?
        )
    ];
    my $qryINS= $db->prepare($stINS);

    my $qry= $db->prepare($st);
    $qry->execute();

    while (my $dref = $qry->fetchrow_hashref()) {
        my $intID = $newProductIDs_ref->{$dref->{'intID'}};
        my $activeProducts = $activeProducts_ref->{$dref->{'strItemActiveFilterPaidProducts'}} || '';
        my $activePeriods  = $activePeriods_ref->{$dref->{'strItemActiveFilterPeriods'}} || '';

        if ($dref->{'strItemActiveFilterPaidProducts'} and ! $activeProducts)    {
            if ($dref->{'strItemActiveFilterPaidProducts'} =~ /\&/) {
                my @products= split /\&/, $dref->{'strItemActiveFilterPaidProducts'};
                foreach my $ExistingProductID (@products)    {
                    $activeProducts.= "&" if ($activeProducts);
                    $activeProducts .= $newProductIDs_ref->{$ExistingProductID};
                }
            }
            if ($dref->{'strItemActiveFilterPaidProducts'} =~ /\|/) {
                my @products= split /\|/, $dref->{'strItemActiveFilterPaidProducts'};
                foreach my $ExistingProductID (@products)    {
                    $activeProducts.= "|" if ($activeProducts);
                    $activeProducts .= $newProductIDs_ref->{$ExistingProductID};
                }
            }
        }

        $qryINS->execute(
            $dref->{'intOriginLevel'},
            $dref->{'strRuleFor'},
            $dref->{'strEntityType'},
            $dref->{'intEntityLevel'},
            $dref->{'strRegistrationNature'},
            $dref->{'strPersonType'},
            $dref->{'strPersonLevel'},
            $dref->{'strSport'},
            $dref->{'strAgeLevel'},
            $dref->{'strItemType'},
            $intID,
            $dref->{'intUseExistingThisEntity'},
            $dref->{'intUseExistingAnyEntity'},
            $dref->{'intRequired'},
            $dref->{'strPersonEntityRole'},
            $dref->{'strISOCountry_IN'},
            $dref->{'strISOCountry_NOTIN'},
            $dref->{'intFilterFromAge'},
            $dref->{'intFilterToAge'},
            $dref->{'intItemNeededITC'},
            $dref->{'intItemUsingITCFilter'},
            $dref->{'intItemUsingActiveFilter'},
            $activePeriods,
            $dref->{'intItemActive'},
            $dref->{'intItemUsingPaidProductFilter'},
            $activeProducts,
            $dref->{'intItemPaidProducts'},
            $dref->{'intItemForInternationalTransfer'},
            $dref->{'intItemForInternationalLoan'},
        );
    }
}

sub setupFINHashes {

 my %ActiveProducts = ();
    $ActiveProducts{''} = '';

    my %ActivePeriods  = ();
    $ActivePeriods{''} = '';
    $ActivePeriods{'8|9|17|15|26|27|35|36'} = '8|9|17|18|26|27|35|36|38|39|40|41';

    my %NewProductIDs = ();
    $NewProductIDs{1}= 31;   
    $NewProductIDs{2}= 32;   
    $NewProductIDs{3}= 33;   
    $NewProductIDs{4}= 34;   
    $NewProductIDs{5}= 35;   
    $NewProductIDs{6}= 36;   
    $NewProductIDs{7}= 37;   
    $NewProductIDs{8}= 38;   
    $NewProductIDs{9}= 39;   
    $NewProductIDs{10}= 40;   
    $NewProductIDs{11}= 41;   
    $NewProductIDs{12}= 42;   
    $NewProductIDs{13}= 43;   
    $NewProductIDs{14}= 44;   
    $NewProductIDs{15}= 45;   
    $NewProductIDs{16}= 46;   
    $NewProductIDs{17}= 47;   
    $NewProductIDs{18}= 48;   
    $NewProductIDs{19}= 49;   
    $NewProductIDs{20}= 50;   
    $NewProductIDs{21}= 51;   
    $NewProductIDs{22}= 52;   
    $NewProductIDs{23}= 53;   
    $NewProductIDs{24}= 54;   
    $NewProductIDs{25}= 55;   
    $NewProductIDs{26}= 56;   
    $NewProductIDs{27}= 57;   
    $NewProductIDs{28}= 58;   
    $NewProductIDs{29}= 59;   
    $NewProductIDs{30}= 60;   
    return (\%ActiveProducts, \%ActivePeriods, \%NewProductIDs);
}

1;
