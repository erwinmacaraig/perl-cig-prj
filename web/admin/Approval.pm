package approval;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    list_tasks
);
@EXPORT_OK = qw(
    list_tasks
);

use lib "..","../..";
use DBI;
use CGI qw(param unescape escape);
use strict;
use Defs;
use Utils;
use AdminCommon;
use TTTemplate;
use Data::Dumper;
# use HTML::FillInForm;

sub list_tasks {
    my(
        $db,
        $roleID,
        $WFTaskID,
    ) = @_;
    
    
    if ($WFTaskID) {
    	fncApproveTask($db, $WFTaskID)
    }
    
    my $st = qq[
		SELECT r.intRoleID, p.strFirstName, p.strSurname, e.strLocalName, r.strTitle
		FROM tblRole r
		INNER JOIN tblEntity e on r.intEntityID = e.intEntityID
		INNER JOIN tblPersonRole pr on r.intRoleID = pr.intRoleID
		INNER JOIN tblPerson p on pr.intPersonID = p.intPersonID
        ORDER BY r.intRoleID
    ];
 
    my $query = $db->prepare($st);
    $query->execute();
    my $body = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{intRoleID}</td>
	        <td class="listborder">$dref->{strFirstName} $dref->{strSurname}</td>
	        <td>&nbsp;</td>
	        <td class="listborder"><a href="approval.cgi?RID=$dref->{intRoleID}">$dref->{strLocalName} - $dref->{strTitle}</a></td>
	      </tr>
	    ];
    }
    

    $body = '<h1>Select your current Role</h1>'
    	. '<p><a href="registration.cgi">Registration</a>'
    	. '<table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>RoleID</th><th>Name</th><th>&nbsp;</th><th>Entity/Role</th></tr>' 
	    . $body . 
	    '</table>';

    if (!$roleID) {
    	return($body);	
    }    

    $body .= '<h1>Approve any outstanding tasks</h1><table cellpadding="5">'
	    . '<tr style="margin: 10px;"><th>TaskID</th><th>Name</th><th>Status</th><th>TaskType</th><th>PersonLevel</th><th>AgeLevel</th><th>Sport</th><th>Registration<br>Type</th><th>Document</th><th>&nbsp;</th><th>Approve</th><th>Reject</th></tr>';

    $st = qq[
		SELECT t.intWFTaskID, t.strTaskStatus, t.strTaskType, pr.strPersonLevel, pr.strAgeLevel, pr.strSport, pr.strRegistrationType, dt.strDocumentName,
		p.strFirstName, p.strSurName, p.intPersonID
		FROM tblWFTask t
		INNER JOIN tblPersonRegistration pr ON t.intPersonRegistrationID = pr.intPersonRegistrationID
		INNER JOIN tblPerson p on t.intPersonID = p.intPersonID
		LEFT OUTER JOIN tblDocumentType dt ON t.intDocumentTypeID = dt.intDocumentTypeID
		WHERE t.intWFRoleID = ?
		ORDER BY p.strSurname, p.strFirstname, p.intPersonID, t.strTaskType, dt.strDocumentName
    ];
 
    $query = $db->prepare($st);
    $query->execute($roleID);


    my $link = '';
    
    while(my $dref= $query->fetchrow_hashref()) {
	        if ($dref->{strTaskStatus} eq 'ACTIVE') {
        		$link = qq[<td class="listborder"><a href="approval.cgi?RID=$roleID&TID=$dref->{intWFTaskID}">Approve</a></td><td class="listborder">Reject</td>]
	        }
	        else {
        		$link = qq[<td class="listborder">&nbsp;</td><td class="listborder">&nbsp;</td>]
	        }
     	
	    $body .= qq[
	      <tr>
	        <td class="listborder">$dref->{intWFTaskID}</td>
	        <td class="listborder">$dref->{strFirstName} $dref->{strSurName}</td>
	        <td class="listborder">$dref->{strTaskStatus}</td>
	        <td class="listborder">$dref->{strTaskType}</td>
	        <td class="listborder">$dref->{strPersonLevel}</td>
	        <td class="listborder">$dref->{strAgeLevel}</td>
	        <td class="listborder">$dref->{istrSport}</td>
	        <td class="listborder">$dref->{strRegistrationType}</td>
	        <td class="listborder">$dref->{strDocumentName}</td>
	        <td>&nbsp;</td>
	   		$link
	      </tr>
	    ];
    }
    
    return $body . '</table>';

    
}

