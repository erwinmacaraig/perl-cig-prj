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

    my $realmID=2016;
    my $maxOldProductID = 175;

    my ($activeProducts_ref, $activePeriods_ref, $newProductIDs_ref) = setupFINHashes();

    my $st = qq[
        SELECT
            *
        FROM
            tblRegistrationItem
        WHERE
            strItemType = 'PRODUCT'
            AND intID < $maxOldProductID
            AND intRealmID=1
            AND strRuleFor = 'REGO'
    ];

    my $stDEL = qq[
        DELETE FROM tblRegistrationItem
        WHERE intRealmID=$realmID
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
            strISOCountry_NOTIN  
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
                my @products= split /\&/, $dref->{'strItemActiveFilterPaidProducts'};
                foreach my $ExistingProductID (@products)    {
                    $activeProducts.= "|" if ($activeProducts);
                    $activeProducts .= $newProductIDs_ref->{$ExistingProductID};
                }
            }
        }

        $qryINS->execute(
            $dref->{'intSubRealmID'},
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
    $ActivePeriods{'118|120'} = '120|121';

    my %NewProductIDs = ();
    $NewProductIDs{59}= 200;   
    $NewProductIDs{60}= 201;
    $NewProductIDs{61}= 202;
    $NewProductIDs{62}= 203;
    $NewProductIDs{63}= 204;
    $NewProductIDs{64}= 205;
    $NewProductIDs{65}= 206;
    $NewProductIDs{66}= 207;
    $NewProductIDs{67}= 208;
    $NewProductIDs{68}= 209;
    $NewProductIDs{69}= 210;
    $NewProductIDs{70}= 211;
    $NewProductIDs{71}= 212;
    $NewProductIDs{72}= 213;
    $NewProductIDs{73}= 214;
    $NewProductIDs{74}= 215;
    $NewProductIDs{75}= 216;
    $NewProductIDs{76}= 217;
    $NewProductIDs{77}= 218;
    $NewProductIDs{78}= 219;
    $NewProductIDs{79}= 220;
    $NewProductIDs{80}= 221;
    $NewProductIDs{81}= 222;
    $NewProductIDs{82}= 223;
    $NewProductIDs{83}= 224;
    $NewProductIDs{84}= 225;
    $NewProductIDs{86}= 227;
    $NewProductIDs{87}= 228;
    $NewProductIDs{88}= 229;
    $NewProductIDs{89}= 230;
    $NewProductIDs{90}= 231;
    $NewProductIDs{91}= 232;
    $NewProductIDs{92}= 233;
    $NewProductIDs{93}= 234;
    $NewProductIDs{94}= 235;
    $NewProductIDs{95}= 236;
    $NewProductIDs{96}= 237;
    $NewProductIDs{97}= 238;
    $NewProductIDs{98}= 239;
    $NewProductIDs{99}= 240;
    $NewProductIDs{100}= 241;
    $NewProductIDs{117}= 258;
    $NewProductIDs{118}= 259;
    $NewProductIDs{119}= 260;
    $NewProductIDs{120}= 261;
    $NewProductIDs{121}= 262;
    $NewProductIDs{122}= 263;
    $NewProductIDs{123}= 264;
    $NewProductIDs{124}= 265;
    $NewProductIDs{125}= 266;
    $NewProductIDs{126}= 267;
    $NewProductIDs{127}= 268;
    $NewProductIDs{128}= 269;
    $NewProductIDs{129}= 270;
    $NewProductIDs{130}= 271;
    $NewProductIDs{131}= 272;
    $NewProductIDs{132}= 273;
    $NewProductIDs{133}= 274;
    $NewProductIDs{134}= 275;
    $NewProductIDs{135}= 276;
    $NewProductIDs{136}= 277;
    $NewProductIDs{137}= 278;
    $NewProductIDs{138}= 279;
    $NewProductIDs{139}= 280;
    $NewProductIDs{140}= 281;
    $NewProductIDs{141}= 282;
    $NewProductIDs{142}= 283;
    $NewProductIDs{143}= 284;
    $NewProductIDs{144}= 285;
    $NewProductIDs{145}= 286;
    $NewProductIDs{146}= 287;
    $NewProductIDs{147}= 288;
    $NewProductIDs{148}= 289;
    $NewProductIDs{149}= 290;
    $NewProductIDs{150}= 291;
    $NewProductIDs{151}= 292;
    $NewProductIDs{152}= 293;
    $NewProductIDs{153}= 294;
    $NewProductIDs{154}= 295;
    $NewProductIDs{160}= 301;
    $NewProductIDs{161}= 302;
    $NewProductIDs{162}= 303;
    $NewProductIDs{163}= 304;
    $NewProductIDs{164}= 305;
    $NewProductIDs{165}= 306;
    return (\%ActiveProducts, \%ActivePeriods, \%NewProductIDs);
}

1;
