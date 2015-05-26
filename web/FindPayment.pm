
package FindPayment;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handePayInvoice );
@EXPORT_OK = qw(handleFindPayment );

use strict;
use CGI qw(param unescape escape);

use lib '.';
use Reg_common;
use Defs;
use Utils;
use FormHelpers;
use HTMLForm;
use AuditLog;

use InvoicePay;
require Payments;
require TransLog;
require PersonRegistration;
use TTTemplate;
use Payments;
use Data::Dumper;

use GridDisplay;

sub handleFindPayment {
	my($action, $Data, $clubID)=@_;

	my $resultHTML = '';
  	my $title = 'Find Payment';
	my $Number = param('strNumber') || '';
	$Number =~ s/^\s+//;
    my $client = setClient($Data->{'clientValues'}) || '';
	$resultHTML = displayFindPaymentForm($Data, $clubID, $client);
    

	if($action eq 'TXN_FIND_NUM'){
	    $resultHTML = queryFindByNumber($a, $Data, $Number, $client);
	}
    if ( $action eq 'TXN_FIND_VIEW') {
        my $entityID = getLastEntityID($Data->{'clientValues'});
        ( $resultHTML, $title ) = TransLog::handleTransLogs('payVIEW', $Data, $entityID, 0);
    }
	return ($resultHTML,$title);
}

sub displayFindPaymentForm  {
	my ($Data,$clubID, $client) = @_; 
	my %pagecontent = (
			client =>  $client, 
			a => 'TXN_FIND_NUM', 
			Lang => $Data->{'lang'},
	);
	my $form = runTemplate($Data, \%pagecontent,'payment/search_payments.templ');	
   return $form;
	
} 

sub queryFindByNumber { 
	my ($action, $Data, $findNumber, $client) = @_;	
	my $totalAmount = 0;
	
	my $content = '';
	my $results = 0;
	my @rowdata = ();
	my $intEntityID = getEntityID($Data->{'clientValues'});

	my $query = qq[
		SELECT 
            *
        FROM
            tblTransLog
        WHERE
            intRealmID = ?
            AND (
                strOnlinePayReference = ?
                OR strTXN= ?
            )
	];
	
		#get authlevel
		if($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB){			
			$query .= qq[ AND intEntityPaymentID = $intEntityID ];			
		}
		elsif($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION){
			my $subquery = qq[SELECT intChildEntityID FROM tblEntityLinks WHERE intParentEntityID = $intEntityID];
			my $st = $Data->{'db'}->prepare($subquery);
			my @clubs = ();
			$st->execute();
			while(my $dref = $st->fetchrow_hashref()){
				push @clubs, $dref->{'intChildEntityID'};
			}
			$query .= qq[ AND intEntityPaymentID IN ('', ] . join(',',@clubs) . q[)];
		}
	#
	my $sth = $Data->{'db'}->prepare($query) or print STDERR "DDD";
	$sth->execute(
        $Data->{'Realm'},
        $findNumber,
        $findNumber
    );
	my $cl=setClient($Data->{'clientValues'}) || '';
    my %cv=getClient($cl);    
	while(my $dref = $sth->fetchrow_hashref()){
		$results = 1;
		$totalAmount += $dref->{'TotalAmount'};
        my $clm=setClient(\%cv);
		push @rowdata, {
			id => $dref->{'intLogID'},
			SelectLink => qq[$Data->{'target'}?client=$clm&amp;a=TXN_FIND_VIEW&tlID=$dref->{intLogID}],
			txnnumber=> $dref->{'strTXN'} || '-',
            otherref => $dref->{'strOtherRef2'},
			paymentDate =>  $Data->{'l10n'}{'date'}->TZformat($dref->{'dtLog'},'MEDIUM','SHORT'), 
			amount => $Data->{'l10n'}{'currency'}->format($dref->{'intAmount'}),
			status => $Defs::TransLogStatus{$dref->{'intStatus'}},			
			paymentType=> $Defs::paymentTypes{$dref->{'intPaymentType'}},			
			paymentDateSortColumn => $dref->{'dtLog'},
			strOnlinePayReference=> $dref->{'strOnlinePayReference'} || $dref->{'intLogID'},
		};
		
	}

    my @headers = (
	{
		name => '', 
		field => 'SelectLink', 
	    type => 'Selector', 
	},
	{
		name => $Data->{'lang'}->txt('Payment Reference Number'),
		field => 'strOnlinePayReference', 
	},
	{
		name => $Data->{'lang'}->txt('Bank Reference'),
		field => 'txnnumber', 
	},
	{
      name => $Data->{'lang'}->txt('Payment Date'),
      field => 'paymentDate',
	  sortdata => 'paymentDateSortColumn',
    },
	{
		name => $Data->{'lang'}->txt('Amount'),
		field => 'amount',
	},
	{
		name => $Data->{'lang'}->txt('Payment Type'),
		field => 'paymentType',
	},
	{
		name => $Data->{'lang'}->txt('Status'),
		field => 'status', 
	}
	);
	 my $grid  = showGrid(
   		 Data => $Data,
     	 columns => \@headers,
   		 rowdata => \@rowdata,   	    
   	     gridid => 'grid',
  	     width => '99%',
    );

 return   qq[
            <div style="clear:both">&nbsp;</div>
            <div class="clearfix">
                    $grid
            </div>
        ];

## end payment settings
	my %PageData = (
		grid => $grid, 
        Lang => $Data->{'lang'},
        client => $client,
	);
	 my $body = $content;
	 return $body if($results);
	 return $results;
	
}

1;
