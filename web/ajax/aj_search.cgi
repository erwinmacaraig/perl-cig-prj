#!/usr/bin/perl

use strict;
use warnings;
use lib "..",".","../..";
use CGI qw(param);
use Defs;
use Reg_common;
use Utils;
use Sphinx::Search;
use JSON;
use Lang;
use Data::Dumper;
use Search::Person;
use Search::WorkTask;

main();  

sub main  {
  # GET INFO FROM URL
  my $client = param('client') || '';
  my $searchval = param('term') || '';
  my $role= param('role') || '';
  my $entityfilters = param('entity') || 0;
  my $tasktype = param('tasktype') || '';
  my $otherparams = '';

  my $personparams = '';
  
  my %Data=();
  my $target='main.cgi';
  $Data{'target'}=$target;
  $Data{'cache'}  = new MCache();
  my $lang= Lang->get_handle() || die "Can't get a language handle!";
  $Data{'lang'} = $lang;

  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
  my $db=allowedTo(\%Data);
  $Data{'db'} = $db;	

  my $currentLevel = $Data{'clientValues'}{'currentLevel'} || 0;
  ($Data{'Realm'}, $Data{'RealmSubType'})=getRealm(\%Data);

  # AUTHENTICATE
  my $output = '';
  if($db)  {
     my %results = ();
	 my @r = ();
	 my @iterationItems = ();
     my $sphinx = Sphinx::Search->new;

    $sphinx->SetServer($Defs::Sphinx_Host, $Defs::Sphinx_Port);
    $sphinx->SetLimits(0,1000);

    my $intermediateNodes = {};
    my $subNodes = [];
    my $rawResult = 1;

	if($role){
		#$roles  =~ s/,/','/g;
		#$otherparams .= qq[AND strPersonType IN ('$roles') ]; 	
		$otherparams .= qq[AND strPersonType = '$role' ]; 			
	}
	
	if($otherparams){
			#$personSearchObj->setQueryParam($otherparams);
		if($currentLevel > $Defs::LEVEL_PERSON)  {
        #$results{'persons'} = search_persons(
        #  \%Data,
        #  $sphinx,
        #  $searchval,
        #  $filters,
        #  $intermediateNodes,
        #  $subNodes,
        #);

		    my $personSearchObj = new Search::Person();
		    $personSearchObj
		        ->setRealmID($Data{'Realm'})
		        ->setSubRealmID(0)
		        ->setSearchType("unique")
		        ->setData(\%Data)
		        ->setKeyword($searchval)
		        ->setSphinx($sphinx)
				->setQueryParam($otherparams);		
		    #intermediateNodes, subNodes and filters are initialised in Search/Person.pm
		    $results{'persons'} = $personSearchObj->process($rawResult);
			@iterationItems = ('persons');

   		}
	} # end $otherparams

	elsif($entityfilters){
		if($currentLevel > $Defs::LEVEL_CLUB)  {
		    my $intermediateNodes = {};
		    my $subNodes = [];
		    ($intermediateNodes, $subNodes) = getIntermediateNodes(\%Data);
		    my $filters = setupFilters(\%Data, $subNodes);
			my $entityfiltersetup = '';
			$entityfiltersetup = qq[ AND intEntityLevel IN ($entityfilters) ];
			$results{'entities'} = search_entities(
				\%Data,
				$sphinx,
				$searchval,
				$filters,
				$intermediateNodes,
				$entityfiltersetup,
		  	);
		 }
		@iterationItems = ('entities');
	} #enityfilters
	elsif($tasktype){	
		
		my($strRuleFor,$nature,$type) = split(/-/,$tasktype);
		my $taskSearchObj = new Search::WorkTask();
      	  $taskSearchObj
            ->setRealmID($Data{'Realm'})
            ->setSubRealmID(0)
            ->setData(\%Data)
            ->setKeyword($searchval)
            ->setSphinx($sphinx);

			
		$results{'tasks'} = $taskSearchObj->process($strRuleFor,$nature,$type);

		@iterationItems = ('tasks');
	}
	else{
		 my $personSearchObj = new Search::Person();
		 $personSearchObj
		        ->setRealmID($Data{'Realm'})
		        ->setSubRealmID(0)
		        ->setSearchType("unique")
		        ->setData(\%Data)
		        ->setKeyword($searchval)
		        ->setSphinx($sphinx)
				->setQueryParam($otherparams);		
		    #intermediateNodes, subNodes and filters are initialised in Search/Person.pm
		    $results{'persons'} = $personSearchObj->process($rawResult);

		if($currentLevel > $Defs::LEVEL_CLUB)  {
		    my $intermediateNodes = {};
		    my $subNodes = [];
		    ($intermediateNodes, $subNodes) = getIntermediateNodes(\%Data);
		    my $filters = setupFilters(\%Data, $subNodes);
			my $entityfiltersetup = '';
			$results{'entities'} = search_entities(
				\%Data,
				$sphinx,
				$searchval,
				$filters,
				$intermediateNodes,
				'',
		  	);
		 }
		@iterationItems = ('entities','persons');
	}
   
    #for my $k (qw(entities persons tasks))  { 
	#for my $k (qw(entities tasks)){ 
	foreach my $k (@iterationItems){
      if($results{$k} and scalar(@{$results{$k}}))  {
        for my $r (@{$results{$k}})  {
          push @r, $r;
        }
      }
    }
    $output = to_json(\@r);
  }
  print "Content-type: application/x-javascript\n\n";
  print $output;
}

