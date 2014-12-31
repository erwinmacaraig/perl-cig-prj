package ITC_TransferCertificate;

use strict;
use lib '.', '..', '../..';
use CGI;
use FieldLabels;
use Countries;
use Reg_common;
use TTTemplate;
use Defs;


sub show_itc_request_form {	
	my ($Data) = @_;
	my $isocountries  = getISOCountriesHash();
    my %countriesonly = ();
    my %Mcountriesonly = ();
	
	
    my @limitCountriesArr = ();
    while(my($k,$c) = each(%{$isocountries})){
    	$countriesonly{$k} = $c;
    	if(@limitCountriesArr){
    		next if(grep(/^$k/, @limitCountriesArr));
    	}
    	$Mcountriesonly{$c} = $c;
    }
	my $FieldLabelsPerson = FieldLabels::getFieldLabels($Data, $Defs::LEVEL_PERSON);
	my %FieldDefinitions=(		
   		    	strLocalFirstname => {
   		    		label => $FieldLabelsPerson->{'strLocalFirstname'},
   		    		type => 'text',
   		    		size  => '50',
                	compulsory => 1,
   		    		name => 'strLocalFirstname',
   		    	},
   		    	strLocalSurname => {   		    		
					label => $FieldLabelsPerson->{'strLocalSurname'},   		    			
					type => 'text',
					size => '50',					
                	compulsory => 1,  
					name => 'strLocalSurname', 		    		
   		    	},
   		    	dtDOB => {   		    	
   		    		label => $FieldLabelsPerson->{'dtDOB'},
   		    		type => 'date',
   		    		size => '20',
                    datetype    => 'dropdown',
					name => 'dtDOB',
                    validate    => 'DATE',
   		    	},
   		    	strISONationality => {   		    	
   		    		label => $FieldLabelsPerson->{'strISONationality'},
   		    		options => \%Mcountriesonly, 
   		    		name => 'strISONationality',
   		    		class => 'chzn-select',
   		    	},
   		    	strPlayerID => {   		    		
   		    		label => 'Player\'s ID(Previous Football Association, if available)',
   		    		name => 'strPlayerID',
   		    		type => 'text',
   		    		size => '50',
   		    	},  
   		    	strISOCountry => {   		    	
   		    		label => $FieldLabelsPerson->{'strISOCountry'},
   		    		name	=> 'strISOCountry',
   		    		class   => 'chzn-select',
   		    	},
   		    	strClubName => {   		    	
   		    		label => 'Club\'s Name',
   		    		type => 'text',
   		    		value => '',
					size => '50',
					name => 'strClubName',
   		    	},
   	); #end of FieldDefinitions

	my $resultHTML = runTemplate($Data, \%FieldDefinitions, 'person/request_itc_form.templ');

	return ($resultHTML, 'Request Form For An International Transfer Certificate');
	
}
1;

