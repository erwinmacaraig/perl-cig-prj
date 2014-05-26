#
# $Header: svn://svn/SWM/trunk/web/ProcessLogDisplay.pm 8251 2013-04-08 09:00:53Z rlee $
#

package ProcessLogDisplay;

require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(handleProcessLog);
@EXPORT_OK=qw(handleProcessLog);

use strict;
use ProcessLog;
use Utils;
use List qw(list_row list_headers);
use Reg_common;
use GridDisplay;

sub handleProcessLog{
	my ($action, $Data)=@_;

    my $assocID = $Data->{'clientValues'}{'assocID'};
    #my $compID =  $Data->{'clientValues'}{'compID'};

    my $resultHTML='';
   	my $title='';
    
    if ($action eq 'PROCESSLOG_L') {
        ($resultHTML,$title)=list_processlog($Data, $assocID);
    }
    
	return ($resultHTML,$title);
}

sub list_processlog {
    my ($Data, $assocID) = @_;
    
    my $pl = new ProcessLog('DB'=>$Data->{db});
    my $Processes = $pl->get_processes('','',$assocID);
    my $RunProcesses = $pl->get_processes_run($assocID);
    push @{$Processes}, @{$RunProcesses};

    my $resultHTML = '';
    
    my $txtName  = 'Process';
    my $txtNames = 'Processes';
    
   	my $found = 0;
		my $Comps = AssocObj->getComps($Data,$assocID,1);
	    
    my @rowdata = ();
    foreach my $process (@{$Processes}) {
    	$process->{compname} = $Comps->{$process->{compID}};
			push @rowdata, {
      	id => $found,
				compname => $process->{'compname'},
				name => $process->{'name'},
				added => $process->{'added'},
				started => $process->{'started'},
				ended => $process->{'ended'},
    	};
      $found++;
	}


	my $numlist=($found and $found > 1)? qq[<div class="tablecount">$found rows found</div>] : '';
	my @headerdata = (
    {
      name => 'Competition',
      field => 'compname',
    },
    {
      name => "$txtName",
      field => 'name',
    },
    {
      name => 'Date Added',
      field => 'added',
    },
    {
      name => 'Date Started',
      field => 'started',
    },
    {
      name => 'Date Completed',
      field => 'ended',
    },
  );
	if($found==0)   {
		$resultHTML = textMessage("No $txtNames can be found."); 
	}
	else  {
		$resultHTML = showGrid(
      Data => $Data,
			columns => \@headerdata,
			rowdata => \@rowdata,
			gridid => 'grid',
			width => '99%',
			height => 700,
		);
	}

  	return ($resultHTML,'Process Log');
}