sub fncApproveTask {
    my(
        $db,
        $WFTaskID,
    ) = @_;
	
	#Q - Add in the PersonID of whoever is logged on
	my $st = '';
	my $q = '';
	my $query = '';
	
	#First update this task to COMPLETE
	$st = qq[
	  	UPDATE tblWFTask SET 
	  		strTaskStatus = 'COMPLETE',
	  		dtApprovedDate = Now(),
	  		intApprovedPersonID = 1
	  	WHERE intWFTaskID = ?; 
		];
		
  	$q = $db->prepare($st);
  	$q->execute(
  		$WFTaskID,
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}
	
    $st = qq[
        SELECT intPersonRegistrationID
        FROM tblWFTask
        WHERE intWFTaskID = ?
    ];
        
    $q = $db->prepare($st);
    $q->execute($WFTaskID);
            
    my $dref= $q->fetchrow_hashref();
    my $PersonRegistrationID = $dref->{intPersonRegistrationID};
		
	#As a result of this update, check to see if there are any Tasks that now have all their pre-reqs completed
	$st = qq[	
		SELECT distinct pt.intWFTaskID, ct.strTaskStatus 
		FROM tblWFTask pt
		INNER JOIN tblWFTaskPreReq ptpr ON pt.intWFTaskID = ptpr.intWFTaskID
		INNER JOIN tblWFTask ct on ptpr.intPreReqWFRuleID = ct.intWFRuleID 
		WHERE pt.intPersonRegistrationID = ? 
		AND pt.strTaskStatus = ?
		AND ct.intPersonRegistrationID = ?
		AND ct.strTaskStatus IN (?,?)
		ORDER by pt.intWFTaskID;
	];
	
	$q = $db->prepare($st);
  	$q->execute(
  		$PersonRegistrationID,
  		'PENDING',
  		$PersonRegistrationID,
  		'ACTIVE',
  		'COMPLETE',
  		);
  		
	if ($q->errstr) {
		return $q->errstr . '<br>' . $st
	}

	my $prev_WFTaskID = 0;
   	my $updateThisTask = '';
   	my $pfx = '';
   	my $list_WFTaskID = '';
   	my $update_count = 0;
   	my $count = 0;
   		
   	#Should be a cleverer way to do this, but check all the Pending Tasks and see if all of their
   	# pre-reqs have been completed. If so, update their status from Pending to Active.
	while(my $dref= $q->fetchrow_hashref()) {
		++ $count;
		
	
   		if ($dref->{intWFTaskID} != $prev_WFTaskID) {
   			if ($prev_WFTaskID != 0) {
   				if ($updateThisTask eq 'YES') {
   					$list_WFTaskID .= $pfx . $prev_WFTaskID;
   					$pfx = ",";
					++ $update_count;
			   			}
   			}
   			$updateThisTask = 'YES';
   			$prev_WFTaskID = $dref->{intWFTaskID};
   		}
   		
   		if ($dref->{strTaskStatus} eq 'ACTIVE') {
   			$updateThisTask = "nope";
   		}
    }
   	if ($prev_WFTaskID != 0) {
   		if ($updateThisTask eq 'YES') {
   			$list_WFTaskID .= $pfx . $prev_WFTaskID;
			++ $update_count;
		}
   	}
	 
	if ($update_count > 0) {
		#Update the Tasks to Active as their pre-reqs have been completed
		$st = qq[
		  	UPDATE tblWFTask SET 
		  		strTaskStatus = 'ACTIVE',
		  		dtActiveDate = Now(),
		  		intActivePersonID = 1
		  	WHERE intWFTaskID IN ($list_WFTaskID); 
			];
			
	  	$q = $db->prepare($st);
	  	$q->execute();
	  		
		if ($q->errstr) {
			return $q->errstr . '<br>' . $st
		}
		

    
	} 
else {	
		# Nothing to update. Do a check to see if there all tasks have been completed
		$st = qq[
            SELECT count(*) as NumRows
            FROM tblWFTask
            WHERE intPersonRegistrationID = ?
			AND strTaskStatus IN (?,?)
        ];
        
        $q = $db->prepare($st);
        $q->execute(
       		$PersonRegistrationID,
	  		'PENDING',
	  		'ACTIVE'
	  	);
  
        
        if (!$q->fetchrow_array()) {
            $st = qq[
            	UPDATE tblPersonRegistration SET
            	strStatus = ?,
            	dtFrom = Now()
    	        WHERE intPersonRegistrationID = ?
        ];
    
        $q = $db->prepare($st);
        $q->execute(
        	'ACTIVE',
       		$PersonRegistrationID
  			);         
        }
}      
    
       	
}