sub search_persons  {
  my (
    $Data,
    $sphinx,
    $searchval,
    $filters,
    $intermediateNodes,
    $subEntities,
    ) = @_;
  $sphinx->ResetFilters();
  my $realmID = $Data->{'Realm'};
  $sphinx->SetFilter('intrealmid',[$filters->{'realm'}]);

  $sphinx->SetFilter('intentityid',$filters->{'entity'}) if $filters->{'entity'};
  my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
  my $results = $sphinx->Query($searchval, $indexName);
  my @persons = ();
  if($results and $results->{'total'})  {
    for my $r (@{$results->{'matches'}})  {
      push @persons, $r->{'doc'};
    }
  }
  my @memarray = ();
  if(@persons)  {
    my $person_list = join(',',@persons);

    my $entity_list = '';
    $entity_list = join(',', @{$subEntities});
    my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
    $clubID = 0 if $clubID == $Defs::INVALID_ID;
	
    my $st = qq[
      SELECT DISTINCT
        tblPerson.intPersonID,
        tblPerson.strLocalFirstname,
        tblPerson.strLocalSurname,
        tblPerson.strNationalNum,
        tblPerson.strFIFAID,
        E.strLocalName AS EntityName,
        E.intEntityID,
        E.intEntityLevel
      FROM
        tblPerson
        INNER JOIN tblPersonRegistration_$realmID AS PR ON (
          tblPerson.intPersonID = PR.intPersonID
          AND PR.strStatus <> 'DELETED'
          AND PR.intEntityID IN ($entity_list)
        )
        INNER JOIN tblEntity AS E ON (
          PR.intEntityID = E.intEntityID
        )
      WHERE tblPerson.intPersonID IN ($person_list)
      ORDER BY 
        strLocalSurname, 
        strLocalFirstname
      LIMIT 10
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute();
    my %origClientValues = %{$Data->{'clientValues'}};

    my $numnotshown = ($results->{'total'} || 0) - 10;
    $numnotshown = 0 if $numnotshown < 0;
    while(my $dref = $q->fetchrow_hashref())  {
      my $link = getSearchLink(
        $Data,
        $Defs::LEVEL_PERSON,
        '',
        $dref->{'intPersonID'},
        $intermediateNodes,
        $dref->{'intEntityID'},
        $dref->{'intEntityLevel'},
      );            
      my $name = "$dref->{'strLocalSurname'}, $dref->{'strLocalFirstname'}" || '';
      $name .= " #$dref->{'strNationalNum'}" if $dref->{'strNationalNum'};
      $name .= "  ($dref->{'EntityName'})" if $dref->{'EntityName'};
      push @memarray, {
        id => $dref->{'intPersonID'} || next,
        label => $name,
        category => 'Persons',
        link => $link,
        numnotshown => $numnotshown,
      };
    }
  }
  return \@memarray;
}
  
sub setupFilters  {
  my ($Data, $subEntities) = @_;

  my $realm = $Data->{'Realm'} || 0;
  my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
  $clubID = 0 if $clubID < 0;
  my %filters = (
    realm => $realm,
    club => $clubID,
  );
  if($subEntities)  {
        $filters{'entity'} = $subEntities;
  }

  return \%filters;
}


sub search_entities  {
  my (
    $Data,
    $sphinx,
    $searchval,
    $filters,
    $intermediateNodes,
	$entityfilter,
  ) = @_;
  $sphinx->ResetFilters();
  $sphinx->SetFilter('intrealmid',[$filters->{'realm'}]);
  #$sphinx->SetFilter('intentitylevel',[3]);
  my $results = $sphinx->Query($searchval, 'FIFA_Entities_r'.$filters->{'realm'});
  
  my @matchlist = ();
  if($results and $results->{'total'})  {
    for my $r (@{$results->{'matches'}})  {
      push @matchlist, $r->{'doc'};
    }
  }
  my @dataarray = ();
  if(@matchlist)  {
    my $id_list = join(',',@matchlist);
    my $st = qq[
      SELECT 
        intEntityID,
        strLocalName,
        intEntityLevel
      FROM
        tblEntity
        INNER JOIN tblTempEntityStructure AS TES
          ON TES.intChildID = tblEntity.intEntityID

      WHERE intEntityID IN ($id_list)
        AND  intEntityLevel < ? AND intEntityLevel <> $Defs::LEVEL_VENUE
        AND TES.intParentID = ?
        AND TES.intDataAccess >= $Defs::DATA_ACCESS_READONLY
		$entityfilter
      ORDER BY 
        strLocalName 
      LIMIT 10
    ];


	my $q = $Data->{'db'}->prepare($st);
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'} || 0;
    $q->execute(
        $currentLevel,
        getID($Data->{'clientValues'}),
    );

    my $numnotshown = ($results->{'total'} || 0) - 10;
    $numnotshown = 0 if $numnotshown < 0;
    while(my $dref = $q->fetchrow_hashref())  {
      my $link = getSearchLink(
        $Data,
        $dref->{'intEntityLevel'},
        '',
        $dref->{'intEntityID'},
        $intermediateNodes,
      );
      my $name = $dref->{'strLocalName'} || '';
      push @dataarray, {
        id => $dref->{'intEntityID'} || next,
        label => $name,
        category => $Data->{'lang'}->txt('Organisations'),
        link => $link,
        numnotshown => $numnotshown,
      };
    }
  }
  return \@dataarray;
}

sub getSearchLink  {
  my (
    $Data,
    $level,
    $field,
    $value,
    $intermediateNodes,
    $entityID,
    $entityLevel,
  ) = @_;

  my %tempClientValues = %{$Data->{'clientValues'}};
  $field ||= getClientFieldKey($level);
  my %actions=(
    $Defs::LEVEL_PERSON => 'P_HOME',
    $Defs::LEVEL_CLUB => 'C_HOME',
    $Defs::LEVEL_ZONE => 'E_HOME',
    $Defs::LEVEL_REGION => 'E_HOME',
    $Defs::LEVEL_STATE => 'E_HOME',
    $Defs::LEVEL_NATIONAL => 'E_HOME',
    $Defs::LEVEL_INTZONE => 'E_HOME',
    $Defs::LEVEL_INTREGION => 'E_HOME',
    $Defs::LEVEL_INTERNATIONAL => 'E_HOME',
  );

  my $structlevel = $level || 0;
  my $structvalue = $value || 0;
  if($level == $Defs::LEVEL_PERSON)    {
      $structlevel = $entityLevel;
      $structvalue = $entityID || 0;
  }

  for my $k (keys %{$intermediateNodes->{$structlevel}{$structvalue}})  {
    if(
      !$tempClientValues{$k} 
      or ($tempClientValues{$k} and $tempClientValues{$k} == $Defs::INVALID_ID )
    )  {
      $tempClientValues{$k} = $intermediateNodes->{$structlevel}{$structvalue}{$k} || 0;
    }
  }
  $tempClientValues{$field} = $value;
  $tempClientValues{currentLevel} = $level;
  my $tempClient = setClient(\%tempClientValues);

  my $act = $actions{$level};
  my $url = "$Data->{'target'}?client=$tempClient&amp;a=$act";

  return $url;
}

sub getIntermediateNodes {
  my(
    $Data, 
  ) = @_;

  my $currentLevel = $Data->{'clientValues'}{'currentLevel'} || 0;
  my $currentID = getID($Data->{'clientValues'}) || 0;
  return undef if !$currentLevel;
  return undef if !$currentID;

  my $field = '';
  $field = 'int100_ID' if $currentLevel == $Defs::LEVEL_NATIONAL;
  $field = 'int30_ID' if $currentLevel == $Defs::LEVEL_STATE;
  $field = 'int20_ID' if $currentLevel == $Defs::LEVEL_REGION;
  $field = 'int10_ID' if $currentLevel == $Defs::LEVEL_ZONE;
  $field = 'int3_ID' if $currentLevel == $Defs::LEVEL_CLUB;

  my $st = qq[
    SELECT 
      int100_ID,
      int30_ID,
      int20_ID,
      int10_ID,
      int3_ID
    FROM tblTempTreeStructure
    WHERE
      intRealmID = ?
      AND $field = ?
  ];
      #AND intPrimary = 1
  my $q = $Data->{'db'}->prepare($st);
  $q->execute(
    $Data->{'Realm'},
    $currentID,
  );
  
  my %intermediateNodes = ();
  my %nodes = ();
  while(my $dref = $q->fetchrow_hashref())  {
    my $zoneID = $dref->{'int10_ID'} || 0;
    my $regionID = $dref->{'int20_ID'} || 0;
    my $stateID = $dref->{'int30_ID'} || 0;
    my $nationalID = $dref->{'int100_ID'} || 0;
    my $clubID = $dref->{'int3_ID'} || 0;
    #if($currentLevel <= $Defs::LEVEL_NATIONAL)  {
      #$nationalID = 0;
    #}
    #if($currentLevel <= $Defs::LEVEL_STATE)  {
      #$stateID = 0;
    #}
    #if($currentLevel <= $Defs::LEVEL_REGION)  {
      #$regionID = 0;
    #}
    #if($currentLevel <= $Defs::LEVEL_ZONE)  {
      #$zoneID = 0;
    #}
    #if($currentLevel <= $Defs::LEVEL_CLUB)  {
      #$clubID = 0;
    #}
    $intermediateNodes{$Defs::LEVEL_STATE}{$stateID} = {
      natID => $nationalID || 0,  
    };
    $intermediateNodes{$Defs::LEVEL_REGION}{$regionID} = {
      natID => $nationalID || 0,  
      stateID => $stateID || 0,  
    };
    $intermediateNodes{$Defs::LEVEL_ZONE}{$zoneID} = {
      natID => $nationalID || 0,  
      stateID => $stateID || 0,  
      regionID => $regionID || 0,  
    };
    $intermediateNodes{$Defs::LEVEL_CLUB}{$clubID} = {
      natID => $nationalID || 0,  
      stateID => $stateID || 0,  
      regionID => $regionID || 0,  
      zoneID => $zoneID || 0,  
      clubID => $clubID || 0,  
    };
    $nodes{$nationalID || 0} = 1;
    $nodes{$stateID || 0} = 1;
    $nodes{$regionID || 0} = 1;
    $nodes{$zoneID || 0} = 1;
    $nodes{$clubID || 0} = 1;
  }
  delete $nodes{0};
  delete $nodes{-1};
  my @nodes = keys %nodes;
  return (\%intermediateNodes, \@nodes);
}


