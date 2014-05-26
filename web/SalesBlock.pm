#
# $Header: svn://svn/SWM/trunk/web/SalesBlock.pm 8251 2013-04-08 09:00:53Z rlee $
#

package SalesBlock;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getSalesBlock);
@EXPORT_OK = qw(getSalesBlock);

use strict;
use lib "..",".";

use Defs;
use TTTemplate;

sub getSalesBlock {
 
	my($Data, $SystemConfig, $type) = @_;

	$type ||= 0;
	my $clientValues = $Data->{'clientValues'};
	my $currentLevel = $clientValues->{INTERNAL_tempLevel} ||  $clientValues->{currentLevel};
	my $authLevel = $clientValues->{authLevel};

	my $assocID = $clientValues->{'assocID'} || 0;
	my $clubID = $clientValues->{'clubID'} || 0;
	my $realmID = $Data->{'Realm'};
	my $subRealmID = $Data->{'RealmSubType'};


	my $typeWhere = '';
	if( $currentLevel == $Defs::LEVEL_ASSOC)	{
		$typeWhere .= qq[ SBE.intAssocs = 1 ];
	}
	elsif( $currentLevel == $Defs::LEVEL_CLUB)	{
		$typeWhere .= qq[ SBE.intClubs = 1 ];
	}
	else	{
		$typeWhere .= qq[ SBE.intOther = 1 ];
	}
	my $realmWhere = '';
	if($realmID and $realmID != -1)	{
		$realmWhere = qq[
			AND SBE.intRealmID IN (0,$realmID)
		];
		if($subRealmID)	{
			$realmWhere .= qq[
				AND SBE.intSubRealmID IN (0,$subRealmID)
			];
		}
	}

	my($country, $state) = getLocationInfo(
    $Data,
    $assocID,
    $clubID,
  );
	$country = ','.$country if $country;
	$state = ','.$state if $state;


	#Get Exclusions
	my %excluded = ();
	if($assocID)	{
		my $clubWhere = '';
		if($clubID)	{
			$clubWhere = qq[
				OR
				(
					intEntityTypeID = $Defs::LEVEL_CLUB 
						AND intEntityID = $clubID
				)

			];
		}
		my $st = qq[
			SELECT intSalesBlockID
			FROM
				tblSalesBlockExclusion
			WHERE
				(
					intEntityTypeID = $Defs::LEVEL_ASSOC 
						AND intEntityID = ?
				)
				$clubWhere
		];

		my $q=$Data->{'db'}->prepare($st);
		$q->execute( $assocID);
		while( my ($exID)=$q->fetchrow_array())	{
			$excluded{$exID} = 1;
		}
	}

	my $limit = '';
	my $template = 'sales/salesblock.templ';
	if( $type == 2)	{
		$template = 'sales/reg_confirmation.templ';
		$limit = ' LIMIT 1';
	}
	elsif($type == 3)	{
		$limit = ' LIMIT 1';
		$template = 'sales/paymentconfirmation.templ';
	}
	my $st = qq[
		SELECT DISTINCT SB.*
		FROM
			tblSalesBlock AS SB
			INNER JOIN tblSalesBlockEntity AS SBE
				ON SBE.intSalesBlockID = SB.intSalesBlockID
		WHERE
			$typeWhere
			AND SBE.strCountry IN (''$country)
			AND SBE.strState IN (''$state)
			AND intType = ?
			$realmWhere
		ORDER BY intRanking DESC
		$limit 
	];
  my $q=$Data->{'db'}->prepare($st);
  $q->execute($type);

	my @salesblocks = ();
	while( my $dref=$q->fetchrow_hashref())	{
		next if $excluded{$dref->{'intSalesBlockID'}};
		$dref->{'ThumbURL'} = "$Defs::salesimage_url/$dref->{'intSalesBlockID'}-t.jpg";
		$dref->{'DetailURL'} = "$Defs::salesimage_url/$dref->{'intSalesBlockID'}-d.jpg";
		$dref->{'strURL'} = 'http://'.$dref->{'strURL'} if $dref->{'strURL'} !~/^http/;
		push @salesblocks, $dref;
	}
	$q->finish();

	return '' if !@salesblocks;

	my $output = runTemplate(
		$Data,
		{
			Blocks => \@salesblocks,
		},
		$template,
	);
	$output ||= '';
	return $output;
}

sub getLocationInfo	{
	my (
		$Data,
		$assocID,
		$clubID,		
	) = @_;
		#Get country for current level
		# From two places 
		# 1. the country field in the record itself
		# 2. from the country level on the node structure
		#Same for state as well

	my $clubdata = ();
	my $assocdata = ();

	my $assoc = '';
	my $club = '';

	my $state = '';
	my $country = '';

	{
		if($clubID)	{
			my $st = qq[
				SELECT strState, strCountry
				FROM tblClub
				WHERE intClubID = ?
			];
			my $q=$Data->{'db'}->prepare($st);
			$q->execute($clubID);
			$clubdata = $q->fetchrow_hashref();
			$q->finish();
			$clubdata->{'strState'} ||= '';
			$clubdata->{'strState'} =~s/'/''/g;
			$clubdata->{'strCountry'} ||= '';
			$clubdata->{'strCountry'} =~s/'/''/g;
			$state = "'$clubdata->{'strState'}'" if $clubdata->{'strState'};
			$country = "'$clubdata->{'strCountry'}'" if $clubdata->{'strCountry'};
		}
		
		my $st = qq[
			SELECT strState, strCountry
			FROM tblAssoc
			WHERE intAssocID = ?
		];
		my $q=$Data->{'db'}->prepare($st);
		$q->execute($assocID);
		$assocdata = $q->fetchrow_hashref();
		$q->finish();
		$assocdata->{'strState'} =~s/'/''/g;
		$assocdata->{'strCountry'} =~s/'/''/g;
		$state ||= "'$assocdata->{'strState'}'" if $assocdata->{'strState'};
		$country ||= "'$assocdata->{'strCountry'}'" if $assocdata->{'strCountry'};
	}

	{
		my $st = qq[
			SELECT 
				S.strName AS StateName,
				C.strName AS CountryName
			FROM tblTempNodeStructure AS TNS
				INNER JOIN tblNode AS S ON S.intNodeID = TNS.int30_ID
				INNER JOIN tblNode AS C ON C.intNodeID = TNS.int100_ID
			WHERE intAssocID = ?
		];
		my $q=$Data->{'db'}->prepare($st);
		$q->execute($assocID);
		my $nodedata = $q->fetchrow_hashref();
		$q->finish();
		$nodedata->{'StateName'} =~s/'/''/g;
		$nodedata->{'CountryName'} =~s/'/''/g;
		$state .= ',' if ($state and $nodedata->{'StateName'});
		$country .= ',' if ($country and $nodedata->{'CountryName'});
		$state .= "'$nodedata->{'StateName'}'" if $nodedata->{'StateName'};
		$country .= "'$nodedata->{'CountryName'}'" if $nodedata->{'CountryName'};
	}
	return($state, $country);	
}

1;
