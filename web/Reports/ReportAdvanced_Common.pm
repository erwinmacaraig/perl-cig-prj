#
# $Header: svn://svn/SWM/trunk/web/Reports/ReportAdvanced_Common.pm 11607 2014-05-20 01:12:36Z cgao $
#

package ReportAdvanced_Common;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getCommonValues showMultiEntitlements);
@EXPORT_OK = qw(getCommonValues showMultiEntitlements);

use strict;

use lib '.', 'comp',"..","../..";
use Reg_common;
use Defs;
use Utils;
use ConfigOptions;
use CustomFields;
use Countries;
use FieldLabels;
use FormHelpers;
use ClubCharacteristics;
use Log;
use NationalReportingPeriod;


sub getCommonValues {
	my($Data, $options)=@_;

	return undef if !keys %{$options};

	my $clientValues_ref=$Data->{'clientValues'};

	my %optvalues = ();
	my $db=$Data->{'db'};
	if($options->{'CustomFields'})	{
		$optvalues{'CustomFields'}=getCustomFieldNames($Data) || undef;
	}

	if($options->{'DefCodes'})	{
        my $locale     = $Data->{'lang'}->generateLocale();
		my $aID=getAssocID($clientValues_ref) || 0;
		my %Codes=();

		$aID=0 if $aID==-1;
		my $statement=qq[
			SELECT *,
                COALESCE(LT.strString1,strName) AS strName

			FROM tblDefCodes
                LEFT JOIN tblLocalTranslations AS LT ON (
                    LT.strType = 'DEFCODES'
                    AND LT.intID = intCodeID
                    AND LT.strLocale = '$locale'
                )
      			WHERE intRealmID=$Data->{'Realm'}
        			AND (intAssocID = $aID OR intAssocID = 0)
				AND intRecStatus<>$Defs::RECSTATUS_DELETED
		];
		my $query = $db->prepare($statement) or query_error($statement);
		$query->execute or query_error($statement);
		while (my $dref = $query->fetchrow_hashref() ) {
			$Codes{$dref->{'intType'}}{$dref->{'intCodeID'}}=$dref->{strName};
		}
		$optvalues{'DefCodes'} = \%Codes;
	}
	if($options->{'CertTypes'})	{
		my %CertTypes=();
		my $statement=qq[
			SELECT intCertificationTypeID, strCertificationType, strCertificationName
			FROM tblCertificationTypes
			WHERE intRealmID = ?
		];
		my $query = $db->prepare($statement);
		$query->execute($Data->{'Realm'});
		while (my $dref = $query->fetchrow_hashref() ) {
            my $name = '';
            if ($dref->{'strCertificationType'})    {
                $name .= $Defs::personType{$dref->{'strCertificationType'}} . qq[-];
            }
            $name .= $dref->{strCertificationName};
			$CertTypes{$dref->{'intCertificationTypeID'}}=$name;
		}
		$optvalues{'CertTypes'} = \%CertTypes;
	}


	if($options->{'LegalTypes'})	{
		my %LegalTypes=();
		my $statement=qq[
			SELECT strLegalType, intLegalTypeID
			FROM tblLegalType
			WHERE intRealmID IN (0, ?)
		];
		my $query = $db->prepare($statement);
		$query->execute($Data->{'Realm'});
		while (my $dref = $query->fetchrow_hashref() ) {
			$LegalTypes{$dref->{'intLegalTypeID'}}=$dref->{strLegalType};
		}
		$optvalues{'LegalTypes'} = \%LegalTypes;
	}

	if($options->{'NationalPeriods'})	{
        my $natPeriods = getPeriods($Data);
		$optvalues{'NationalPeriods'} = $natPeriods;
	}

	if($options->{'SubRealms'})	{
		my %AssocTypes=();
		my $statement=qq[
			SELECT intSubTypeID, strSubTypeName
			FROM tblRealmSubTypes
			WHERE intRealmID = ?
		];
		my $query = $db->prepare($statement);
		$query->execute($Data->{'Realm'});
		while (my $dref = $query->fetchrow_hashref() ) {
			$AssocTypes{$dref->{'intSubTypeID'}}=$dref->{strSubTypeName};
		}
		$optvalues{'SubRealms'} = \%AssocTypes;
	}


	if($options->{'Seasons'})	{
		my $AssocSeasons=Seasons::getDefaultAssocSeasons($Data);
		my $hideSeasons=0;
		$hideSeasons = 1 if(!$Data->{'SystemConfig'}{'AllowSeasons'} and !$AssocSeasons->{'allowSeasons'});
		my $currentSeason = $AssocSeasons->{'currentSeasonID'} || 0;
		my %Seasons=();
		my @SeasonsOrder=();
		if ($Data->{'SystemConfig'}{'AllowSeasons'})	{
			my $aID=getAssocID($clientValues_ref) || 0;
			$aID=0 if $aID==-1;
			my $statement=qq[
				SELECT intSeasonID, strSeasonName
				FROM tblSeasons
							WHERE intRealmID=$Data->{'Realm'}
							AND (intAssocID = $aID OR intAssocID = 0)
				 AND (intRealmSubTypeID = $Data->{'RealmSubType'} OR intRealmSubTypeID= 0)
				ORDER BY intSeasonOrder, strSeasonName DESC
			];
			my $query = $db->prepare($statement) or query_error($statement);
			$query->execute or query_error($statement);
			while (my $dref = $query->fetchrow_hashref() ) {
				$Seasons{$dref->{'intSeasonID'}}=$dref->{strSeasonName};
				push @SeasonsOrder, $dref->{intSeasonID};
			}
		}
		my %SeasonData = (
			Options => \%Seasons,
			Order => \@SeasonsOrder,
			Hide => $hideSeasons,
			Current => $currentSeason,
		);
		$optvalues{'Seasons'} = \%SeasonData;
	}

	if($options->{'AgeGroups'})	{

		my %AgeGroups=();
		my @AgeGroupsOrder=();
		if ($Data->{'SystemConfig'}{'AllowSeasons'})	{
			my $aID=getAssocID($clientValues_ref) || 0;
			$aID=0 if $aID==-1;
			my $statement=qq[
				SELECT intAgeGroupID, strAgeGroupDesc, intAgeGroupGender
				FROM tblAgeGroups
							WHERE intRealmID=$Data->{'Realm'}
							AND (intAssocID = $aID OR intAssocID = 0)
				 AND (intRealmSubTypeID = $Data->{'RealmSubType'} OR intRealmSubTypeID= 0)
				AND intRecStatus=1
				ORDER BY strAgeGroupDesc
			];
			my $query = $db->prepare($statement) or query_error($statement);
			$query->execute or query_error($statement);
			while (my $dref = $query->fetchrow_hashref() ) {
				my $gender = $dref->{intAgeGroupGender} ? qq[- ($Defs::genderInfo{$dref->{intAgeGroupGender}})] : '';
				$AgeGroups{$dref->{'intAgeGroupID'}}=qq[$dref->{strAgeGroupDesc}$gender] || '';
				push @AgeGroupsOrder, $dref->{intAgeGroupID};
			}
		}
		$optvalues{'AgeGroups'} = {
			Order => \@AgeGroupsOrder,
			Options => \%AgeGroups,
		};
	}

	if($options->{'Products'})	{
		if($Data->{'SystemConfig'}{'AllowTXNrpts'})	{
			my %Products=();
			my @ProductsOrder=();
			my $aID=getAssocID($clientValues_ref) || 0;
			$aID=0 if $aID==-1;
			my $WHEREClub = '';
			if ($Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID) {
				$WHEREClub = qq[
					AND (
						(intCreatedLevel = 0 OR intCreatedLevel > 3) 
						OR (
							intCreatedLevel = $Defs::LEVEL_CLUB 
							AND intCreatedID = $Data->{'clientValues'}{'clubID'}
						)
					)
				];
			}

			my $levelWHERE = '';
			my $currentLevel = $Data->{'clientValues'}{'currentLevel'};
			my $productName = qq[ P.strName as ProductName,];
			if ($currentLevel > $Defs::LEVEL_CLUB)	{
				$levelWHERE .= qq[TNS.int100_ID > 0 ] if ($currentLevel > 100);
				$levelWHERE .= qq[TNS.int100_ID = $Data->{'clientValues'}{'natID'}] if ($currentLevel == 100);
				$levelWHERE .= qq[TNS.int30_ID = $Data->{'clientValues'}{'stateID'}] if ($currentLevel == 30);
				$levelWHERE .= qq[TNS.int20_ID = $Data->{'clientValues'}{'regionID'}] if ($currentLevel == 20);
				$levelWHERE .= qq[TNS.int10_ID = $Data->{'clientValues'}{'zoneID'}] if ($currentLevel == 10);
				$levelWHERE .= qq[ )];
			}
$levelWHERE = '';
			my $statement=qq[
				SELECT DISTINCT
					P.intProductID,
                    P.strName as ProductName,
					$productName
					strGroup, 
					intInactive
				FROM tblProducts as P 
				WHERE P.intRealmID=$Data->{'Realm'}
					$levelWHERE
					AND intProductSubRealmID IN (0, $Data->{'RealmSubType'})
					$WHEREClub
				ORDER BY intInactive, strGroup,ProductName 
			];
			my $query = $db->prepare($statement) or query_error($statement);
			$query->execute or query_error($statement);
			while (my $dref = $query->fetchrow_hashref() ) {
				my $inactive = $dref->{intInactive} ? qq[(ARCHIVED)-] : '';
				my $group = $dref->{strGroup} ? qq[$dref->{strGroup}-] : '';
				$Products{$dref->{'intProductID'}}=qq[$inactive$group$dref->{ProductName}];
				push @ProductsOrder, $dref->{intProductID};
			}
			$optvalues{'Products'} = {
				Order => \@ProductsOrder,
				Options => \%Products,
			};
		}
	}

	if($options->{'Countries'})	{
		$optvalues{'Countries'} = getISOCountriesHash();
		$optvalues{'CountriesHistorical'} = getISOCountriesHash(historicalCountries => 1);
	}

	if($options->{'FieldLabels'})	{
		$optvalues{'FieldLabels'} = getFieldLabels($Data, $Defs::LEVEL_PERSON);
	}

	return \%optvalues;
}

sub showMultiEntitlements {
  my($val, $lookup)=@_;

  my @a=split /\|/,$val;
  my $out='';
  for my $i (@a)  {
    next if !$i;
    $out.=', ' if $out;
    my $v=$i;
    $v=$lookup->{$i} if ($lookup and $lookup->{$i});
    $out.=$v;
  }
  return $out;

}

1;

