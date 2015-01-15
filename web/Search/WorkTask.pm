package Search::WorkTask;

use strict;
use lib '.', '..', '../..';
use Search::Base;
our @ISA = qw(Search::Base);

use Defs;
use Data::Dumper;
use Switch;
use Reg_common;
sub process {
    my ($self) = shift;
	
	my ($strWFRuleFor,$strRegistrationNature,$strPersonType) = @_;
	$strPersonType ||= '';
	$strRegistrationNature ||= '';
	my ($intermediateNodes, $subNodes) = $self->getIntermediateNodes(1); # $subnodes contains intEntityID
    my $filters = $self->setupFilters($subNodes);

    my $realmID = $self->getData()->{'Realm'};
    $self->getSphinx()->ResetFilters();
    $self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);

    $self->getSphinx()->SetFilter('intentityid', $filters->{'entity'}) if $filters->{'entity'};
  	my $indexName;
	my $results;
	my @matchlist = ();

	#my $indexName = $Defs::SphinxIndexes{'Person'}.'_r'.$filters->{'realm'};
	#my $results = $self->getSphinx()->Query($self->getKeyword(), $indexName);
    #my @persons = ();
	#
	my @taskids = ();
	my $st;
    #if($results and $results->{'total'})  {
    #    for my $r (@{$results->{'matches'}})  {
    #        push @persons, $r->{'doc'};
    #    }
    #}
	

	my @memarray = ();
	my $query = qq[SELECT intWFRuleID FROM tblWFRule WHERE strWFRuleFor = ? AND strRegistrationNature = ? AND strPersonType = ? AND intApprovalEntityLevel = ? AND intRealmID = ?];



	my $q = $self->getData->{'db'}->prepare($query);
    $q->execute($strWFRuleFor,$strRegistrationNature,$strPersonType,$self->getData()->{'clientValues'}{'currentLevel'},$realmID);    
	while(my $dref = $q->fetchrow_hashref()){
		push @taskids,$dref->{'intWFRuleID'};
	}
	my $taskids_list = '';
	$taskids_list = join(',',@taskids);

	my $client = setClient($self->getData()->{'clientValues'});
        #my $person_list = join(',',@persons);

        my $entity_list = '';
        $entity_list = join(',', @{$subNodes});

        #my $clubID = $self->getData()->{'clientValues'}{'clubID'} || 0; 
        #$clubID = 0 if $clubID == $Defs::INVALID_ID;


	switch($strWFRuleFor){
		case 'REGO' {
			my $keywordsearch = $self->getKeyword();
			$keywordsearch =~ s/[,\-\']+//g;
			$st = qq[
					SELECT DISTINCT
				    tblPerson.intPersonID,
				    tblPerson.strLocalFirstname,
				    tblPerson.strLocalSurname,
				    tblPerson.strNationalNum,
				    tblPerson.strFIFAID,
				    tblPerson.dtDOB,
				    E.strLocalName AS EntityName,
				    E.intEntityID,
				    E.intEntityLevel,
					T.intWFTaskID
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
			INNER JOIN tblWFTask T ON ( 
				T.intPersonID = tblPerson.intPersonID
				AND
				T.intPersonRegistrationID = PR.intPersonRegistrationID
				AND
				T.strTaskStatus = 'ACTIVE'
				AND 
				T.intWFRuleID IN ($taskids_list)				
			)
			WHERE tblPerson.strLocalFirstname LIKE '%$keywordsearch%' OR tblPerson.strLocalSurname LIKE '%$keywordsearch%'];
			$q = $self->getData->{'db'}->prepare($st);
      		$q->execute();
				
			while(my $dref = $q->fetchrow_hashref()){
				 my $name = "$dref->{'strLocalSurname'}, $dref->{'strLocalFirstname'}" || '';
				 $name .= "  ($dref->{'EntityName'})" if $dref->{'EntityName'};
				 my $link =  $self->getData()->{'target'} . "?client=$client&amp;a=WF_View&TID=".$dref->{'intWFTaskID'};
				push @memarray, {
           			 id => $dref->{'intPersonID'} || next,
           			 label => $name,
           			 category => 'Persons',
          			 link => $link,
            		 #numnotshown => $numnotshown,            
         	    };
			}

		}
		case 'ENTITY' {
			$self->getSphinx()->ResetFilters();
			$self->getSphinx()->SetFilter('intrealmid', [$filters->{'realm'}]);
			$indexName = $Defs::SphinxIndexes{'Entity'}.'_r'.$filters->{'realm'};
			$results = $self->getSphinx()->Query($self->getKeyword(), $indexName);
		
 	   		if($results and $results->{'total'})  {
    			for my $r (@{$results->{'matches'}})  {
      				push @matchlist, $r->{'doc'};
    			}
  			}

			if(@matchlist)  {
   				my $id_list = join(',',@matchlist);
				$st = qq[ SELECT 
       					 tblEntity.intEntityID,
        				 tblEntity.strLocalName,
       					 tblEntity.intEntityLevel,
						 T.intWFTaskID
     				 FROM
        				tblEntity
  				    INNER JOIN tblTempEntityStructure AS TES
       				    ON TES.intChildID = tblEntity.intEntityID
					INNER JOIN tblWFTask T ON ( 
						T.intEntityID = tblEntity.intEntityID
						AND
						T.strTaskStatus = 'ACTIVE'
						AND 
						T.intWFRuleID IN ($taskids_list)	
					)				
      				WHERE tblEntity.intEntityID IN ($id_list)
      				   AND intEntityLevel < ?
       		          AND TES.intParentID = ?
        	          AND TES.intDataAccess >= $Defs::DATA_ACCESS_READONLY
     				ORDER BY 
       				 strLocalName 
     			 LIMIT 10];
				my $currentLevel = $self->getData()->{'clientValues'}{'currentLevel'} || 0;
               
			# 
				
				$q = $self->getData->{'db'}->prepare($st);
      			$q->execute(
					$currentLevel,
					getID($self->getData()->{'clientValues'})
				);
				 my $numnotshown = ($results->{'total'} || 0) - 10;
    			$numnotshown = 0 if $numnotshown < 0;
				while(my $dref = $q->fetchrow_hashref()){
					  my $name = $dref->{'strLocalName'} || '';
					  my $link =  $self->getData()->{'target'} . "?client=$client&amp;a=WF_View&TID=".$dref->{'intWFTaskID'};
					  push @memarray, {
                     	 id => $dref->{'intEntityID'} || next,
        				 label => $name,
						 link => $link,
					}
			   }
			}

		}

		
	}


		
		
        
			#WHERE tblPerson.intPersonID IN ($person_list)


			#my $numnotshown = ($results->{'total'} || 0) - 10;
   			#$numnotshown = 0 if $numnotshown < 0;
			

	
	
	

	return \@memarray;

}
1;
