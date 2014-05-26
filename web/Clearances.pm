#
# $Header: svn://svn/SWM/trunk/web/Clearances.pm 10771 2014-02-21 00:20:57Z cgao $
#

package Clearances;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(checkAutoConfirms handleClearances clearanceHistory sendCLREmail finaliseClearance);
@EXPORT_OK = qw(checkAutoConfirms handleClearances clearanceHistory sendCLREmail finaliseClearance);

use strict;
use CGI qw(param unescape escape);
use Reg_common;
use Utils;
use HTMLForm;
use ClearancesList;
use FormHelpers;
use DeQuote;
use AuditLog;
use Mail::Sendmail;
use SearchLevels;

use Seasons;
use ServicesContacts;
use GridDisplay;
use Data::Dumper;
use ContactsObj;
use DefCodes;
sub handleClearances	{
    ### PURPOSE: main function to handle clearances.

	my($action,$Data)=@_;

	
	my $q=new CGI;
        my %params=$q->Vars();

	my $clearanceID = $params{'cID'} || 0;
	my $clearancePathID = $params{'cpID'} || 0;
	my $txt_RequestCLR = $Data->{'SystemConfig'}{'txtRequestCLR'} || 'Request a Clearance';
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	return (clearances_create(),$txt_RequestCLR) if $action eq 'CL_create';
	return (createClearance($action, $Data), $txt_RequestCLR) if $action eq 'CL_createnew';
	return (clearances_currentstatus(),'Clearance Status') if $action eq 'CL_currentstatus';
	return (clearancePathDetails($Data, $clearanceID, $clearancePathID), 'Clearance Status Selection') if $action eq 'CL_details';
	return (listClearances($Data), $txt_RequestCLR) if $action eq 'CL_list';
	return (listOfflineClearances($Data), $txt_RequestCLR) if $action eq 'CL_offlist';
	return (clearanceView($Data, $clearanceID), 'Clearance Details') if $action eq 'CL_view';
	return (clearanceCancel($Data, $clearanceID), "Cancel $txt_Clr") if $action eq 'CL_cancel';
	return (clearanceReopen($Data, $clearanceID), "Reopen $txt_Clr") if $action eq 'CL_reopen';
	return (clearanceAddManual($Data), "Add Manual $txt_Clr") if $action eq 'CL_addmanual';
	return (clearanceAddManual($Data), "Edit Manual $txt_Clr") if $action eq 'CL_editmanual';


}

sub clearanceCancel	{
### PURPOSE: To allow the Destination Club (club who requested the clearance), to cancel it. This function is called when the destination Club views the clearance (after clicking on the clearance in "List Clearances").
### The club can reopen it at any stage. See clearanceReopen(). 

	my ($Data, $clearanceID) = @_;
	my $db = $Data->{'db'};
	$clearanceID ||= 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	return qq[Clearance Unabled to be cancelled] if (! $clubID or ! $clearanceID);
  	my $client=setClient($Data->{'clientValues'}) || '';

	 my $st = qq[
                SELECT
                        intMemberID,
                        intDestinationClubID,
                        intSourceClubID,
                        intSourceAssocID,
                        intDestinationAssocID,
                        dtPermitTo,
			intPermitType , 
			IF(CONCAT(DATE_FORMAT(dtPermitTo,'%Y-%m-%d'), ' 23:59:59') < NOW(), 1 , 0) as EndPermit
                FROM
                        tblClearance
                WHERE
                        intClearanceID = $clearanceID
        ]; 
#IF(dtPermitTo < NOW(), 1 , 0) as EndPermit
        my $qry= $db->prepare($st);
        $qry->execute or query_error($st);
        my ($intMemberID, $intDestinationClubID, $intSourceClubID, $intSourceAssocID, $intDestinationAssocID, $dtPermitTo, $intPermitType, $endPermit) = $qry->fetchrow_array();

	$st = qq[
		UPDATE tblClearance
		SET intClearanceStatus = $Defs::CLR_STATUS_CANCELLED
		WHERE intClearanceID = $clearanceID
			AND intDestinationClubID = $clubID
	];
	$db->do($st);
	$st = qq[
		UPDATE tblClearancePath as CP INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
		SET CP.intClearanceStatus = $Defs::CLR_STATUS_CANCELLED
		WHERE CP.intClearanceID = $clearanceID
			AND CP.intClearanceStatus = $Defs::CLR_STATUS_PENDING
			AND CP.intDestinationClubID = $clubID
	];
	if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $endPermit and $intPermitType)	{
		clearanceReversePermit($Data, $intMemberID, $intSourceAssocID, $intSourceClubID, $intDestinationAssocID, $intDestinationClubID, $dtPermitTo);
	}
	sendCLREmail($Data, $clearanceID, 'CANCELLED');
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
  auditLog($clearanceID, $Data, 'Cancelled','Clearance');
	return qq[<p>$txt_Clr Cancelled</p><br> <a href="$Data->{'target'}?a=CL_list&amp;client=$client">Return to $txt_Clr Listing</a> ] ;
}

sub clearanceReopen	{

### PURPOSE: To allow the Destination Club (club who requested the clearance), to reopen it, if they cancelled it at any stage. This function is called when the destination Club views the clearance (after clicking on the clearance in "List Clearances").

### See the above function clearanceCancel() for how the destination club actually cancels it.
	my ($Data, $clearanceID) = @_;
	my $db = $Data->{'db'};
	$clearanceID ||= 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	return qq[$txt_Clr Unabled to be cancelled] if (! $clubID or ! $clearanceID);
  	my $client=setClient($Data->{'clientValues'}) || '';

my $st = qq[
      SELECT
        C.intClearanceID, 
				C1.strName as DestinationClubName, 
				C2.strName as SourceClubName, 
				A1.intAssocID  as DestinationAssocID, 
				A2.intAssocID as SourceAssocID, 
				A1.strName  as DestinationAssocName, 
				A2.strName as SourceAssocName, 
				C.intDestinationClubID as DestinationClubID,
                                C.intSourceClubID as SourceClubID,
                                C.intDestinationAssocID  as DestinationAssocID,
                                C.intSourceAssocID as SourceAssocID,
				DATE_FORMAT(C.dtApplied,'%d/%m/%Y') AS AppliedDate, 
				A1.strEmail as DestinationAssocEmail, 
				A1.strPhone as DestinationAssocPh, 
				A1.strContact as DestinationAssocContact,  
				A2.strEmail as SourceAssocEmail, 
				A2.strPhone as SourceAssocPh, 
				A2.strContact as SourceAssocContact
      FROM
				tblClearance as ThisClr
        INNER JOIN tblClearance as C ON (C.intMemberID=ThisClr.intMemberID and C.intClearanceID <> ThisClr.intClearanceID)
        LEFT JOIN tblClub as C1 ON (C1.intClubID = C.intDestinationClubID)
        LEFT JOIN tblClub as C2 ON (C2.intClubID = C.intSourceClubID)
        LEFT JOIN tblAssoc as A1 ON (A1.intAssocID= C.intDestinationAssocID)
        LEFT JOIN tblAssoc as A2 ON (A2.intAssocID= C.intSourceAssocID)
    WHERE ThisClr.intClearanceID = $clearanceID
AND  C.intClearanceStatus = $Defs::CLR_STATUS_PENDING
      AND C.intCreatedFrom =0
  ];
  my $query = $db->prepare($st) or query_error($st);
  $query->execute or query_error($st);

	while (my $dref = $query->fetchrow_hashref()) {
		my $source_contact_name="";
		my $source_contact_email ="";
		my $destination_contact_name ="";
		my $destination_contact_email="";		
	
 if($dref->{SourceAssocID} >0){
                my $source_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getclearances=>1)||[];
                my $source_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getprimary=>1)||[];
                if(scalar(@$source_contactObj)>0){
                        $source_contact_name =qq[@$source_contactObj[0]->{strContactFirstname} @$source_contactObj[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$source_contactObjP)>0){
                        $source_contact_name =qq[@$source_contactObjP[0]->{strContactFirstname} @$source_contactObjP[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObjP[0]->{strContactEmail};
                }
        }
        if($dref->{DestinationAssocID} >0){
                my  $destination_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getclearances=>1) ;
                my  $destination_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getprimary=>1) ;
                if(scalar(@$destination_contactObj)>0){
                        $destination_contact_name =qq[@$destination_contactObj[0]->{strContactFirstname} @$destination_contactObj[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$destination_contactObjP)>0){
                        $destination_contact_name =qq[@$destination_contactObjP[0]->{strContactFirstname} @$destination_contactObjP[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObjP[0]->{strContactEmail};
                }
        }


		$dref->{SourceAssocEmail} = $source_contact_email;
		$dref->{SourceAssocContact} = $source_contact_name;

		$dref->{DestinationAssocEmail} = $destination_contact_email;
		$dref->{DestinationAssocContact} = $destination_contact_name;
		return qq[
			<div class="warningmsg">The selected member is already involved in a pending clearance.  Unable to continue until the below transaction is finalised.</div>
			<p>
					<b>Date Requested:</b> $dref->{AppliedDate}<br>
					<b>Requested From:</b> $dref->{SourceAssocName} $dref->{SourceClubName} ($source_contact_name)<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{SourceAssocContact}<br>
					Phone: $dref->{SourceAssocPh}&nbsp;&nbsp;Email:  $dref->{SourceAssocEmail}<br>
					<b>Request To:</b> $dref->{DestinationAssocName} ($dref->{DestinationClubName})<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{DestinationAssocContact}<br>
					Phone: $dref->{DestinationAssocPh}&nbsp;&nbsp;Email: $dref->{DestinationAssocEmail}<br>
				</p>
			];

	}



	$st = qq[
		UPDATE tblClearance
		SET intClearanceStatus = $Defs::CLR_STATUS_PENDING
		WHERE intClearanceID = $clearanceID
			AND intDestinationClubID = $clubID
	];
	$db->do($st);
	$st = qq[
		UPDATE tblClearancePath as CP INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
		SET CP.intClearanceStatus = $Defs::CLR_STATUS_PENDING
		WHERE CP.intClearanceID = $clearanceID
			AND CP.intClearanceStatus = $Defs::CLR_STATUS_CANCELLED
			AND C.intDestinationClubID = $clubID
	];
	$db->do($st);

	sendCLREmail($Data, $clearanceID, 'REOPEN');
  auditLog($clearanceID, $Data, 'Reopen','Clearance');
	return qq[<p>$txt_Clr Reopened</p><br> <a href="$Data->{'target'}?a=CL_list&amp;client=$client">Return to $txt_Clr Listing</a> ] ;
}

sub clearanceHistory	{

### PURPOSE: This function displays, for given intMemberID, the clearance history that they have. This is called from within the view member screen.

### At the bottom of this function is the ability to add a manual clearance history record.  For example, if they came from overseas.  These manual records don't have approval paths, but rather, are for historical purposes.

	my ($Data, $intMemberID) = @_;

	return if ! $Data->{'SystemConfig'}{'AllowClearances'};
	$intMemberID ||= 0;

	return '' if ! $intMemberID;

	my $db = $Data->{'db'};
	my $clr_query = $db->prepare(qq[
                SELECT intAllowClubClrAccess
                FROM tblAssoc
                WHERE intAssocID= $Data->{'clientValues'}{'assocID'}
                LIMIT 1
        ]);
        $clr_query->execute;
        my($intAllowClubClrAccess)= $clr_query->fetchrow_array();
        $intAllowClubClrAccess ||= 0;

        $intAllowClubClrAccess = 1 if ($Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC);
        $clr_query->finish;

	my $st = qq[
                SELECT C.*, SourceClub.strName as SourceClubName, DestinationClub.strName as DestinationClubName, SourceAssoc.strName as SourceAssocName, DestinationAssoc.strName as DestinationAssocName, SUM(CDF.curDevelopmentFee) + SUM(CP.curPathFee) as SumFee, SUM(CP.curPathFee) as SumPathFee, DATE_FORMAT(dtApplied,'%d/%m/%Y') AS dtApplied, now() AS Today, IF(dtPermitTo<now(), 'Past', 'Current') as PastCurrent
                FROM tblClearance as C
                        LEFT JOIN tblAssoc as SourceAssoc ON (SourceAssoc.intAssocID = C.intSourceAssocID)
                        LEFT JOIN tblAssoc as DestinationAssoc ON (DestinationAssoc.intAssocID = C.intDestinationAssocID)
			LEFT JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                        LEFT JOIN tblClub as SourceClub ON (SourceClub.intClubID = C.intSourceClubID)
                        LEFT JOIN tblClub as DestinationClub ON (DestinationClub.intClubID = C.intDestinationClubID)
			LEFT JOIN tblClearanceDevelopmentFees as CDF ON (CP.intClearanceDevelopmentFeeID = CDF.intDevelopmentFeeID)
                WHERE C.intMemberID = $intMemberID
			AND C.intRecStatus <> -1
		GROUP BY C.intClearanceID
		ORDER BY C.dtApplied DESC
        ];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
	
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';

	my @headerdata = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name => 'Ref. No.',
      field => 'intClearanceID',
    },	
    {
      name => 'Date',
      field => 'dtApplied',
    },	
    {
      name => 'From League (Club)',
      field => 'sourceDetails',
    },	
    {
      name => 'To League (Club)',
      field => 'destinationDetails',
    },	
    {
      name => 'Status',
      field => 'status',
    },	
    {
      name => 'Type',
      field => 'type',
    },	
	);
	my $count=0;
  my $client=setClient($Data->{'clientValues'}) || '';
	my @rowdata=();
	while (my $dref=$query->fetchrow_hashref())	{
		$count++;
		my $status = $Defs::clearance_status{$dref->{intClearanceStatus}};
		my $priority= $Defs::clearance_priority{$dref->{intClearancePriority}};
#		$status = qq[<span style="font-weight:bold;color:green;">$status</span>] if $dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED;
#		$status = qq[<span style="font-weight:bold;color:red;">$status</span>] if $dref->{intClearanceStatus} == $Defs::CLR_STATUS_DENIED;
		$dref->{SourceAssocName} ||= $dref->{strSourceAssocName} || '';
    $dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
    $dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
    $dref->{DestinationAssocName} ||= $dref->{strDestinationAssocName} || '';
		my $selectLink= "$Data->{'target'}?client=$client&amp;cID=$dref->{intClearanceID}&amp;a=CL_view";
		$selectLink= "$Data->{'target'}?client=$client&amp;clrID=$dref->{intClearanceID}&amp;a=CL_editmanual" if ($dref->{intCreatedFrom} == $Defs::CLR_TYPE_MANUAL and $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC);

## TC ## HACKED IN COS TOO MANY BAFF CHANGES ON DEVEL | CHANGE IS CHECKED IN ON DEVEL
    my $clearance_type = '';
    if ($dref->{'intPermitType'} == $Defs::CLRPERMIT_MATCHDAY or $dref->{'intPermitType'} == $Defs::CLRPERMIT_LOCALINTX or $dref->{'intPermitType'} == $Defs::CLRPERMIT_TRANSFER) {
			if ($dref->{'PastCurrent'} eq 'Past')	{
				$clearance_type = 'Past Permit';
			}
			else	{
				$clearance_type='Current Permit';
			}
    }
    else {
      $clearance_type = $Defs::ClearanceTypes{$dref->{intCreatedFrom}};
    }

		$dref->{'sourceDetails'} = qq[$dref->{SourceAssocName} ($dref->{SourceClubName})];
		$dref->{'destinationDetails'} = qq[$dref->{DestinationAssocName} ($dref->{DestinationClubName})];
		$dref->{'status'} = $status;
		$dref->{'type'} = $clearance_type;
		push @rowdata, {
      id => $dref->{'intClearanceID'},
			intClearanceID=>$dref->{'intClearanceID'},
      SelectLink=>$selectLink,
      dtApplied=> $dref->{'dtApplied'},
      sourceDetails=> $dref->{'sourceDetails'},
      destinationDetails=> $dref->{'destinationDetails'},
      status=> $dref->{'status'},
      type=> $dref->{'type'},
		};
	}
	
	my $body = showGrid(
      Data => $Data,
      columns => \@headerdata,
      rowdata => \@rowdata,
      gridid => 'grid',
      width => '99%',
      height => 700,
    );
	$body =qq[<div class="warningmsg">No $txt_Clr History found</div>] if ! $count;

	my $addManual = qq[<a href="$Data->{'target'}?client=$client&amp;a=CL_addmanual">Add manual $txt_Clr History</a>];
	$addManual = '' if (
        ! $intAllowClubClrAccess 
        or $Data->{'ReadOnlyLogin'}
        or $Data->{'SystemConfig'}{'clrTurnOffManual'} 
        or (
            $Data->{'SystemConfig'}{'clrTurnOffManual_clubLevelOnly'} 
            and (! $Data->{'clientValues'}{'clubID'}
                or $Data->{'clientValues'}{'clubID'} == $Defs::INVALID_ID
            )
        )
    );
	#$body = qq[<div class="sectionheader">$txt_Clr History</div>$addManual$body];
	$body = qq[$addManual$body];
	return $body;
}

sub clearanceView	{

### PURPOSE: This function is used to view a clearance record.  This is what is loaded once the clearance is clicked in "List Clearances" navbar option.

## The function works out if the level viewing it is the destination club (who requested the clearance) and if so allows the clearance notes field to be updated.

	my ($Data, $cID) = @_;

	my $db = $Data->{'db'};
	my $body;

	my $st = qq[
                SELECT DISTINCT C.*, M.intNatCustomBool2, DATE_FORMAT(C.dtApplied,"%d/%m/%Y") AS dtApplied, CONCAT(M.strSurname, " ", M.strFirstname) as MemberName, SourceClub.strName as SourceClubName, DestinationClub.strName as DestinationClubName, SourceAssoc.strName as SourceAssocName, DestinationAssoc.strName as DestinationAssocName, M.strSuburb, M.strState, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB, SUM(CDF.curDevelopmentFee) + SUM(CP.curPathFee) as SumFee, strNationalNum, DATE_FORMAT(dtPermitFrom,'%d/%m/%Y') AS dtPermitFrom,DATE_FORMAT(dtPermitTo,'%d/%m/%Y') AS dtPermitTo, SUM(CP.curPathFee) as SumPathFee, SUM(CP.curDevelFee) as SumDevelFee, DATE_FORMAT(C.dtDue,"%d/%m/%Y") AS dtDue, IF(C.dtPermitTo > CURRENT_DATE(), 1, 0) as dtPermitToInFuture, CP.strOtherDetails1
                FROM tblClearance as C
                        INNER JOIN tblMember as M ON (M.intMemberID = C.intMemberID)
			LEFT JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                        LEFT JOIN tblAssoc as SourceAssoc ON (SourceAssoc.intAssocID = C.intSourceAssocID)
                        LEFT JOIN tblAssoc as DestinationAssoc ON (DestinationAssoc.intAssocID = C.intDestinationAssocID)
                        LEFT JOIN tblClub as SourceClub ON (SourceClub.intClubID = C.intSourceClubID)
                        LEFT JOIN tblClub as DestinationClub ON (DestinationClub.intClubID = C.intDestinationClubID)
			LEFT JOIN tblClearanceDevelopmentFees as CDF ON (CP.intClearanceDevelopmentFeeID = CDF.intDevelopmentFeeID)
                WHERE C.intClearanceID= $cID
		GROUP BY C.intClearanceID
        ];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $dref = $query->fetchrow_hashref() || undef;

	$dref->{SumFee} ||= 0.00;
	$dref->{SumPathFee} ||= 0.00;
	$dref->{SumDevelFee} ||= 0.00;
	$dref->{PlayerActive} = $dref->{intPlayerActive} ? 'Yes' : 'No';
	$dref->{CoachActive} = $dref->{intCoachActive} ? 'Yes' : 'No';
	$dref->{MthOfficialActive} = $dref->{intMthOfficialActive} ? 'Yes' : 'No';
	$dref->{MiscActive} = $dref->{intMiscActive} ? 'Yes' : 'No';
	$dref->{VolunteerActive} = $dref->{intVolunteerActive} ? 'Yes' : 'No';
	my $id=0;
	my $edit=0;
  	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option='display';

	if ($dref->{intCreatedFrom} == $Defs::CLR_TYPE_MANUAL or $dref->{intSourceClubID} == $Defs::{'clientValues'}{'clubID'})	{
		$edit=1;
		$id=$cID;
		$option='edit';
	}

	my $clrupdate=qq[
                UPDATE tblClearance
                        SET --VAL--
                WHERE intClearanceID = $cID
        ];

  	my $resultHTML = '';
	my $toplist='';

	my %DataVals=();
	my $RecordData={};

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        onlyTypes  => '-37',
    );

	my $readonly = 1;
	$readonly=0 if ($Data->{'clientValues'}{'clubID'} == $dref->{intDestinationClubID});	
	#$option = 'display' if ($Data->{'ReadOnlyLogin'} and $Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC);
	$dref->{SourceAssocName} ||= $dref->{strSourceAssocName} || '';
	$dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
	$dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || 'Update Clearance';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';
	my $intPlayerActive =($Data->{'SystemConfig'}{'clrHide_intPlayerActive'}==1) ? '1' : '0';
	my $intCoachActive =($Data->{'SystemConfig'}{'clrHide_intCoachActive'}==1) ? '1' : '0';
	my $intMthOfficialActive =($Data->{'SystemConfig'}{'clrHide_intMthOfficialActive'}==1) ? '1' : '0';
	my $intMiscActive =($Data->{'SystemConfig'}{'clrHide_intMiscActive'}==1) ? '1' : '0';
	my $intVolunteerActive =($Data->{'SystemConfig'}{'clrHide_intVolunteerActive'}==1) ? '1' : '0';
	my $dtPermitFrom =($Data->{'SystemConfig'}{'clrHide_dtPermitFrom'}==1) ? '1' : '0';
	my $dtPermitTo = ($Data->{'SystemConfig'}{'clrHide_dtPermitTo'}==1) ? '1' : '0';
	my $ClearanceFee= ($Data->{'SystemConfig'}{'clrHide_clearanceFee'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $DevelFee= ($Data->{'SystemConfig'}{'clrHide_curDevelFee'}==1) ? '1' : '0';
	my $OtherDetails1= ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'}) ? '0' : '1';
	$DevelFee = 1 if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
	
	if (
		($Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC or ($Data->{'clientValues'}{'authLevel'}==$Defs::LEVEL_CLUB and $Data->{'clientValues'}{'clubID'} == $dref->{intSourceClubID}))
		and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED 
		and ! $dtPermitTo 
		and $dref->{'dtPermitToInFuture'})	{
		### ALLOW SOURCE CLUB (or ABOVE) to edit the permit dates

		$readonly=0;
		$option='edit';

	}
	$update_label = '' if $readonly;

	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
    my $showAgentFields = ($Data->{'SystemConfig'}{'clrHide_AgentFields'} == 1) ? '1' : '0';
	my %FieldDefs = (
		CLR => {
			fields => {
				intNatCustomBool2=> {
                    			label=>($dref->{'intNatCustomBool2'} and $Data->{'SystemConfig'}{'clrExpose_intNatCustomBool2'}) ? $Data->{'SystemConfig'}{'clrExpose_intNatCustomBool2'} : '',
                    			value => $dref->{'intNatCustomBool2'},
                    			options=> {1 => 'Yes', 0 => 'No'},
                    			type  => 'lookup',
                    			readonly => 1,
                		},
				NatNum=> {
					label => $Data->{'SystemConfig'}{'NationalNumName'},
					value => $dref->{'strNationalNum'},
                                        type  => 'text',
					readonly => '1',
                		},
				ClearanceID=> {
                                        label => "$txt_Clr Ref. No.",
					value => $dref->{'intClearanceID'},
                                        type  => 'text',
					readonly => '1',
                		},
				dtApplied=> {
					label => 'Application Date',
					value => $dref->{'dtApplied'},
                                        type  => 'text',
					readonly => '1',
				},	
				dtDue => {
					label => $Data->{'SystemConfig'}{'Clearance_DateDue'} ? 'Date Due' : '',
					value => $dref->{'dtDue'},
                                        type  => 'text',
					readonly => '1',
                		},
				MemberName=> {
					label => 'Member being Cleared',
					value => $dref->{'MemberName'},
                                        type  => 'text',
					readonly => '1',
                		},
				dtDOB => {
					label => 'Date of birth',
					value => $dref->{'dtDOB'},
                                        type  => 'text',
					readonly => '1',
				},	
				strSuburb => {
					label => 'Address Suburb',
					value => $dref->{'strSuburb'},
                                        type  => 'text',
					readonly => '1',
                		},
				strState=> {
					label => 'Address State',
					value => $dref->{'strState'},
                                        type  => 'text',
					readonly => '1',
                		},
				SourceClubName => {
					label => 'From Club',
					value => $dref->{'SourceClubName'},
                                        type  => 'text',
					readonly => '1',
				},
				SourceAssocName => {
					label => 'From Association',
					value => $dref->{'SourceAssocName'},
                                        type  => 'text',
					readonly => '1',
				},
				DestinationClubName => {
					label => 'To Club',
					value => $dref->{'DestinationClubName'},
                    type  => 'text',
					readonly => '1',

				},
				DestinationAssocName => {
					label => 'To Association',
					value => $dref->{'DestinationAssocName'},
                                        type  => 'text',
					readonly => '1',
				},
				intPlayerActive => {
					label => 'Clear as Player Active ?',
					value => $dref->{'PlayerActive'},
                                        type  => 'checkbox',
					readonly => '1',
					nodisplay=>$intPlayerActive,
				},
				intCoachActive => {
					label => 'Clear as Coach Active ?',
					value => $dref->{'CoachActive'},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$intCoachActive,
				},
				intMthOfficialActive => {
					label => 'Clear as Match Official Active ?',
					value => $dref->{'MthOfficialActive'},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$intMthOfficialActive,
				},
				intMiscActive => {
					label => 'Clear as Misc Active ?',
					value => $dref->{'MiscActive'},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$intMiscActive,
				},
				intVolunteerActive => {
					label => 'Clear as Volunteer Active ?',
					value => $dref->{'VolunteerActive'},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$intVolunteerActive,
				},
				ClearanceStatus => {
					label => "Overall $txt_Clr Status",
					value => qq[<b>$Defs::clearance_status{$dref->{intClearanceStatus}}</b>],
                                        type  => 'text',
					readonly => '1',
				},
				ClearancePriority => {
					label => "$txt_Clr Priority",
					value => $Defs::clearance_priority{$dref->{intClearancePriority}},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$intClearancePriority,
					noadd=>$intClearancePriority,
					noedit=>$intClearancePriority,
				},
				ClearanceFee => {
					label => 'Total Fees Applied',
					value => qq[\$$dref->{SumPathFee}],
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$ClearanceFee,
					noadd=>$ClearanceFee,
					noedit=>$ClearanceFee,
				},
				DevelFee => {
					label => 'Total Development Fees Applied',
					value => qq[\$$dref->{SumDevelFee}],
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$DevelFee,
					noadd=>$DevelFee,
					noedit=>$DevelFee,
				},
				strOtherDetails1=> {
					label => $Data->{'SystemConfig'}{'clrOtherDetails1_Label'},
					value => $dref->{strOtherDetails1},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$OtherDetails1,
					noadd=>$OtherDetails1,
					noedit=>$OtherDetails1,
				},
				intReasonForClearanceID => {
        				label => "Reason for $txt_Clr",
				        value => $dref->{intReasonForClearanceID},
				        type  => 'lookup',
        				options => $DefCodes->{-37},
        				order => $DefCodesOrder->{-37},
					firstoption => ['',"Choose Reason"],
					readonly => '1',
					nodisplay=>$intReasonForClearanceID,
					noadd=>$intReasonForClearanceID,
					noedit=>$intReasonForClearanceID,
	      			},
				strReasonForClearance=> {
					label => 'Additional Information',
					type => 'textarea',
					value => $dref->{'strReasonForClearance'},
					rows => 5,
                			cols=> 45,
					readonly=>$readonly,
					nodisplay=>$strReasonForClearance,
					noadd=>$strReasonForClearance,
					noedit=>$strReasonForClearance,
				},
				strReason=>	{
					label => 'Reason for Clearance',
                                        value => $dref->{'strReason'},
                                        type  => 'text',
					readonly => '1',
					nodisplay=>$strReason,
					noadd=>$strReason,
					noedit=>$strReason,
				},
				intPermitType	=> {
                                        label => "Permit Type",
                                        value => $dref->{'intPermitType'},
                                        type  => 'lookup',
                                        options => \%{$Defs::clearancePermitType{$Data->{'Realm'}}},
					default=>'0',
					readonly => 1,
				},
				dtPermitFrom =>	{
					label => $dtPermitFrom ? '' : 'Permit Date From',
                                        value => $dref->{'dtPermitFrom'},
                                        type  => 'date',
					readonly => '1',
					nodisplay=>$dtPermitFrom,
					noadd=>$dtPermitFrom,
					noedit=>$dtPermitFrom,
				},
				dtPermitTo =>	{
					label => $dtPermitTo ? '' : 'Permit Date to',
                                        value => $dref->{'dtPermitTo'},
                                        type  => 'date',
					Readonly => '1',
					nodisplay=>$dtPermitTo,
					noadd=>$dtPermitTo,
					noedit=>$dtPermitTo,
				},
                intHasAgent=> {
					label => $showAgentFields ? '' : 'Player has an Agent ?',
					value => $dref->{'intHasAgent'} ? 'Yes' : 'No',
                    type  => 'text',
					readonly=>'1',
				},	
				strAgentFirstname=> {
					label => $showAgentFields ? '' :'Agent Firstname',
					value => $dref->{'strAgentFirstname'},
                    type  => 'text',
					readonly=>'1',
				},	
				strAgentSurname=> {
					label => $showAgentFields ? '' :'Agent Surname',
					value => $dref->{'strAgentSurname'},
                    type  => 'text',
					readonly=>'1',
				},	
				strAgentNationality=> {
					label => $showAgentFields ? '' :'Agent Nationality',
					value => $dref->{'strAgentNationality'},
                    type  => 'text',
					readonly=>'1',
				},	
				strAgentLicenseNum=> {
					label => $showAgentFields ? '' :'Agent License Number',
					value => $dref->{'strAgentLicenseNum'},
                    type  => 'text',
					readonly=>'1',
				},	
				strAgencyName=> {
					label => $showAgentFields ? '' :'Agency Name',
					value => $dref->{'strAgencyName'},
                    type  => 'text',
					readonly=>'1',
				},	
				strAgencyEmail=> {
					label => $showAgentFields ? '' :'Agency Email',
					value => $dref->{'strAgencyEmail'},
                    type  => 'text',
					readonly=>'1',
				},
		},
		order => [qw(ClearanceID dtApplied dtDue NatNum MemberName dtDOB intNatCustomBool2 strSuburb strState SourceClubName SourceAssocName DestinationClubName DestinationAssocName intPermitType dtPermitFrom dtPermitTo intPlayerActive intCoachActive intMthOfficialActive intMiscActive intVolunteerActive ClearanceStatus ClearanceFee DevelFee strOtherDetails1 ClearancePriority ClearanceReason intReasonForClearanceID strReason strReasonForClearance intHasAgent strAgentFirstname strAgentSurname strAgentNationality strAgentLicenseNum strAgencyName strAgencyEmail)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'clr_form',
				submitlabel => $update_label,
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $clrupdate,
				afterupdateFunction => \&postClearanceUpdate,
                        	afterupdateParams => [$option,$Data,$Data->{'db'}, $cID],
				stopAfterAction => 1,
				updateOKtext => qq[
                                        <div class="OKmsg">Record updated successfully</div> <br>                                        <a href="$Data->{'target'}?client=$client&amp;a=CL_view&amp;cID=$cID">Return to Clearance</a>
                                ],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'CL_view',
				cID => $cID,
			},
		},
	);


	($resultHTML, undef )=handleHTMLForm($FieldDefs{'CLR'}, undef, $option, '',$db);

	my $clr_query = $db->prepare(qq[
                SELECT intAllowClubClrAccess
                FROM tblAssoc
                WHERE intAssocID= $Data->{'clientValues'}{'assocID'}
                LIMIT 1
        ]);
        $clr_query->execute;
        my($intAllowClubClrAccess)= $clr_query->fetchrow_array();
        $intAllowClubClrAccess ||= 0;

        $intAllowClubClrAccess = 1 if ($Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC);
        $clr_query->finish;


	if ($dref->{intCreatedFrom} == 0)	{
		$resultHTML .= qq[<a href="$Data->{'target'}?client=$client&amp;cID=$cID&amp;a=CL_cancel">Cancel $txt_Clr</a>] if ($dref->{intDestinationClubID} == $Data->{'clientValues'}{'clubID'} and $dref->{intClearanceStatus} != $Defs::CLR_STATUS_CANCELLED and $intAllowClubClrAccess and $dref->{intClearanceStatus} != $Defs::CLR_STATUS_APPROVED);
		$resultHTML .= qq[<a href="$Data->{'target'}?client=$client&amp;cID=$cID&amp;a=CL_reopen">Reopen Cancelled $txt_Clr</a>] if ($dref->{intDestinationClubID} == $Data->{'clientValues'}{'clubID'} and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_CANCELLED and $intAllowClubClrAccess);
		$resultHTML .= showPathDetails($Data, $cID, $dref->{intClearanceStatus});
	}
	else	{
		$resultHTML .= qq[<br><div class="warningmsg">No path details can be shown as this clearance was created offline or is a Manual $txt_Clr History record</div>];
	}
	$resultHTML .= Member::TribunalHistory($Data, $dref->{intMemberID}, 0);

	if($option eq 'display')	{
		$resultHTML .=qq[<br><a href="$target?a=CL_list&amp;client=$client">Return to $txt_Clr Listing</a> ] ;
	}

	$resultHTML=qq[
			<div class="alphaNav">$toplist</div>
			<div>
				$resultHTML
			</div>
	];
	my $heading=qq[$txt_Clr Summary];
	return ($resultHTML,$heading);

}

sub postClearanceUpdate	{

 my($id,$params, $action,$Data,$db, $cID)=@_;
        $cID||=0;
        $id||=$cID;
        return (0,undef) if !$db;

	 my $st = qq[
                SELECT
			intMemberID,
			intDestinationClubID,
			intSourceClubID,
			intSourceAssocID,
			intDestinationAssocID,
			dtPermitTo,
			IF(dtPermitTo > CURRENT_DATE(), 1, 0) as dtPermitToInFuture
                FROM 
			tblClearance
                WHERE 
			intClearanceID = $id
        ];
        my $qry= $db->prepare($st);
        $qry->execute or query_error($st);
        my ($intMemberID, $intToClubID, $intFromClubID, $intFromAssocID, $intToAssocID, $dtPermitTo, $inFuture) = $qry->fetchrow_array();
	## If in past then set as inactive
	if ($inFuture)	{
		$st = qq[
			UPDATE
				tblMember_Clubs
			SET
				dtPermitEnd = "$dtPermitTo"
			WHERE
				intMemberID = $intMemberID
				AND intClubID = $intToClubID
				AND intPermit=1
			LIMIT 1
		];
		$db->do($st);
	}
	if (! $inFuture)	{
		### ROLL BACK MEMBER
		 my $st_updateSource = qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_ACTIVE
                        WHERE
                                intMemberID = $intMemberID
                                AND intClubID = $intFromClubID
                                AND intStatus = $Defs::RECSTATUS_INACTIVE
                        ORDER BY intPermit
                        LIMIT 1
                ];
                $db->do($st_updateSource);
                my $st_updatePermittedClub= qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_INACTIVE,
                                dtPermitEnd = "$dtPermitTo"
                        WHERE
                                intMemberID = $intMemberID
                                AND intClubID = $intToClubID
                                AND intPermit = 1
                                AND intStatus = $Defs::RECSTATUS_ACTIVE
                ];
                $db->do($st_updatePermittedClub);
                my $st_updateassoc = qq[
                        UPDATE
                                tblMember_Associations
                        SET
                                intRecStatus=0
                        WHERE
                                intMemberID = $intMemberID
                                AND intAssocID = $intToAssocID
                ];
                $db->do($st_updateassoc);
                $st_updateassoc = qq[
                        UPDATE
                                tblMember_Associations
                        SET
                                intRecStatus=1
                        WHERE
                                intMemberID = $intMemberID
                                AND intAssocID = $intFromAssocID
                ];
                $db->do($st_updateassoc);
                my $st_clubsCleared = qq[
                        DELETE
                        FROM
                                tblMember_ClubsClearedOut
                        WHERE
                                intMemberID = $intMemberID
                                AND intAssocID = $intFromAssocID
                                AND intClubID = $intFromClubID
                ];
                $db->do($st_clubsCleared);
	}
}

sub showPathDetails	{

### PURPOSE: This function builds up the visible path information that is displayed at the bottom of the clearance record when viewing it.

### If the destination club (who requested clearance) have cancelled the clearance, this function has the "REOPEN" option set against the status column.

	my ($Data, $cID, $clearanceStatus) = @_;

  	my $client=setClient($Data->{'clientValues'}) || '';
	$cID ||= 0;
	return if ! $cID;

	my $db = $Data->{'db'};

	my $st = qq[
		SELECT CP.* , DATE_FORMAT(CP.tTimeStamp,'%d/%m/%Y') AS TimeStamp, CLF.strTitle, CLF.curDevelopmentFee, C.intCurrentPathID, DATE_FORMAT(CP.dtAlert,'%d/%m/%Y') AS dtAlert
		FROM tblClearancePath as CP LEFT JOIN tblClearanceDevelopmentFees as CLF ON (CLF.intDevelopmentFeeID = CP.intClearanceDevelopmentFeeID) INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
		WHERE CP.intClearanceID = $cID
		ORDER BY intOrder
	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $body = '';

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        onlyTypes  => '-38',
    );
       
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
				#<th>Level</th>
	$body .= qq[
        	<div class="sectionheader">$txt_Clr Approval Details</div>
                <table class="listTable">
			<tr>
				<th>Name</th>
				<th>$txt_Clr Status</th>
	];
	$body .= qq[
				<th>Approved By</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_strApprovedBy'});
	$body .= qq[
				<th>Alert Date</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_dtAlert'});
	$body .= qq[
				<th>Denial Reason</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_intDenialReasonID'});
	$body .= qq[
				<th>Player Financial ?</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_intPlayerFinancial'});
	$body .= qq[
				<th>Player Suspended ?</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_intPlayerSuspended'});
	$body .= qq[
				<th>Fee Applied</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_clearanceFee'});
	$body .= qq[
				<th>$Data->{'SystemConfig'}{'clrOtherDetails1_Label'}</th>
	] if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'});
	$body .= qq[
				<th>Development Fee</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_intClearanceDevelopmentFeeID'});
	$body .= qq[
				<th>Development Fee</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_curDevelFee'} and $Data->{'clientValues'}{'currentLevel'} != $Defs::LEVEL_CLUB);
	$body .= qq[
				<th>Additional Information</th>
				<th>Time Updated</th>
			</tr>
	];
	my $denied = 0;



#### 
 my $intID=0;         $intID = $Data->{'clientValues'}{'clubID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
        $intID = $Data->{'clientValues'}{'assocID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ASSOC);
        $intID = $Data->{'clientValues'}{'zoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ZONE);
        $intID = $Data->{'clientValues'}{'regionID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION);
        $intID = $Data->{'clientValues'}{'stateID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_STATE);         $intID = $Data->{'clientValues'}{'natID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_NATIONAL);
        $intID = $Data->{'clientValues'}{'intzoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTZONE);
        $intID = $Data->{'clientValues'}{'intregID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTREGION);
        $intID = $Data->{'clientValues'}{'interID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTERNATIONAL);
        my $intTypeID = $Data->{'clientValues'}{'currentLevel'};

		my @rowdata=();
	while (my $dref = $query->fetchrow_hashref())	{
		my ($pathnode , undef, undef) = getNodeDetails($db, $dref->{intTableType}, $dref->{intTypeID}, $dref->{intID});
		next if ! $pathnode;
		my $status = ($denied == 1) ? '-' : $Defs::clearance_status{$dref->{intClearanceStatus}};
		$denied = 1 if $dref->{intClearanceStatus} == $Defs::CLR_STATUS_DENIED;
		$status = qq[<a href="$Data->{'target'}?client=$client&amp;a=CL_details&amp;cID=$dref->{intClearanceID}&amp;cpID=$dref->{intClearancePathID}">$status</a>] if ($status ne '-' and $dref->{intClearanceStatus} != $Defs::CLR_STATUS_PENDING and $dref->{intTypeID} == $intTypeID and $dref->{intID} == $intID and !$Data->{'ReadOnlyLogin'});

		$status = qq[<span style="font-weight:bold;color:green;">$status</style>] if $dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED;
		$status = qq[<span style="font-weight:bold;color:red;">$status</style>] if $dref->{intClearanceStatus} == $Defs::CLR_STATUS_DENIED;
		$status .= qq[&nbsp;&nbsp;<a href="$Data->{'target'}?client=$client&amp;a=CL_details&amp;cID=$dref->{intClearanceID}&amp;cpID=$dref->{intClearancePathID}">&nbsp;(--REOPEN CLEARANCE--)</a>] if ($dref->{intClearanceStatus} == $Defs::CLR_STATUS_DENIED and $dref->{intTypeID} == $intTypeID and $dref->{intID} == $intID);
		$status = 'Cancelled' if ($clearanceStatus == $Defs::CLR_STATUS_CANCELLED and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_PENDING);
		my $fee = $dref->{curPathFee} > 0 ? qq[\$$dref->{curPathFee}] : '-';
		my $developmentfee = $dref->{intClearanceDevelopmentFeeID} ? qq[$dref->{strTitle}] : '';
		my $curDevelFee = $dref->{curDevelFee} eq '0.00' ? '-' : $dref->{curDevelFee};
		$curDevelFee = '' if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
		my $timestamp = $dref->{intClearanceStatus} ? $dref->{TimeStamp} : '';
		my $level = $Defs::LevelNames{$dref->{intTypeID}};
				#<td><i>$level</i></td>
		$body .= qq[
			<tr>
				<td>$pathnode</td>
				<td>$status</td>
		];
		my $alert = $dref->{dtAlert} eq '00/00/0000' ? '' : $dref->{dtAlert};
		$body .= qq[
				<td>$dref->{strApprovedBy}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_strApprovedBy'});
		$body .= qq[
				<td>$alert</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_dtAlert'});
		$body .= qq[
				<td>$DefCodes->{-38}{$dref->{intDenialReasonID}}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_intDenialReasonID'});
	$body .= qq[
				<td>$Defs::clearance_financial{$dref->{intPlayerFinancial}}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_intPlayerFinancial'});
	$body .= qq[
				<td>$Defs::clearance_suspended{$dref->{intPlayerSuspended}}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_intPlayerSuspended'});
	$body .= qq[
				<td>$fee</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_clearanceFee'});
	$body .= qq[
				<td>$dref->{'strOtherDetails1'}</td>
	] if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'});
	$body .= qq[
				<td>$developmentfee</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_intClearanceDevelopmentFeeID'});
	$body .= qq[
				<td>$curDevelFee</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_curDevelFee'} and $Data->{'clientValues'}{'currentLevel'} != $Defs::LEVEL_CLUB);
	$body .= qq[
				<td>$dref->{strPathNotes}</td>
				<td>$timestamp</td>
			</tr>
		];
	}
	$body .= qq[</table><br>];

	return $body;

}

sub getNodeDetails	{

### PURPOSE: This function returns the Name, Email address and assoc Type (if appropriate) for the passed values.  This is used by various functions such as emailing.

	my ($db, $intTableType, $intTypeID, $intID) = @_;

	$intTableType ||= 0;
	$intTypeID ||= 0;
	$intID ||= 0;

	return '' if ! $intTableType or ! $intTypeID or ! $intID;

	my $tablename = '';
	my $field = '';
	my $assocTypeID = '';
	my $where = '';
	if ($intTableType == $Defs::CLUB_LEVEL_CLEARANCE)	{
		$tablename = 'tblClub';
		$field = 'intClubID';
	}
	if ($intTableType == $Defs::ASSOC_LEVEL_CLEARANCE)	{
		$tablename = 'tblAssoc';
		$field = 'intAssocID';
		$assocTypeID = qq[, intAssocTypeID];
	}
	if ($intTableType == $Defs::NODE_LEVEL_CLEARANCE)	{
		$tablename = 'tblNode';
		$field = 'intNodeID';
		$where = qq[ AND intStatusID =$Defs::NODE_SHOW ];
	}

	my $st = qq[
		SELECT strName, strEmail $assocTypeID
		FROM $tablename
		WHERE $field = $intID
			$where
	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
	my $name='';
	my $email='';
	my $id = '';

	if ($intTableType == $Defs::ASSOC_LEVEL_CLEARANCE)	{
		($name, $email, $id) = $query->fetchrow_array();
		$id ||= 0;
	}
	else	{
		($name, $email) = $query->fetchrow_array();
	}
	$name ||= '';
	$email ||= '';

	return ($name, $id,$email);

}

sub clearancePathDetails	{

### PURPOSE: This function creates a HTMLForm view of the clearance from a clearance Path view.  Ie: from the approval/denial record of a clearance.

### If the level at view the path details, they are given the option of editing the notes.

	my ($Data, $cID, $cpID) = @_;

	my $db = $Data->{'db'};
	$cpID ||= 0;
	my $cpID_WHERE = $cpID ? qq[ AND CP.intClearancePathID = $cpID] : '';
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';

	my $body;

	my $st = qq[
                SELECT DISTINCT C.*, CP.intClearanceStatus as PathStatus, CP.intClearancePathID, CONCAT(M.strSurname, " ", M.strFirstname) as MemberName, SourceClub.strName as SourceClubName, DestinationClub.strName as DestinationClubName, SourceAssoc.strName as SourceAssocName, DestinationAssoc.strName as DestinationAssocName, CP.curPathFee, M.strSuburb, M.strState, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB, CP.intID, CP.intTypeID, CP2.intClearanceDevelopmentFeeID as DevelopmentFeeID, CP.intPlayerFinancial, CP.intPlayerSuspended, CP.intDenialReasonID, CP.intTableType, CP.strPathNotes, CP.strPathFilingNumber, DATE_FORMAT(dtPermitFrom,'%d/%m/%Y') AS dtPermitFromFORMATTED,DATE_FORMAT(dtPermitTo,'%d/%m/%Y') AS dtPermitToFORMATTED, CP.curDevelFee, CP.strApprovedBy, CP.dtAlert, CP.strOtherDetails1
                FROM tblClearance as C
                        INNER JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                        INNER JOIN tblMember as M ON (M.intMemberID = C.intMemberID)
                        INNER JOIN tblAssoc as SourceAssoc ON (SourceAssoc.intAssocID = C.intSourceAssocID)
                        INNER JOIN tblAssoc as DestinationAssoc ON (DestinationAssoc.intAssocID = C.intDestinationAssocID)
                        LEFT JOIN tblClub as SourceClub ON (SourceClub.intClubID = C.intSourceClubID)
                        LEFT JOIN tblClub as DestinationClub ON (DestinationClub.intClubID = C.intDestinationClubID)
			LEFT JOIN tblClearancePath as CP2 ON (CP2.intClearanceID = C.intClearanceID and CP2.intClearanceDevelopmentFeeID > 0)
                WHERE C.intClearanceID= $cID
			$cpID_WHERE
        ];
	#BAFF HERE
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $dref = $query->fetchrow_hashref() || undef;

	 my $intID=0;
        $intID = $Data->{'clientValues'}{'clubID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
        $intID = $Data->{'clientValues'}{'assocID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ASSOC);
        $intID = $Data->{'clientValues'}{'zoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ZONE);
        $intID = $Data->{'clientValues'}{'regionID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION);
        $intID = $Data->{'clientValues'}{'stateID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_STATE);
        $intID = $Data->{'clientValues'}{'natID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_NATIONAL);
        $intID = $Data->{'clientValues'}{'intzoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTZONE);
        $intID = $Data->{'clientValues'}{'intregID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTREGION);
        $intID = $Data->{'clientValues'}{'interID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_INTERNATIONAL); 
        my $intTypeID = $Data->{'clientValues'}{'currentLevel'};

	my $readonly = 0;
	my $extrafields_readonly = 0;
	$extrafields_readonly = 1 if ($dref->{intTypeID} != $intTypeID or $dref->{intID} != $intID or $dref->{intCurrentPathID} < $cpID);
	$readonly = 1 if ($dref->{intCurrentPathID} != $cpID);
	$readonly = 1 if ($dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED); #BAFF
	my $update_label = ($readonly and $extrafields_readonly) ? '' : "Update";
	$update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_UpdateCLR'} || $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || "Update $txt_Clr";
	my $id=0;
	my $edit=0;
  	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;
	$option='edit';

  	my $resultHTML = '';
	my $toplist='';

	my %DataVals=();
	my $RecordData={};
	$option = $dref->{intClearanceID} ? 'edit' : '';
	my $clrupdate=qq[
		UPDATE tblClearancePath 
			SET --VAL--
		WHERE intClearancePathID=$cpID
	];

	$option = 'display' if ($dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED and $Data->{'SystemConfig'}{'NoEditClearanceOnceApproved'}); 
	$option = 'display' if ($Data->{'ReadOnlyLogin'} and $Data->{'clientValues'}{'authLevel'}>=$Defs::LEVEL_ASSOC); ##BAFF
	my $st_developfees=qq[ SELECT intDevelopmentFeeID, strTitle FROM tblClearanceDevelopmentFees WHERE intRealmID = $Data->{'Realm'} and intCDRecStatus =1 ];
  	my ($developfees_vals,$developfees_order)=getDBdrop_down_Ref($Data->{'db'},$st_developfees,'');

	my $developfeeID = 1;

	my $developfeeType = 'lookup';
        my $developfeeValue = $dref->{'intClearanceDevelopmentFeeID'};
	my $developfeeReadonly = 0;

	if ($dref->{intClearanceDevelopmentFeeID})	{
		$developfeeType='text';
		$developfeeValue="Only one development fee is allowed for the $txt_Clr";
		$developfeeReadonly = 1;
	}

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        onlyTypes  => '-38',
    );
       
	$dref->{SourceAssocName} ||= $dref->{strSourceAssocName} || '';
                $dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
                $dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $strApprovedBy=($Data->{'SystemConfig'}{'clrHide_strApprovedBy'}==1) ? '1' : '0';
	my $dtAlert=($Data->{'SystemConfig'}{'clrHide_dtAlert'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';
	my $intPlayerActive =($Data->{'SystemConfig'}{'clrHide_intPlayerActive'}==1) ? '1' : '0';
	my $intCoachActive =($Data->{'SystemConfig'}{'clrHide_intCoachActive'}==1) ? '1' : '0';
	my $intMthOfficialActive =($Data->{'SystemConfig'}{'clrHide_intMthOfficialActive'}==1) ? '1' : '0';
	my $intMiscActive =($Data->{'SystemConfig'}{'clrHide_intMiscActive'}==1) ? '1' : '0';
	my $intVolunteerActive =($Data->{'SystemConfig'}{'clrHide_intVolunteerActive'}==1) ? '1' : '0';
	my $dtPermitFrom =($Data->{'SystemConfig'}{'clrHide_dtPermitFrom'}==1) ? '1' : '0';
	my $dtPermitTo = ($Data->{'SystemConfig'}{'clrHide_dtPermitTo'}==1) ? '1' : '0';
	my $ClearanceFee= ($Data->{'SystemConfig'}{'clrHide_clearanceFee'}==1) ? '1' : '0';
	my $intClearanceDevelopmentFeeID= ($Data->{'SystemConfig'}{'clrHide_intClearanceDevelopmentFeeID'}==1) ? '1' : '0';
	my $intPlayerFinancial= ($Data->{'SystemConfig'}{'clrHide_intPlayerFinancial'}==1) ? '1' : '0';
	my $intPlayerSuspended= ($Data->{'SystemConfig'}{'clrHide_intPlayerSuspended'}==1) ? '1' : '0';
	my $intDenialReasonID= ($Data->{'SystemConfig'}{'clrHide_intDenialReasonID'}==1) ? '1' : '0';
	my $DevelFee= ($Data->{'SystemConfig'}{'clrHide_curDevelFee'}==1) ? '1' : '0';
	$DevelFee = 1 if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
	my $OtherDetails1= ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'}) ? '0' : '1';
	
    my $showAgentFields = ($Data->{'SystemConfig'}{'clrHide_AgentFields'} == 1) ? '1' : '0';
	#my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || 'Update Clearance';
	my %FieldDefs = (
		CLR => {
			fields => {
					intClearanceID=> {
                                        label => "$txt_Clr Ref. No.",
                                        value => $dref->{'intClearanceID'},
                                        type  => 'text',
					readonly => '1',
                                },
				MemberName=> {
                                        label => 'Member being Cleared',
                                        value => $dref->{'MemberName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                dtDOB => {
                                        label => 'Date of birth',
                                        value => $dref->{'dtDOB'},
                                        type  => 'text',
					readonly => '1',
                                },
                                strSuburb => {
                                        label => 'Address Suburb',
                                        value => $dref->{'strSuburb'},
                                        type  => 'text',
					readonly => '1',
                                },
                                strState=> {
                                        label => 'Address State',
                                        value => $dref->{'strState'},
                                        type  => 'text',
					readonly => '1',
                                },
                                SourceClubName => {
                                        label => 'From Club',
                                        value => $dref->{'SourceClubName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                SourceAssocName => {
                                        label => 'From Association',
                                        value => $dref->{'SourceAssocName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                DestinationClubName => {
                                        label => 'To Club',
                                        value => $dref->{'DestinationClubName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                DestinationAssocName => {
                                        label => 'To Association',
                                        value => $dref->{'DestinationAssocName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                Reason=> {
                                        label => "Reason for $txt_Clr",
                                        value => $dref->{'strReason'},
                                        type  => 'text',
					readonly => '1',
                                },
				dtPermitFrom =>	{
					label => 'Permit Date From',
                    			value => $dref->{'dtPermitFromFORMATTED'},
                    			type  => 'date',
					readonly => '1',
				},
				dtPermitTo =>	{
					label => 'Permit Date To',
                    			value => $dref->{'dtPermitToFORMATTED'},
			                type  => 'date',
					readonly => '1',
				},
				intClearanceStatus=> {
					label => "$txt_Clr Status",
					value => $dref->{'PathStatus'},
                        		type  => 'lookup',
					options => \%Defs::clearance_status_approvals,
					compulsory => 1,
                        		firstoption => ['','Select Status'],
					readonly => $readonly,
                		},
				curPathFee => {
					label => 'Fee involved',
					value => $dref->{'curPathFee'},
					type => 'text',
					readonly => $readonly,
					noadd=> $ClearanceFee,
					noedit=> $ClearanceFee,
				},
				curDevelFee => {
					label => 'Development Fee',
					value => $dref->{'curDevelFee'},
					type => 'text',
					readonly => $readonly,
					noadd=> $DevelFee,
					noedit=> $DevelFee,
				},
				strOtherDetails1=> {
					label => $Data->{'SystemConfig'}{'clrOtherDetails1_Label'},
					value => $dref->{strOtherDetails1},
                                        type  => 'text',
					readonly => $readonly,
					noadd=>$OtherDetails1,
					noedit=>$OtherDetails1,
				},

				strPathNotes => {
					label => 'Additional Information',
					value => $dref->{'strPathNotes'},
					type => 'textarea',
					readonly => $extrafields_readonly,
				},
				dtAlert=> {
					label => 'Alert Date',
					value => $dref->{'dtAlert'},
					type => 'date',
					readonly => $extrafields_readonly,
					noadd=> $dtAlert,
					noedit=> $dtAlert,
				},
				strApprovedBy=> {
					label => 'Approved By',
					value => $dref->{'strApprovedBy'},
					type => 'text',
					readonly => $extrafields_readonly,
					noadd=> $strApprovedBy,
					noedit=> $strApprovedBy,
					compulsory => $Data->{'SystemConfig'}{'ClrApprovedBy_NotCompulsory'} ? 0 : 1,
				},
				strPathFilingNumber => {
					label => 'Reference Number at this level',
					value => $dref->{'strPathFilingNumber'},
					type => 'text',
					readonly => $extrafields_readonly,
					noadd=> $strFilingNumber,
					noedit=> $strFilingNumber,
				},
				intClearanceDevelopmentFeeID => {
                 		       	label => 'Development Fee',
                        		type => $developfeeType,
                        		value => $developfeeValue, 
 		                       	options =>  $developfees_vals,
                        		firstoption => ['','Select Development Fee'],
					readonly => $developfeeReadonly,
					readonly => $readonly,
					noadd=> $intClearanceDevelopmentFeeID,
					noedit=> $intClearanceDevelopmentFeeID,
                		},
				intPlayerFinancial=> {
					label => 'Player Financial ?',
					value => $dref->{'intPlayerFinancial'},
                        		type  => 'lookup',
					options => \%Defs::clearance_financial,
                        		firstoption => ['','Select Status'],
					readonly => $readonly,
					noadd=>$intPlayerFinancial,
					noedit=>$intPlayerFinancial,
                		},
				intPlayerSuspended=> {
					label => 'Player Suspended ?',
					value => $dref->{'intPlayerSuspended'},
                        		type  => 'lookup',
					options => \%Defs::clearance_suspended,
                        		firstoption => ['','Select Status'],
					readonly => $readonly,
					noadd=>$intPlayerSuspended,
					noedit=>$intPlayerSuspended,
                		},
				 intDenialReasonID=> {
        				label => "Reason for Denial",
				        value => $dref->{intDenialReasonID},
				        type  => 'lookup',
        				options => $DefCodes->{-38},
        				order => $DefCodesOrder->{-38},
					firstoption => ['',"Choose Reason"],
					readonly => $readonly,
					noadd=>$intDenialReasonID,
					noedit=>$intDenialReasonID,
	      			},
				intPermitType	=> {
                                        label => "Permit Type",
                                        value => $dref->{'intPermitType'},
                                        type  => 'lookup',
                                        options => \%{$Defs::clearancePermitType{$Data->{'Realm'}}},
					readonly => 1,
				},
				intHasAgent=> {
                    label => $showAgentFields ? '' : 'Player has an Agent ?',
                    value => $dref->{'intHasAgent'} ? 'Yes' : 'No',
                    type  => 'text',
                    readonly=>'1',
                },
                strAgentFirstname=> {
                    label => $showAgentFields ? '' :'Agent Firstname',
                    value => $dref->{'strAgentFirstname'},
                    type  => 'text',
                    readonly=>'1',
                },
                strAgentSurname=> {
                    label => $showAgentFields ? '' :'Agent Surname',
                    value => $dref->{'strAgentSurname'},
                    type  => 'text',
                    readonly=>'1',
                },
                strAgentNationality=> {
                    label => $showAgentFields ? '' :'Agent Nationality',
                    value => $dref->{'strAgentNationality'},
                    type  => 'text',
                    readonly=>'1',
                },
                strAgentLicenseNum=> {
                    label => $showAgentFields ? '' :'Agent License Number',
                    value => $dref->{'strAgentLicenseNum'},
                    type  => 'text',
                    readonly=>'1',
                },
                strAgencyName=> {
                    label => $showAgentFields ? '' :'Agency Name',
                    value => $dref->{'strAgencyName'},
                    type  => 'text',
                    readonly=>'1',
                },
                strAgencyEmail=> {
                    label => $showAgentFields ? '' :'Agency Email',
                    value => $dref->{'strAgentFirstname'},
                    type  => 'text',
                    readonly=>'1',
                },	
		},
		order => [qw(intClearanceID MemberName dtDOB strSuburb strState SourceClubName SourceAssocName DestinationClubName DestinationAssocName Reason intPermitType dtPermitFrom dtPermitTo intClearanceStatus strApprovedBy intDenialReasonID curPathFee curDevelFee strOtherDetails1 dtAlert strPathNotes intClearanceDevelopmentFeeID intPlayerFinancial intPlayerSuspended strPathFilingNumber intHasAgent strAgentFirstname strAgentSurname strAgentNationality strAgentLicenseNum strAgencyName strAgencyEmail)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'clr_form',
				submitlabel => $update_label,
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $clrupdate,
				auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          'Clearance Path'
        ],
        auditEditParams => [
          $cpID,
          $Data,
          'Update',
          'Clearance Path'
        ],

				afterupdateFunction => \&updateClearance,
				afterupdateParams=> [$option,$Data,$Data->{'db'}, $cID, $cpID],
				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_view&amp;cID=$cID&amp;cpID=$cpID">Return to $txt_Clr Details</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_details">Return to $txt_Clr Details</a>
				],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'CL_details',
				cpID => $cpID,
				cID => $cID,
			},
		},
	);
	$FieldDefs{'CLR'}{'fields'}{'intDenialReasonID'}{'compulsory'}=1 if ($Data->{'SystemConfig'}{'clrDenialReason_compulsory'} and param('d_intClearanceStatus') == $Defs::CLR_STATUS_DENIED);
	$FieldDefs{'CLR'}{'fields'}{'strOtherDetails1'}{'compulsory'}=1 if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'} 
        and $Data->{'SystemConfig'}{'clrDevelFees_OtherDetails1_compulsory'} 
        and param('d_intClearanceDevelopmentFeeID'));
	($resultHTML, undef )=handleHTMLForm($FieldDefs{'CLR'}, undef, $option, '',$db);
	$resultHTML = destinationClubText($Data) . $resultHTML if ($dref->{intDestinationClubID} == $dref->{intID} and $dref->{intTypeID} == $Defs::LEVEL_CLUB);

	my $clrDenialBlob=  $Data->{'SystemConfig'}{'ClearancesDenialBlob'} || '';
	$resultHTML .= $clrDenialBlob;

	$resultHTML .= showPathDetails($Data, $cID, $dref->{intClearanceStatus});

	if($option eq 'display')	{
		#$resultHTML .=allowedAction($Data, 'clr_s_e') ?qq[ <a href="$target?a=M_TXN_EDIT&amp;tID=$dref->{'intTransactionID'}&amp;client=$client">Edit Details</a> ] : '';
		$resultHTML .=qq[ <a href="$target?a=CL_details&amp;tID=$dref->{'intTransactionID'}&amp;client=$client">Edit Details</a> ] if !$Data->{'ReadOnlyLogin'};
	}

	$resultHTML .= memberLink($Data, $cID);


		$resultHTML=qq[
			<div>This member does not have any Transaction information to display.</div>
		] if !ref $dref;

		$resultHTML=qq[
				<div class="alphaNav">$toplist</div>
				<div>
					$resultHTML
				</div>
		];
		my $heading=qq[$txt_Clr];
		return ($resultHTML,$heading);
}

sub memberLink	{

	my ($Data, $cID) = @_;

	my $destClubID = $Data->{'clientValues'}{'clubID'} || -1;
	$cID ||= 0;

	my $st = qq[
		SELECT *
		FROM tblClearance
		WHERE intClearanceID = $cID
			AND intDestinationClubID = $destClubID
	];
	my $query = $Data->{'db'}->prepare($st) or query_error($st);
	$query->execute or query_error($st);
	my $dref=$query->fetchrow_hashref();

	if ($dref->{intClearanceID} and $dref->{intMemberID} and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED)	{
 		my %tempClientValues = %{$Data->{clientValues}};
        $tempClientValues{memberID} = $dref->{intMemberID};
        $tempClientValues{currentLevel} = $Defs::LEVEL_MEMBER;
        my $tempClient = setClient(\%tempClientValues);
		return qq[ <div class="OKmsg">The clearance has now been finalised</div><br><a href="$Data->{'target'}?client=$tempClient&amp;a=M_HOME">click here to display members record</a>&nbsp;|&nbsp;<a href="$Data->{'target'}?client=$tempClient&amp;a=M_DTE">click here to edit members record</a>];

	}
	return '';
}
sub destinationClubText	{

### PURPOSE: This function returns text that is displayed at the top of the clearance approval record when its the destination clubs turn to decide whether they actually want to member.  At this stage, all other levels would have approved the clearance.

	my ($Data) = @_;

	return '';
	my $body = $Data->{'SystemConfig'}{'clr_FinalApproval_txt'} || qq[By approving this clearance, you will receive the member.<br>You also agree to pay any Fees incurred by the transferring of this player];
	return qq[<p class="heading1" style="font-size:16px;color:red;">$body</p>];

}

sub updateClearance	{

### PURPOSE: This function is called as an afterupdatefunction of clearancePathDetails.
### It updates the clearance record to what ever status, notes etc.. that the logged in level gave the path record.

### Once its done, it will try and do any Auto Confirms, then will send an email.

	my($id,$params,$action,$Data,$db, $cID, $cpID)=@_;


	if ($params->{d_intClearanceStatus} == $Defs::CLR_STATUS_DENIED)	{
		my $st = qq[
			UPDATE tblClearance
			SET intClearanceStatus = $Defs::CLR_STATUS_DENIED, dtFinalised = NOW()
			WHERE intClearanceID = $cID
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		sendCLREmail($Data, $cID, 'DENIED');
	}
	else	{
		if ($params->{d_intClearanceStatus} == $Defs::CLR_STATUS_APPROVED)	{
			## IF it was denied, then reopen if appropriate
			my $st = qq[
				UPDATE tblClearance
				SET intClearanceStatus = $Defs::CLR_STATUS_PENDING, dtFinalised = NULL
				WHERE intClearanceID = $cID
					AND intClearanceStatus =$Defs::CLR_STATUS_DENIED 
				AND intCurrentPathID <= $cpID
			];
			### BAFF ADDED ABOVE !!!!!
			my $query = $db->prepare($st) or query_error($st);
			$query->execute or query_error($st);
		}
		checkAutoConfirms($Data, $cID, $cpID);
	}

	my $st = qq[
		SELECT intClearancePathID, intClearanceStatus
		FROM tblClearancePath
		WHERE intClearanceID = $cID
		ORDER BY intOrder DESC
		LIMIT 1
	];
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);
	my ($intFinalCPID, $intClearanceStatus) = $query->fetchrow_array();
	if ($intClearanceStatus == $Defs::CLR_STATUS_APPROVED)	{
		finaliseClearance($Data, $cID);
	}
	else	{
		sendCLREmail($Data, $cID, 'PATH_UPDATED');
	}
}

sub checkAutoConfirms	{

### PURPOSE: This function, when called from Clearance ADD or Path UPDATE, checks to see if any of the next path levels have Clearance Settings, and then applies these.
### Also, if the next path level is invisible (ie: an invisible zone level), then its auto confirmed.


	my($Data,$cID, $cpID)=@_;

	my $db = $Data->{'db'};
	$cpID ||= 0;
	my $cpWHERE = $cpID ? qq[ AND C.intCurrentPathID <= $cpID] : '';
	
	#LEFT JOIN tblClearanceSettings as CS ON (CS.intID = CP.intID AND CS.intTypeID = CP.intTypeID and (C.intAssocTypeID = CS.intAssocTypeID or CS.intAssocTypeID = 0))
	my $st = qq[
		SELECT CP.intClearancePathID, CP.intID, CP.intTypeID, C.intAssocTypeID, M.dtDOB, N.intStatusID, N.intNodeID, ASource.intAssocTypeID as SourceSubType, ADest.intAssocTypeID as DestSubType, intDirection,
            C.intDestinationAssocID,
            C.intSourceAssocID,
	C.intPermitType
		FROM tblClearance as C 
			INNER JOIN tblMember as M ON (M.intMemberID = C.intMemberID)
			INNER JOIN tblClearancePath as CP ON (C.intClearanceID = CP.intClearanceID)
			LEFT JOIN tblAssoc as ASource ON (ASource.intAssocID = C.intSourceAssocID) 
			LEFT JOIN tblAssoc as ADest ON (ADest.intAssocID = C.intDestinationAssocID) 
			LEFT JOIN tblNode as N ON (N.intNodeID = CP.intID AND CP.intTableType = $Defs::NODE_LEVEL_CLEARANCE)
		WHERE C.intClearanceID = $cID
			AND C.intClearanceStatus = 0
			AND CP.intClearanceStatus IN (0,2)
		ORDER BY CP.intOrder
	];
			#AND CP.intClearancePathID >= C.intCurrentPathID
##	WHEN LEFT JOINING TO TBLCLEARANCESETTINGS, ADD PATH DIRECTION & ASSOC_SUBTYPE ??
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my $st_path_update = qq[
		UPDATE tblClearancePath
		SET strApprovedBy = 'Auto Approved', intClearanceStatus = ?, curPathFee = ?
		WHERE intClearancePathID = ?
			AND intClearanceID = $cID
	];
	my $qry_path_update = $db->prepare($st_path_update) or query_error($st_path_update);

	my %pathIDs=();
	my $clearanceStatus = 0;
	my $currentPathID = 0;
	while (my $dref = $query->fetchrow_hashref())	{
		## BECAUSE WE ARE PULLING BACK MULTI RECORDS FOR EACH PATH RECORD (ie: FOR ASSOCTYPEID = xx and 0) NEED TO ONLY PROCESS THE PATHID ONCE.
		next if exists $pathIDs{$dref->{intClearancePathID}};
		next if ($clearanceStatus == 2);
		
		$pathIDs{$dref->{intClearancePathID}} = 1;

		$currentPathID = $dref->{intClearancePathID};
		my ($intAutoApproval, $curDefaultFee) = getClearanceSettings($Data, $dref->{intID}, $dref->{intTypeID}, $dref->{intAssocTypeID}, $dref->{dtDOB}, $dref->{intDirection}, $dref->{'intDestinationAssocID'}, $dref->{'intSourceAssocID'}, $dref->{'intPermitType'});
		if ($dref->{SourceSubType} and $dref->{DestSubType} and $dref->{SourceSubType} == $dref->{DestSubType} and $Data->{'SystemConfig'}{'clrSameSubTypeApproval'}) {
			$intAutoApproval = $Defs::CLR_AUTO_APPROVE;
		}
		if ($dref->{intNodeID} and $dref->{intStatusID} eq '0' and $intAutoApproval == 0)	{
			$intAutoApproval = $Defs::CLR_AUTO_APPROVE;
		}
		if ($intAutoApproval == $Defs::CLR_AUTO_APPROVE)	{
			my $clearancePathStatus = $intAutoApproval;
			$qry_path_update->execute($clearancePathStatus, $curDefaultFee, $dref->{intClearancePathID}) or query_error($st_path_update);
			$currentPathID = $dref->{intClearancePathID};
		}
		 elsif ($intAutoApproval == $Defs::CLR_AUTO_DENY)	{
			my $clearancePathStatus = $intAutoApproval;
			$clearanceStatus = 2;
			$currentPathID = $dref->{intClearancePathID};
			$qry_path_update->execute($clearancePathStatus, 0, $dref->{intClearancePathID}) or query_error($st_path_update);
		}
		else	{
			last;
		}

	}
	if ($currentPathID or $clearanceStatus)	{
	
		my $st_clr_update = qq[
			UPDATE tblClearance
			SET intCurrentPathID= $currentPathID, intClearanceStatus= $clearanceStatus
			WHERE intClearanceID = $cID
		];
		my $qry_clr_update = $db->prepare($st_clr_update) or query_error($st_clr_update);
		$qry_clr_update->execute or query_error($st_clr_update);
	}

	$query->finish();
}

sub getClearanceSettings	{
	
### PURPOSE: This function returns the clearance settings for the level and members DOB

	my($Data, $intID, $intTypeID, $intAssocTypeID, $dtDOB, $ruleDirection, $destinationAssocID, $sourceAssocID, $intPermitType)=@_;

	my $db = $Data->{'db'};
	$ruleDirection ||= $Defs::CLR_BOTH;
$intPermitType||= 0;
	
    my $ruleAssocCheck = '';
    if ($ruleDirection == $Defs::CLR_OUTWARD)   {
        $ruleAssocCheck = qq[ 
            AND (
                intRuleDirection = $Defs::CLR_OUTWARD
                AND intCheckAssocID IN (0, $sourceAssocID) 
                OR (
                    intRuleDirection = $Defs::CLR_BOTH
                    AND intCheckAssocID IN (0, $destinationAssocID, $sourceAssocID) 
                )
            )
         ];
    }
    elsif ($ruleDirection == $Defs::CLR_INWARD)   {
        $ruleAssocCheck = qq[ 
            AND (
                intRuleDirection = $Defs::CLR_INWARD
                AND intCheckAssocID IN (0, $destinationAssocID) 
                OR (
                    intRuleDirection = $Defs::CLR_BOTH
                    AND intCheckAssocID IN (0, $destinationAssocID, $sourceAssocID) 
                )
            )
         ];
    }
    else    {
        $ruleAssocCheck = qq[ AND intCheckAssocID IN (0, $destinationAssocID, $sourceAssocID)];
    }
	my $st = qq[
		SELECT intClearanceSettingID, intAutoApproval , curDefaultFee, intRuleDirection
		FROM tblClearanceSettings
		WHERE intID = $intID
			AND intTypeID = $intTypeID
			AND (intAssocTypeID = $intAssocTypeID or intAssocTypeID = 0 or intAssocTypeID IS NULL)
			AND (dtDOBStart <= '$dtDOB' or dtDOBStart = '0000-00-00' or dtDOBStart IS NULL)
				AND (dtDOBEnd >= '$dtDOB' or dtDOBEnd = '0000-00-00' or dtDOBEnd IS NULL)
			AND intRuleDirection IN ($ruleDirection, $Defs::CLR_BOTH)
            $ruleAssocCheck
		AND (
                intClearanceType = $intPermitType
                OR
                ($intPermitType = 0 and intClearanceType = -99)
				OR 
				(intClearanceType = 0)
            )
		ORDER BY intCheckAssocID DESC, intRuleDirection DESC, intAssocTypeID DESC , dtDOBStart
		LIMIT 1
	];
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my ($intClearanceSettingID, $intAutoApproval, $curDefaultFee, $intRuleDirection) = $query->fetchrow_array();
	$intRuleDirection ||= $Defs::CLR_BOTH;
	$intClearanceSettingID ||= 0;
	$intAutoApproval ||= 0;
	if (! $intClearanceSettingID)	{
		$intAutoApproval = $Data->{'SystemConfig'}{'clrDefaultApprovalAction'} || 0;
		$intAutoApproval = ($Data->{'SystemConfig'}{'clrDefaultApprovalAction_'.$intAssocTypeID}) ? $Data->{'SystemConfig'}{'clrDefaultApprovalAction_'.$intAssocTypeID}: $intAutoApproval ;
	}
	$curDefaultFee ||= 0;

	return ($intAutoApproval, $curDefaultFee);
	
	
}

sub finaliseClearance	{

### PURPOSE: Once the clearance has been finalised, this function inserts the appropriate member_club, member_assoc & member_type records.

### Once done, it notifies all the levels via email of the current clearance status (ie:Finalised).

	my ($Data, $cID) = @_;

	### If successful, move person and notify everyone.
	my $db = $Data->{'db'};

	my $st = qq[
		SELECT C.intMemberID, C.intDestinationAssocID, C.intDestinationClubID, C.intPlayerActive, C.intCoachActive, C.intMthOfficialActive, C.intMiscActive, C.intVolunteerActive, DATE_FORMAT(C.dtPermitFrom,'%Y-%m-%d') AS dtPermitFrom, DATE_FORMAT(dtPermitTo,'%Y-%m-%d') AS dtPermitTo, C.intSourceAssocID, C.intSourceClubID, M.intGender, DATE_FORMAT(M.dtDOB, "%Y%m%d") as DOBAgeGroup, intPermitType, IF(CONCAT(DATE_FORMAT(C.dtPermitTo,'%Y-%m-%d'), ' 23:59:59') < NOW(), 1 , 0) as EndPermit, A.intAssocClrStatus

		FROM tblClearance as C
			INNER JOIN tblMember as M ON (M.intMemberID = C.intMemberID)
            LEFT JOIN tblAssoc as A ON (A.intAssocID = C.intDestinationAssocID)
		WHERE intClearanceID = $cID
	];
#IF(dtPermitTo < NOW(), 1 , 0) as EndPermit
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my ($intMemberID, $intAssocID, $intClubID, $intPlayerActive, $intCoachActive, $intMthOfficialActive, $intMiscActive, $intVolunteerActive, $dtPermitFrom, $dtPermitTo, $intSourceAssocID, $intSourceClubID, $Gender, $DOBAgeGroup, $intPermitType, $endPermit, $assocClrStatus) = $query->fetchrow_array();
	$intMemberID ||= 0;
	$intAssocID ||= 0;
	$intClubID ||= 0;
	$intPlayerActive ||= 0;
	$intCoachActive ||= 0;
	$intMthOfficialActive ||= 0;
	$intMiscActive ||= 0;
	$intVolunteerActive ||= 0;
	$intSourceAssocID ||= 0;
	$intSourceClubID ||= 0;
	$Gender ||= 0;
	$DOBAgeGroup ||= '';
	$intPermitType ||= 0;

	return if ! $intMemberID or ! $intAssocID or ! $intClubID;

	my $genAgeGroup||=new GenAgeGroup ($Data->{'db'},$Data->{'Realm'}, $Data->{'RealmSubType'}, $intAssocID);
	my $ageGroupID =$genAgeGroup->getAgeGroup($Gender, $DOBAgeGroup) || 0;

	$st = qq[
		SELECT intMemberAssociationID
		FROM tblMember_Associations
		WHERE intMemberID = $intMemberID
			AND intAssocID = $intAssocID
		LIMIT 1
	];
	$query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);
	my $intMemberAssocID = $query->fetchrow_array();
	$intMemberAssocID ||= 0;

	my $intMA_Status = $Defs::RECSTATUS_ACTIVE;
	if (exists $Data->{'SystemConfig'}{'clrStatusAtDestination'})	{
		$intMA_Status = $Data->{'SystemConfig'}{'clrStatusAtDestination'} || 0;
	}
    $intMA_Status = $assocClrStatus if (!$intMA_Status and $assocClrStatus);
	$st = qq[
		INSERT INTO tblMember_Associations
		(intMemberID, intAssocID, intRecStatus)
		VALUES ($intMemberID, $intAssocID, $intMA_Status)
	];
	$st = qq[
		UPDATE tblMember_Associations
		SET intRecStatus = $intMA_Status
		WHERE intMemberID = $intMemberID
			AND intMemberAssociationID = $intMemberAssocID
	] if $intMemberAssocID;

	$db->do($st);
	my %types = ();
        $types{'intPlayerStatus'} = 1 if ($intPlayerActive);
        $types{'intCoachStatus'} = 1 if ($intCoachActive);
        $types{'intOfficialStatus'} = 1 if ($intMthOfficialActive);
        $types{'intMiscStatus'} = 1 if ($intMiscActive);
        $types{'intVolunteerStatus'} = 1 if ($intVolunteerActive);
	$Data->{'OverrideAssocID'} = $intAssocID;
	my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
	$types{'intMSRecStatus'} = 1;
	Seasons::insertMemberSeasonRecord($Data, $intMemberID, $assocSeasons->{'newRegoSeasonID'}, $intAssocID, 0, $ageGroupID, \%types);

	if ($Data->{'SystemConfig'}{'clrInactiveSourceAssoc'} and $intAssocID != $intSourceAssocID and $intPermitType != 1 and $intPermitType != 2)	{
		$st =qq[
			UPDATE tblMember_Associations
			SET intRecStatus = $Defs::RECSTATUS_INACTIVE
			WHERE intMemberID = $intMemberID
				AND intAssocID = $intSourceAssocID
			LIMIT 1
		];
#print STDERR "\nCLR_UPDATE_IN$cID: $st : $Defs::CLRPERMIT_MATCHDAY | $Defs::CLRPERMIT_LOCALINTX | $Defs::CLRPERMIT_TRANSFER | $intPermitType\n";
		$db->do($st);
	}
	else	{
#print STDERR "\nCLR_NOT_RUNNING_ASSOC_INACTIVE:$cID|REALM:$Data->{'Realm'}|$Defs::CLRPERMIT_MATCHDAY|$Defs::CLRPERMIT_LOCALINTX|$Defs::CLRPERMIT_TRANSFER|$intPermitType|$intAssocID|$intSourceAssocID\n";
	}
	

	$st = qq[
		SELECT intMemberClubID
		FROM tblMember_Clubs
		WHERE intMemberID = $intMemberID
			AND intClubID = $intClubID
			AND intStatus = $Defs::RECSTATUS_ACTIVE
			AND intPermit = 0
		LIMIT 1
	];
	$query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);
	my $intMemberClubID = $query->fetchrow_array();
	$intMemberClubID ||= 0;

	my $intPermit = (($dtPermitFrom and $dtPermitFrom ne '0000-00-00') or ($dtPermitTo and $dtPermitTo ne '0000-00-00')) ? 1 : 0;
	$intPermit =1 if ($intPermitType);
	#$intPermit=0; ### SET BY BI ON 23/3/07 due to not being sent to SWC
	$st = qq[
		INSERT INTO tblMember_Clubs
		(intMemberID, intClubID, intStatus, intPermit, dtPermitStart, dtPermitEnd)
		VALUES ($intMemberID, $intClubID, $Defs::RECSTATUS_ACTIVE, $intPermit, '$dtPermitFrom', '$dtPermitTo')
	];

	$intMemberClubID=0 if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $intPermit);
	$st = qq[
		UPDATE tblMember_Clubs
		SET intStatus = $Defs::RECSTATUS_ACTIVE
		WHERE intMemberID = $intMemberID
			AND intMemberClubID = $intMemberClubID
	] if $intMemberClubID;
	$db->do($st);

    #if ($intMemberClubID and ! $intPermit)  {
    if (! $intPermit)  {
	   $st = qq[
           UPDATE 
               tblMember_Clubs
           SET 
               intStatus = $Defs::RECSTATUS_DELETED
           WHERE intMemberID = $intMemberID 
               AND intClubID = $intClubID
               AND intPermit=1
    ];
	$db->do($st);
    }                    

	#$st = qq[
	#	UPDATE tblMember_Clubs
	#	SET intStatus = $Defs::RECSTATUS_INACTIVE
	#	WHERE intMemberID = $intMemberID
	#		AND intClubID = $intClubID
	#		AND intPermit=1
	#];
	#$db->do($st);

	%types = ();
        $types{'intPlayerStatus'} = 1 if ($intPlayerActive);
        $types{'intCoachStatus'} = 1 if ($intCoachActive);
        $types{'intOfficialStatus'} = 1 if ($intMthOfficialActive);
        $types{'intMiscStatus'} = 1 if ($intMiscActive);
        $types{'intVolunteerStatus'} = 1 if ($intVolunteerActive);
	Seasons::insertMemberSeasonRecord($Data, $intMemberID, $assocSeasons->{'newRegoSeasonID'}, $intAssocID, $intClubID, $ageGroupID, \%types);

	if ($Data->{'SystemConfig'}{'clrInactiveSourceClub'} and $intClubID != $intSourceClubID and $intPermitType != 1 and $intPermitType != 2)	{
		$st =qq[
			UPDATE tblMember_Clubs
			SET intStatus = $Defs::RECSTATUS_INACTIVE
			WHERE intMemberID = $intMemberID
				AND intClubID = $intSourceClubID
				AND intStatus = $Defs::RECSTATUS_ACTIVE
				AND intPermit = 0
		];
		$db->do($st);
		$st =qq[
			UPDATE tblMember_Teams as MT
				INNER JOIN tblTeam as T ON (T.intTeamID = MT.intTeamID)
			SET MT.intStatus = $Defs::RECSTATUS_INACTIVE
			WHERE MT.intMemberID = $intMemberID
				AND T.intClubID = $intSourceClubID
				AND MT.intStatus = $Defs::RECSTATUS_ACTIVE
				AND T.intAssocID = $intSourceAssocID
		];
		$db->do($st);
	}
	else	{
#print STDERR "\nCLR_NOT_RUNNING_CLUB_INACTIVE:$cID|REALM:$Data->{'Realm'}|CLUB:$intSourceClubID|C2:$intSourceClubID|$Defs::CLRPERMIT_MATCHDAY|$Defs::CLRPERMIT_LOCALINTX|$Defs::CLRPERMIT_TRANSFER|$intPermitType\n";
	}

	if ($intPlayerActive)	{
		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intMemberID = $intMemberID 
				AND intAssocID=$intAssocID
				AND intTypeID=$Defs::MEMBER_TYPE_PLAYER
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE, intActive=1	
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intMemberID, intAssocID, intRecStatus, intTypeID, intActive)
				VALUES ($intMemberID, $intAssocID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_PLAYER, 1)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblMember
			SET intPlayer = 1
			WHERE intMemberID=$intMemberID
		];
		$db->do($st);
	}
	if ($intCoachActive)	{
		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intMemberID = $intMemberID 
				AND intAssocID=$intAssocID
				AND intTypeID=$Defs::MEMBER_TYPE_COACH
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE, intActive=1	
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intMemberID, intAssocID, intRecStatus, intTypeID, intActive)
				VALUES ($intMemberID, $intAssocID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_COACH, 1)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblMember
			SET intCoach = 1
			WHERE intMemberID=$intMemberID
		];
		$db->do($st);
	}
	if ($intMthOfficialActive)	{
		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intMemberID = $intMemberID 
				AND intAssocID=$intAssocID
				AND intTypeID=$Defs::MEMBER_TYPE_UMPIRE
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE, intActive=1	
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intMemberID, intAssocID, intRecStatus, intTypeID, intActive)
				VALUES ($intMemberID, $intAssocID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_UMPIRE, 1)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblMember
			SET intUmpire = 1
			WHERE intMemberID=$intMemberID
		];
		$db->do($st);
		
	}
	if ($intMiscActive)	{
		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intMemberID = $intMemberID 
				AND intAssocID=$intAssocID
				AND intTypeID=$Defs::MEMBER_TYPE_MISC
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE, intActive=1	
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intMemberID, intAssocID, intRecStatus, intTypeID, intActive)
				VALUES ($intMemberID, $intAssocID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_MISC, 1)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblMember
			SET intMisc = 1
			WHERE intMemberID=$intMemberID
		];
		$db->do($st);
	}
	if ($intVolunteerActive)	{
		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intMemberID = $intMemberID 
				AND intAssocID=$intAssocID
				AND intTypeID=$Defs::MEMBER_TYPE_VOLUNTEER
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE, intActive=1	
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intMemberID, intAssocID, intRecStatus, intTypeID, intActive)
				VALUES ($intMemberID, $intAssocID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_VOLUNTEER, 1)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblMember
			SET intVolunteer = 1
			WHERE intMemberID=$intMemberID
		];
		$db->do($st);
	}

	$st = qq[
		UPDATE tblMember
		SET intStatus = $Defs::RECSTATUS_ACTIVE
		WHERE intMemberID = $intMemberID
			AND intStatus = $Defs::RECSTATUS_DELETED
		LIMIT 1
	];
	$db->do($st);
	$st = qq[
		UPDATE tblClearance
		SET intClearanceStatus = $Defs::CLR_STATUS_APPROVED, dtFinalised=NOW()
		WHERE intClearanceID = $cID
	];
	$db->do($st);

	$st = qq[
		DELETE FROM tblMember_ClubsClearedOut
		WHERE intRealmID = $Data->{'Realm'}
			AND intAssocID = $intAssocID
			AND intClubID = $intClubID
			AND intMemberID = $intMemberID
	];
	$db->do($st);

	if (! $intPermitType)	{
		$st = qq[
			INSERT INTO tblMember_ClubsClearedOut
			(intRealmID, intAssocID, intClubID, intMemberID, intClearanceID, intCurrentSeasonID)
			VALUES ($Data->{'Realm'}, $intSourceAssocID, $intSourceClubID, $intMemberID, $cID, $assocSeasons->{'newRegoSeasonID'})
		];
		$db->do($st);
	}


#### CHECK IF PERMIT OVER ?
	if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $endPermit and $intPermitType)	{
		clearanceReversePermit($Data, $intMemberID, $intSourceAssocID, $intSourceClubID, $intAssocID, $intClubID, $dtPermitTo);
	}

	sendCLREmail($Data, $cID, 'FINALISED');

}

sub clearanceReversePermit	{

	my ($Data, $memberID, $sourceAssocID, $sourceClubID, $destinationAssocID, $destinationClubID, $dtPermitEnd) = @_;

	$memberID || return;
	$sourceAssocID || return;
	$sourceClubID || return;
	$destinationAssocID || return
	$destinationClubID || return;

	my $st_updateSource = qq[
        	UPDATE
                	tblMember_Clubs
                SET
                        intStatus = $Defs::RECSTATUS_ACTIVE
                WHERE
                        intMemberID = $memberID
                        AND intClubID = $sourceClubID
                        AND intStatus = $Defs::RECSTATUS_INACTIVE
                ORDER BY intPermit
                LIMIT 1
	];
        $Data->{'db'}->do($st_updateSource);
        my $st_updatePermittedClub= qq[
        	UPDATE
        		tblMember_Clubs
	        SET
        		intStatus = $Defs::RECSTATUS_INACTIVE
	        WHERE
        		intMemberID = $memberID
	        	AND intClubID = $destinationClubID
        		AND intPermit = 1
		        AND intStatus = $Defs::RECSTATUS_ACTIVE
		        AND dtPermitEnd = "$dtPermitEnd"
        ];
        $Data->{'db'}->do($st_updatePermittedClub);
	if ($destinationAssocID != $sourceAssocID)	{
        	my $st_updateassoc = qq[
        		UPDATE
			        tblMember_Associations
		        SET
			        intRecStatus=0
		        WHERE
			        intMemberID = $memberID
			        AND intAssocID = $destinationAssocID
	        ];
        	$Data->{'db'}->do($st_updateassoc);
	        $st_updateassoc = qq[
        		UPDATE
			        tblMember_Associations
		        SET
			        intRecStatus=1
		        WHERE
			        intMemberID = $memberID
			        AND intAssocID = $sourceAssocID
        	];
	        $Data->{'db'}->do($st_updateassoc);
	}
        my $st_clubsCleared = qq[
        	DELETE FROM
        		tblMember_ClubsClearedOut
	        WHERE
        		intMemberID = $memberID
		        AND intAssocID = $sourceAssocID
		        AND intClubID = $sourceClubID
        ];
        $Data->{'db'}->do($st_clubsCleared);

	return;
}

sub createClearance	{

### PURPOSE: This function is used to create the clearance.  It prepares all of the screens in the create clearance wizard and then passes control to clearanceForm() (a HTMLForm function) to actually display the clearance questions and insert the records into db.

	my ($action, $Data) = @_;


	#my $db = $Data->{'db'};
	my $db = connectDB('reporting');
	my $q=new CGI;
        my %params=$q->Vars();
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';

	
	my $destinationAssocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;

	my $sourceAssocID = $params{'sourceAssocID'} || $params{'d_sourceAssocID'} || 0;
	my $sourceStateID = $params{'sourceStateID'} || $params{'d_sourceStateID'} || 0;
	my $sourceClubID = $params{'sourceClubID'} || $params{'d_sourceClubID'} || 0;

	my $memberID = $params{'memberID'} || $params{'d_memberID'} || 0;
	$params{'member_surname'} ||= '';
	$params{'member_dob'} ||= '';
	$params{'member_natnum'} ||= '';
	$params{'member_loggedsurname'} ||= '';
	$params{'member_systemsurname'} ||= '';
	$params{'member_dob'}=  '' if ! check_valid_date($params{'member_dob'});
	$params{'member_dob'}= _fix_date($params{'member_dob'}) if (check_valid_date($params{'member_dob'}));
	$params{'member_systemdob'}=  '' if ! check_valid_date($params{'member_systemdob'});
	$params{'member_systemdob'}= _fix_date($params{'member_systemdob'}) if (check_valid_date($params{'member_systemdob'}));

	my $body = '';

	my $hidden='';
	for my $key (keys %params)	{
		next if ($key =~ /^member_/);
		next if (! $params{$key});
		$hidden .= qq[ <input type="hidden" value="$params{$key}" name="$key">];
	}
	if (! $destinationAssocID or ! $destinationClubID)	{
		$body .=qq[Assoc or Club not found];
		return $body;
	}

	if (! $sourceStateID and ! $params{'member_natnum'} and ! $params{'member_loggedsurname'} and ! ($params{'member_systemsurname'} and $params{'member_systemdob'}))	{
        my $subRealmFilter = '';
        $subRealmFilter = qq[ AND intSubTypeID=$Data->{'RealmSubType'}] if ($Data->{'SystemConfig'}{'clr_FilterSubRealms'});
		my $st = qq[
			SELECT intNodeID, strName	
			FROM tblNode
			WHERE intRealmID = $Data->{'Realm'}
				AND intTypeID = $Defs::LEVEL_STATE
				AND intHideClearances = 0
                $subRealmFilter
			ORDER BY strName
		];
				#AND intAssocTypeID = 0
		my $query = $db->prepare($st) or query_error($st);
	        $query->execute or query_error($st);

		my $state_body = qq[
			<select name="sourceStateID">
				<option SELECTED value='0'>--Select a Source $Data->{'LevelNames'}{$Defs::LEVEL_STATE}--</option>
		];
		while (my $dref = $query->fetchrow_hashref())	{
			$state_body .= qq[
				<option value="$dref->{intNodeID}">$dref->{strName}</option>
			];
		}
		$state_body .= qq[</select>];
		my $clrTEXT = $Data->{'SystemConfig'}{'txtRequestCLR'} || "Request a $txt_Clr";
		$body .= qq[
			<form action="$Data->{'target'}" method="POST">
			<p class=""><b>Please fill in the appropriate information below to $clrTEXT</b></p>
			<table>
			<tr><td colspan="2">Select the Source $Data->{'LevelNames'}{$Defs::LEVEL_STATE} from which the required member is from.</td></tr>
			<tr><td>$Data->{'LevelNames'}{$Defs::LEVEL_STATE} Body:</td><td>$state_body</td></tr>
			<tr><td colspan="2">&nbsp;</td></tr>
			<tr><td colspan="2"><b>OR</b></td></tr>
			<tr><td>Search on $Data->{'SystemConfig'}{'NationalNumName'}:</td><td><span class="formw"><input type="text" name="member_natnum" value=""></td></tr>
		];
		$body .=qq[
			<tr><td colspan="2">&nbsp;</td></tr>
			<tr><td colspan="2"><b>OR</b></td></tr>
			<tr><td colspan="2">You are logged in at a <b>$Defs::LevelNames{$Data->{'clientValues'}{'authLevel'}}</b> level. Search by Surname for members below this level.</td></tr>
			<tr><td>Surname:</td><td><span class="formw"><input type="text" name="member_loggedsurname" value=""></td></tr>
		] if ($Data->{'SystemConfig'}{'clrAuthSurnameSearch'});
		$body .=qq[
			<tr><td colspan="2">&nbsp;</td></tr>
			<tr><td colspan="2"><b>OR</b></td></tr>
			<tr><td colspan="2">Search system wide by Surname & Date of Birth</td></tr>
		<tr><td>Surname:</td><td><input type="text" name="member_systemsurname" value=""></td></tr>
		<tr><td>Date of Birth (dd/mm/yyyy):</td><td><span class="formw"><input type="text" name="member_systemdob" value=""></td></tr>
		] if ($Data->{'SystemConfig'}{'clrDOBSurnameSearch'});

		$body .= qq[
		</table>
			$hidden
			<input type="submit" name="submit" value="Select">	
			</form>
		];
	}
	elsif ($sourceStateID and ! $sourceAssocID)	{
		my $st = qq[
			SELECT A.intAssocID, A.strName	
			FROM tblAssoc as A
				INNER JOIN tblNodeLinks as NRegion ON (NRegion.intParentNodeID = $sourceStateID and NRegion.intPrimary=1)
				LEFT JOIN tblNodeLinks as NZone ON (NZone.intParentNodeID = NRegion.intChildNodeID and NZone.intPrimary=1)
				INNER JOIN tblAssoc_Node as AssocNode ON (AssocNode.intNodeID IN (NRegion.intChildNodeID, NZone.intChildNodeID))
			WHERE A.intRealmID = $Data->{'Realm'}
				AND A.intAssocID = AssocNode.intAssocID
				AND A.intAllowClearances=1
			ORDER BY A.strName
		];
				#AND intAssocTypeID = 0
		my $query = $db->prepare($st) or query_error($st);
	        $query->execute or query_error($st);

		my $assoc_body = qq[
			<select name="sourceAssocID">
				<option SELECTED value=''>--Select a Source $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}--</option>
		];
		while (my $dref = $query->fetchrow_hashref())	{
			$assoc_body .= qq[
				<option value="$dref->{intAssocID}">$dref->{strName}</option>
			];
		}
		$assoc_body .= qq[</select>];
		my $clrBlob=  $Data->{'SystemConfig'}{'ClearancesBlob'} || '';
		$body .= qq[
			<form action="$Data->{'target'}" method="POST">
			<p>Select the Source $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} from which the required member is from.</p>
			$clrBlob
			<p>$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}:$assoc_body</p>
			<input type="submit" name="submit" value="Select $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC}">	
			$hidden
			</form>
		];
	}
	elsif (! $sourceClubID and $sourceAssocID and $sourceStateID)	{
		my $st = qq[
			SELECT C.intClubID, C.strName	
			FROM tblAssoc_Clubs as AC INNER JOIN tblClub as C ON (AC.intClubID = C.intClubID)
			WHERE AC.intAssocID = $sourceAssocID
				AND AC.intRecStatus=1
				AND C.intRecStatus=1
			ORDER BY C.strName
		];
		my $query = $db->prepare($st) or query_error($st);
	        $query->execute or query_error($st);

		my $club_body = qq[
			<select name="sourceClubID">
				<option SELECTED value=''>--Select a Source Club--</option>
		];
		while (my $dref = $query->fetchrow_hashref())	{
			$club_body .= qq[
				<option value="$dref->{intClubID}">$dref->{strName}</option>
			];
		}
		$club_body .= qq[</select>];
		$body .= qq[
			<form action="$Data->{'target'}" method="POST">
			<p>Select a Source Club:$club_body</p>
			<input type="submit" name="submit" value="Select Club">
			$hidden
			</form>
		];
	}
	elsif	(! $memberID and ! $params{'member_surname'} and ! $params{'member_dob'} and ! $params{'member_natnum'} and ! $params{'member_loggedsurname'} and ! $params{'member_systemsurname'} and ! $params{'member_systemdob'})	{
		$body .= qq[
			<form action="$Data->{'target'}" method="POST">
			<p>Fill in the members $Data->{'SystemConfig'}{'NationalNumName'}, or enter Surname and DOB<br></p>
			<table>
			<tr><td><span class="label">Search on a $Data->{'SystemConfig'}{'NationalNumName'}:</span></td><td><span class="formw"><input type="text" name="member_natnum" value=""></span></td></tr>
			<tr><td colspan="2"><b>and/or</b></td></tr>
			<tr><td><span class="label">Search on Surname:</span></td><td><span class="formw"><input type="text" name="member_surname" value=""></span></td></tr>
			<tr><td colspan="2"><b>and/or</b></td></tr>
			<tr><td><span class="label">Search on Date of Birth (dd/mm/yyyy):</span></td><td><span class="formw"><input type="text" name="member_dob" value=""></span></td></tr>
			</table>
			<input type="submit" name="submit" value="Select Member">	
			$hidden
			</form>
		];
	}
	elsif	(! $memberID and ($params{'member_surname'} or $params{'member_dob'} or $params{'member_natnum'} or $params{'member_loggedsurname'} or ($params{'member_systemsurname'} and $params{'member_systemdob'})))	{
		my $strWhere = '';
		my %tParams = %params;
		deQuote($db, \%tParams);	
		if ($params{'member_natnum'})	{
			my $nn=$tParams{'member_natnum'};
			$nn="'$nn'" if $nn!~/'/; #'
			$strWhere .= qq[ AND M.strNationalNum = $nn];
		}
		if ($params{'member_surname'})	{
			$strWhere .= qq[ AND M.strSurname =$tParams{'member_surname'}];
		}
		if ($params{'member_loggedsurname'})	{
			$strWhere .= qq[ AND M.strSurname =$tParams{'member_loggedsurname'}];
		}
		if ($params{'member_systemsurname'})	{
			$strWhere .= qq[ AND M.strSurname =$tParams{'member_systemsurname'}];
		}
		if ($params{'member_systemdob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_systemdob'}];
		}
		if ($params{'member_dob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_dob'}];
		}
		if ($sourceAssocID)	{
			$strWhere .= qq[ AND MA.intAssocID = $sourceAssocID];
		}
		if ($sourceClubID)	{
			$strWhere .= qq[ AND MC.intClubID = $sourceClubID];
		}

	my $permitFilter = $Data->{'SystemConfig'}{'clrFilterPermitsOut'} ? qq[ AND MC.intPermit<>1] : '';
	my $MSPlayerJoin = '';
	if ($Data->{'SystemConfig'}{'clrFilterMSPlayers'})	{
		my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
		$MSPlayerJoin = qq[
			INNER JOIN $MStablename as MS ON (
				MS.intMemberID = M.intMemberID
				AND MS.intPlayerStatus=1
				AND MS.intAssocID = A.intAssocID
				AND MS.intClubID = MC.intClubID
			)
		];
	}
		my $st = qq[
			SELECT DISTINCT M.intMemberID, M.strFirstname, M.strSurname, M.strNationalNum, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS DOB, M.dtDOB, MC.intClubID, MA.intAssocID, C.strName as ClubName, A.strName as AssocName, DATE_FORMAT(MAX(CLR.dtFinalised),'%d/%m/%Y') AS CLR_DATE, IF(MC.intStatus = 1, 'Y', 'N') as Club_STATUS
			FROM tblMember as M 
				INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID $permitFilter)
				INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID)
				INNER JOIN tblAssoc as A ON (A.intAssocID = MA.intAssocID)
				INNER JOIN tblClub as C ON (C.intClubID = MC.intClubID)
				INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = C.intClubID and AC.intAssocID =A.intAssocID)
				LEFT JOIN tblClearance as CLR ON (CLR.intMemberID = M.intMemberID AND CLR.intDestinationClubID = C.intClubID)
				$MSPlayerJoin
		 WHERE M.intRealmID = $Data->{'Realm'}
                        AND C.intClubID <> $Data->{'clientValues'}{'clubID'}
                AND A.intAllowClearances=1
			AND AC.intRecStatus <> $Defs::RECSTATUS_DELETED
			AND C.intRecStatus <> $Defs::RECSTATUS_DELETED
			AND MC.intStatus <> $Defs::RECSTATUS_DELETED
                $strWhere
			GROUP BY M.intMemberID, A.intAssocID, C.intClubID
            ORDER BY M.strSurname, M.strFirstname, M.dtDOB

		];
		if ($params{'member_dob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_dob'}];
		}
		if ($sourceAssocID)	{
			$strWhere .= qq[ AND MA.intAssocID = $sourceAssocID];
		}
		if ($sourceClubID)	{
			$strWhere .= qq[ AND MC.intClubID = $sourceClubID];
		}

		my $CLRD_OUT_JOIN = qq[ LEFT JOIN tblMember_ClubsClearedOut as CLRD_OUT ON (CLRD_OUT.intAssocID = MA.intAssocID AND CLRD_OUT.intClubID = C.intClubID AND CLRD_OUT.intMemberID = M.intMemberID)];
		my $CLRD_OUT_WHERE = ''; #$Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} ? qq[ AND CLRD_OUT.intMemberID IS NULL] : '';

		my $permitJoinCheck='';
		my $permitWhereCheck='';
		if ($Data->{'SystemConfig'}{'clrFilterPermitsFromClubs'})	{
			## This will need to be commented out when Tony realises its stupid
				$permitJoinCheck = qq[
					LEFT JOIN tblMember_Clubs as MCPermit ON (
						MCPermit.intMemberID= M.intMemberID
						AND MCPermit.intPermit=1
						AND MCPermit.intClubID=MC.intClubID
						AND MCPermit.intStatus IN (0,1)
					)
				];
				$permitWhereCheck = qq[
					AND MCPermit.intMemberClubID IS NULL
				];
		}


		$st = qq[
			SELECT DISTINCT M.intDeRegister, M.intMemberID, M.strFirstname, M.strSurname, M.strNationalNum, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS DOB, M.dtDOB, MC.intClubID, MA.intAssocID, C.strName as ClubName, A.strName as AssocName, DATE_FORMAT(MAX(CLR.dtFinalised),'%d/%m/%Y') AS CLR_DATE, IF(MC.intStatus = 1, 'Y', 'N') as Club_STATUS, DATE_FORMAT(MA.dtLastRegistered, '%d/%m/%Y') AS LastRegistered, CLRD_OUT.intMemberID as CLRD_ID, MAX(MC.intPrimaryClub) as PrimaryClub

			FROM tblMember as M 
				INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID $permitFilter)
				INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID)
				INNER JOIN tblAssoc as A ON (A.intAssocID = MA.intAssocID)
				INNER JOIN tblClub as C ON (C.intClubID = MC.intClubID)
				INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = C.intClubID and AC.intAssocID =A.intAssocID)
				LEFT JOIN tblClearance as CLR ON (CLR.intMemberID = M.intMemberID AND CLR.intDestinationClubID = C.intClubID)
				$permitJoinCheck
				$CLRD_OUT_JOIN
				$MSPlayerJoin
			WHERE M.intRealmID = $Data->{'Realm'}
				AND C.intClubID <> $Data->{'clientValues'}{'clubID'}
				AND AC.intRecStatus <> $Defs::RECSTATUS_DELETED
				AND C.intRecStatus <> $Defs::RECSTATUS_DELETED
				AND MC.intStatus <> $Defs::RECSTATUS_DELETED
				AND A.intAllowClearances=1
				$permitWhereCheck
				$strWhere
				$CLRD_OUT_WHERE
			GROUP BY M.intMemberID, A.intAssocID, C.intClubID
			ORDER BY MAX(CLR.dtFinalised) DESC, M.strSurname, M.strFirstname, M.dtDOB
		];
		
		my $userID=getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'}) || 0;
		my $loggedInWHERE = '';
		$CLRD_OUT_JOIN = qq[ LEFT JOIN tblMember_ClubsClearedOut as CLRD_OUT ON (CLRD_OUT.intAssocID = tblMember_Associations.intAssocID AND CLRD_OUT.intClubID = C.intClubID AND CLRD_OUT.intMemberID = M.intMemberID)];

		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB)	{
			$loggedInWHERE = qq[ AND C.intClubID = $userID];
		}
		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_ASSOC)	{
			$loggedInWHERE = qq[ AND tblMember_Associations.intAssocID = $userID];
		}
		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_ZONE)	{
			$loggedInWHERE = qq[ AND tblZone.intNodeID = $userID];
		}
		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_REGION)	{
			$loggedInWHERE = qq[ AND tblRegion.intNodeID = $userID];
		}
		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_STATE)	{
			$loggedInWHERE = qq[ AND tblState.intNodeID = $userID];
		}
		if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_NATIONAL)	{
			$loggedInWHERE = qq[ AND tblNational.intNodeID = $userID];
		}


	if ($Data->{'SystemConfig'}{'clrFilterMSPlayers'})	{
		my $MStablename = "tblMember_Seasons_$Data->{'Realm'}";
		$MSPlayerJoin = qq[
			INNER JOIN $MStablename as MS ON (
				MS.intMemberID = M.intMemberID
				AND MS.intPlayerStatus=1
				AND MS.intAssocID = tblAssoc.intAssocID
				AND MS.intClubID = MC.intClubID
			)
		];
	}
		my $st2 = qq[
			SELECT DISTINCT M.intDeRegister, tblState.intNodeID as intStateID, tblNational.intNodeID, tblRegion.intNodeID, tblZone.intNodeID, M.intMemberID, M.strFirstname, M.strSurname, M.strNationalNum, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS DOB, M.dtDOB, MC.intClubID, tblMember_Associations.intAssocID, C.strName as ClubName, tblAssoc.strName as AssocName, DATE_FORMAT(MAX(CLR.dtFinalised),'%d/%m/%Y') AS CLR_DATE, IF(MC.intStatus = 1, 'Y', 'N') as Club_STATUS, DATE_FORMAT(tblMember_Associations.dtLastRegistered, '%d/%m/%Y') AS LastRegistered, CLRD_OUT.intMemberID as CLRD_ID, MAX(MC.intPrimaryClub) as PrimaryClub

			FROM 
				tblNode AS tblNational LEFT JOIN tblNodeLinks AS NL_N ON (NL_N.intPrimary=1 AND NL_N.intChildNodeID=tblNational.intNodeID AND tblNational.intTypeID=$Defs::LEVEL_NATIONAL) INNER JOIN
				tblNode AS tblState INNER JOIN tblNodeLinks AS NL_S ON (NL_S.intPrimary=1 AND NL_S.intChildNodeID=tblState.intNodeID AND tblState.intTypeID=30  ) INNER JOIN tblNode AS tblRegion INNER JOIN tblNodeLinks AS NL_R ON (NL_R.intPrimary=1 AND NL_R.intChildNodeID=tblRegion.intNodeID AND tblRegion.intTypeID=20  ) INNER JOIN tblNode AS tblZone INNER JOIN tblNodeLinks AS NL_Z ON (NL_Z.intPrimary=1 AND NL_Z.intChildNodeID=tblZone.intNodeID AND tblZone.intTypeID=10  ) INNER JOIN tblAssoc INNER JOIN tblAssoc_Node ON (tblAssoc_Node.intAssocID=tblAssoc.intAssocID   ) INNER JOIN tblMember as M INNER JOIN tblMember_Associations ON (M.intMemberID=tblMember_Associations.intMemberID) 
				INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID $permitFilter)
				INNER JOIN tblClub as C ON (C.intClubID = MC.intClubID)
				INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = C.intClubID and AC.intAssocID =tblAssoc.intAssocID)
				LEFT JOIN tblClearance as CLR ON (CLR.intMemberID = M.intMemberID AND CLR.intDestinationClubID = C.intClubID)
				$CLRD_OUT_JOIN
				$MSPlayerJoin
				$permitJoinCheck
			WHERE M.intRealmID = $Data->{'Realm'}
				AND C.intClubID <> $Data->{'clientValues'}{'clubID'}
				AND intAllowClearances=1
				AND MC.intStatus <> $Defs::RECSTATUS_DELETED
				$permitWhereCheck
				$strWhere
				$CLRD_OUT_WHERE
			AND  NL_R.intParentNodeID = tblState.intNodeID AND NL_S.intParentNodeID=tblNational.intNodeID  AND  NL_Z.intParentNodeID=tblRegion.intNodeID  AND  tblAssoc_Node.intNodeID = tblZone.intNodeID AND tblAssoc.intRecStatus <> -1 AND tblAssoc.intAssocID=tblMember_Associations.intAssocID AND M.intStatus <> -1
			$loggedInWHERE
			GROUP BY M.intMemberID, tblAssoc.intAssocID, C.intClubID
			ORDER BY MAX(CLR.dtFinalised) DESC, M.strSurname, M.strFirstname, M.dtDOB
		];


		my $st3 = qq[
			SELECT DISTINCT M.intDeRegister, tblState.intNodeID as intStateID, tblNational.intNodeID, tblRegion.intNodeID, tblZone.intNodeID, M.intMemberID, M.strFirstname, M.strSurname, M.strNationalNum, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS DOB, M.dtDOB, MC.intClubID, tblMember_Associations.intAssocID, C.strName as ClubName, tblAssoc.strName as AssocName, DATE_FORMAT(MAX(CLR.dtFinalised),'%d/%m/%Y') AS CLR_DATE, IF(MC.intStatus = 1, 'Y', 'N') as Club_STATUS, DATE_FORMAT(tblMember_Associations.dtLastRegistered, '%d/%m/%Y') AS LastRegistered, CLRD_OUT.intMemberID as CLRD_ID, MAX(MC.intPrimaryClub) as PrimaryClub
			FROM 
				tblNode AS tblNational LEFT JOIN tblNodeLinks AS NL_N ON (NL_N.intPrimary=1 AND NL_N.intChildNodeID=tblNational.intNodeID AND tblNational.intTypeID=$Defs::LEVEL_NATIONAL) INNER JOIN
				tblNode AS tblState INNER JOIN tblNodeLinks AS NL_S ON (NL_S.intPrimary=1 AND NL_S.intChildNodeID=tblState.intNodeID AND tblState.intTypeID=30  ) INNER JOIN tblNode AS tblRegion INNER JOIN tblNodeLinks AS NL_R ON (NL_R.intPrimary=1 AND NL_R.intChildNodeID=tblRegion.intNodeID AND tblRegion.intTypeID=20  ) INNER JOIN tblNode AS tblZone INNER JOIN tblNodeLinks AS NL_Z ON (NL_Z.intPrimary=1 AND NL_Z.intChildNodeID=tblZone.intNodeID AND tblZone.intTypeID=10  ) INNER JOIN tblAssoc INNER JOIN tblAssoc_Node ON (tblAssoc_Node.intAssocID=tblAssoc.intAssocID   ) INNER JOIN tblMember as M INNER JOIN tblMember_Associations ON (M.intMemberID=tblMember_Associations.intMemberID) 
				INNER JOIN tblMember_Clubs as MC ON (MC.intMemberID = M.intMemberID $permitFilter)
				INNER JOIN tblClub as C ON (C.intClubID = MC.intClubID)
				INNER JOIN tblAssoc_Clubs as AC ON (AC.intClubID = C.intClubID and AC.intAssocID =tblAssoc.intAssocID)
				LEFT JOIN tblClearance as CLR ON (CLR.intMemberID = M.intMemberID AND CLR.intDestinationClubID = C.intClubID)
				$CLRD_OUT_JOIN
				$MSPlayerJoin
				$permitJoinCheck
			WHERE M.intRealmID = $Data->{'Realm'}
						AND C.intClubID <> $Data->{'clientValues'}{'clubID'}
				AND intAllowClearances=1
				AND MC.intStatus <> $Defs::RECSTATUS_DELETED
				$strWhere
				$CLRD_OUT_WHERE
				$permitWhereCheck
			AND  NL_R.intParentNodeID = tblState.intNodeID AND NL_S.intParentNodeID=tblNational.intNodeID  AND  NL_Z.intParentNodeID=tblRegion.intNodeID  AND  tblAssoc_Node.intNodeID = tblZone.intNodeID AND tblAssoc.intRecStatus <> -1 AND tblAssoc.intAssocID=tblMember_Associations.intAssocID AND M.intStatus <> -1
			GROUP BY M.intMemberID, tblAssoc.intAssocID, C.intClubID
			ORDER BY MAX(CLR.dtFinalised) DESC, M.strSurname, M.strFirstname, M.dtDOB
		];


		
		$st = $st2 if ($params{'member_loggedsurname'} and $loggedInWHERE and $Data->{'SystemConfig'}{'clrAuthSurnameSearch'});
		$st = $st3 if ($params{'member_systemsurname'} and $params{'member_systemdob'} and $Data->{'SystemConfig'}{'clrDOBSurnameSearch'});
#		$st = $st3 if ($params{'member_natnum'} and $Data->{'SystemConfig'}{'clrNatNumSystemWide'});
		my $query = $db->prepare($st) or query_error($st);
	        $query->execute or query_error($st);

		my ($sourceClub, undef, undef) = getNodeDetails($db, $Defs::CLUB_LEVEL_CLEARANCE, $Defs::LEVEL_CLUB, $sourceClubID);
		my ($sourceAssoc, undef, undef)= getNodeDetails($db, $Defs::ASSOC_LEVEL_CLEARANCE, $Defs::LEVEL_ASSOC, $sourceAssocID);
		my $txt_RequestCLR =  $Data->{'SystemConfig'}{'txtRequestCLR'} || 'Request a Clearance';
		my $clrBlob=  $Data->{'SystemConfig'}{'ClearancesBlob'} || '';
		$body .= qq[
			<p>Select a member from the club <b>$sourceClub</b> in the Association <b>$sourceAssoc</b> in which to $txt_RequestCLR for.</p>$clrBlob
                	<table class="listTable">
				<tr>
					<th>&nbsp;</th>
					<th>Surname</th>
					<th>Firstname</th>
					<th>Association</th>
					<th>Club</th>
					<th>Date Cleared To ($Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Active ?)</th>
        ];
        $body .= qq[
					<th>Primary $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} ?</th>
        ] if ($Data->{'SystemConfig'}{'ClearancesShowPrimaryClub'});
        $body .= qq[
					<th>Date Last Registered</th>
					<th>DOB</th>
		];
		$body .= qq[
			<th>$Data->{'SystemConfig'}{'NationalNumName'}</th>
		];
		$body .= qq[
			</tr>
		];
		while (my $dref= $query->fetchrow_hashref())	{
			my $href = qq[client=$params{'client'}&amp;sourceAssocID=$dref->{'intAssocID'}&amp;sourceClubID=$dref->{'intClubID'}&amp;sourceStateID=$params{'sourceStateID'}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}];
			$href = qq[client=$params{'client'}&amp;sourceAssocID=$dref->{'intAssocID'}&amp;sourceClubID=$dref->{'intClubID'}&amp;sourceStateID=$dref->{intStateID}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}] if ($params{'member_loggedsurname'});
			$href = qq[client=$params{'client'}&amp;sourceAssocID=$dref->{'intAssocID'}&amp;sourceClubID=$dref->{'intClubID'}&amp;sourceStateID=$dref->{intStateID}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}] if ($params{'member_systemsurname'});
			$body .= qq[
				<tr>
			];
			if ($Data->{'SystemConfig'}{'AllowDeRegister'} and $dref->{intDeRegister})	{
				$body .= qq[<td><b>DEREGISTERED</b></td>];
			}
			elsif ($Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} and $dref->{CLRD_ID})	{
				$body .= qq[<td><b>CLEARED OUT</b></td>];
			}
			else	{
				$body .= qq[<td><a href="$Data->{'target'}?$href&amp;memberID=$dref->{intMemberID}">select</a></td>];
			}
			$body .= qq[
					<td>$dref->{strSurname}</td>
					<td>$dref->{strFirstname}</td>
					<td>$dref->{AssocName}</td>
					<td>$dref->{ClubName}</td>
					<td>$dref->{CLR_DATE} ($dref->{Club_STATUS})</td>
            ];
            my $primaryClub = ($dref->{PrimaryClub}) ? 'Yes' : 'No';
            $body .= qq[
					<td>$primaryClub</td>
            ] if ($Data->{'SystemConfig'}{'ClearancesShowPrimaryClub'});
            $body .= qq[
					<td>$dref->{LastRegistered}</td>
					<td>$dref->{DOB}</td>
			];
			$body .= qq[
					<td>$dref->{strNationalNum}</td>
			];
			$body .= qq[
				</tr>
			];
		}
		$body .= qq[</table>];
	}
	else	{
		my ($title, $cbody) = clearanceForm($Data, \%params,0,0,'add');
		
		$body .= $title . $cbody;
	}
	return $body;
}

sub clearanceForm	{

### PURPOSE: This function is called once the createClearance() function is ready to pass control to ask the destination club (who requested the clearance) the final clearance questions and then to write to DB.

### It has a preClearanceAdd() (beforeaddfunction), which checks whether the member is involved in another pending clearance (or already in destination club).

### It has a postClearanceAdd() (afteraddfunction), which will create the clearance path.

  my($Data, $params, $memberID, $id, $edit) = @_;
	$id ||= 0;	

	my $db=$Data->{'db'} || undef;
	my $assocID= $Data->{'clientValues'}{'assocID'} || -1;
	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;

	my $destinationAssocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;

	my $member_natnum= $params->{'member_natnum'} || 0;
	my $sourceAssocID = $params->{'sourceAssocID'} || 0;
	my $sourceClubID = $params->{'sourceClubID'} || 0;
	my $sourceStateID = $params->{'sourceStateID'} || 0;
	my $realm = $params->{'realmID'} || $Data->{'Realm'} || 0;

	my ($sourceClub, undef, undef) = getNodeDetails($db, $Defs::CLUB_LEVEL_CLEARANCE, $Defs::LEVEL_CLUB, $sourceClubID);
	my ($sourceAssoc, $intAssocTypeID, undef)= getNodeDetails($db, $Defs::ASSOC_LEVEL_CLEARANCE, $Defs::LEVEL_ASSOC, $sourceAssocID);
	$intAssocTypeID ||= 0;
	$memberID = $memberID || $params->{'memberID'} || 0;
	my $statement = qq[
		SELECT *, DATE_FORMAT(dtDOB,'%d/%m/%Y') AS DOB
		FROM tblMember 
		WHERE intMemberID = $memberID
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my $memref = $query->fetchrow_hashref();

	my $body = '';

  	my $resultHTML = '';

	$statement=qq[
		SELECT * 
		FROM tblClearance
		WHERE intClearanceID=$id
	];

	$query = $db->prepare($statement);
	my $RecordData={};
	$query->execute;
	my $dref=$query->fetchrow_hashref();
	my $clrupdate=qq[
		UPDATE tblClearance
			SET --VAL--
		WHERE intClearanceID=$id
	];
	my $intPlayerActive = $Data->{'SystemConfig'}{'clr_PlayerActive'} || 0;
	my $intClearanceYear =$Data->{'SystemConfig'}{'clrClearanceYear'} || 0;

	my ($dtDue, $dtReminder) = getDateDue($Data, $sourceAssocID, $destinationAssocID);
 
    my $clradd=qq[
        INSERT INTO tblClearance (intMemberID, intDestinationClubID, intSourceClubID, intDestinationAssocID, intSourceAssocID, intRealmID, --FIELDS--, dtApplied, intClearanceStatus, intAssocTypeID, intRecStatus, intClearanceYear, dtDue, dtReminder, intPlayerActive)
            VALUES ($memberID, $destinationClubID, $sourceClubID, $destinationAssocID, $sourceAssocID, $realm, --VAL--,  SYSDATE(), $Defs::CLR_STATUS_PENDING, $intAssocTypeID, $Defs::RECSTATUS_ACTIVE,  $intClearanceYear, "$dtDue", "$dtReminder", $intPlayerActive)
    ];

    ###LETS BUILD UP AN SQL STATEMENT WHERE intPlayerActive will come in --VAL-- & --FIELDS--
    $clradd = qq[
        INSERT INTO tblClearance (intMemberID, intDestinationClubID, intSourceClubID, intDestinationAssocID, intSourceAssocID, intRealmID, --FIELDS--, dtApplied, intClearanceStatus, intAssocTypeID, intRecStatus, intClearanceYear, dtDue, dtReminder)
            VALUES ($memberID, $destinationClubID, $sourceClubID, $destinationAssocID, $sourceAssocID, $realm, --VAL--,  SYSDATE(), $Defs::CLR_STATUS_PENDING, $intAssocTypeID, $Defs::RECSTATUS_ACTIVE,  $intClearanceYear, "$dtDue", "$dtReminder")
    ] if (! $intPlayerActive and ! $Data->{'SystemConfig'}{'clrHide_intPlayerActive'});

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        onlyTypes  => '-37',
    );
       
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';
	$intPlayerActive =($intPlayerActive or $Data->{'SystemConfig'}{'clrHide_intPlayerActive'}==1) ? '1' : '0';
	my $intCoachActive =($Data->{'SystemConfig'}{'clrHide_intCoachActive'}==1) ? '1' : '0';
	my $intMthOfficialActive =($Data->{'SystemConfig'}{'clrHide_intMthOfficialActive'}==1) ? '1' : '0';
	my $intMiscActive =($Data->{'SystemConfig'}{'clrHide_intMiscActive'}==1) ? '1' : '0';
	my $intVolunteerActive =($Data->{'SystemConfig'}{'clrHide_intVolunteerActive'}==1) ? '1' : '0';
	my $dtPermitFrom =($Data->{'SystemConfig'}{'clrHide_dtPermitFrom'}==1) ? '1' : '0';
	my $dtPermitTo = ($Data->{'SystemConfig'}{'clrHide_dtPermitTo'}==1) ? '1' : '0';
	my $intPermitType = ($dtPermitFrom or $dtPermitTo) ? '1' : '0';
	$dref->{'intPermitType'} ||= 0;

    my $showAgentFields = ($Data->{'SystemConfig'}{'clrHide_AgentFields'} == 1) ? '1' : '0';

	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || "Update $txt_Clr";
	my $update_labelClr= $Data->{'SystemConfig'}{'txtUpdateLabelClr_CLR'} || "Update $txt_Clr";
	my $update_labelOverride= $Data->{'SystemConfig'}{'txtUpdateLabelClrOverride'} || "Update $txt_Clr";
	### Date Permit From/To hidden on 19/4/07 as they contain issues
	my $defaulter = $memref->{intDefaulter} ? qq[<span style="color:red;font-weight:bold;">Member is a Defaulter</span>] : '';
	my $develfees= $memref->{intNatCustomBool2} ? qq[<span style="color:red;font-weight:bold;">Development Fees Apply</span>] : '';
	my %FieldDefs = (
		Clearance => {
			fields => {
				intNatCustomBool2=> {
                    			label=>($memref->{'intNatCustomBool2'} and $Data->{'SystemConfig'}{'clrExpose_intNatCustomBool2'}) ? $Data->{'SystemConfig'}{'clrExpose_intNatCustomBool2'} : '',
                    			options=> {1 => 'Yes', 0 => 'No'},
                    			type  => 'lookup',
                    			value => $memref->{'intNatCustomBool2'},
                    			readonly=>1,
                		},
				SourceAssoc => {
                                label => 'Source Association',
					value => $sourceAssoc,
					type=> 'text',
					readonly => 1,
				},
				SourceClub => {
					label => 'Source Club',
					value => $sourceClub,
					type=> 'text',
					readonly => 1,
				},
				MemberName => {
					label => "Member Name",
					value => qq[$memref->{strFirstname} $memref->{strSurname}],
					type=> 'text',
					readonly => 1,
				},
				NatNum=> {
					label => $Data->{'SystemConfig'}{'NationalNumName'},
					value => $memref->{'strNationalNum'},
                                        type  => 'text',
					readonly => '1',
                		},
				develfees=> {
					label => $Data->{'SystemConfig'}{'clrCheckDevelopmentFees'} ? 'Development Fees ?' : '',
					value => qq[$develfees],
                                        type  => 'text',
					readonly => '1',
                		},
				Defaulter=> {
					label => 'Defaulter ?',
					value => qq[$defaulter],
                                        type  => 'text',
					readonly => '1',
                		},
				DOB => {
					label => 'Date of birth',
					value => $memref->{'DOB'},
                                        type  => 'text',
					readonly => '1',
				},	
				strSuburb => {
					label => 'Address Suburb',
					value => $memref->{'strSuburb'},
                                        type  => 'text',
					readonly => '1',
                		},
				strState=> {
					label => 'Address State',
					value => $memref->{'strState'},
                                        type  => 'text',
					readonly => '1',
                		},
				 intReasonForClearanceID => {
        				label => "Reason for $txt_Clr",
				        value => $dref->{intReasonForClearanceID},
				        type  => 'lookup',
        				options => $DefCodes->{-37},
        				order => $DefCodesOrder->{-37},
					firstoption => ['',"Choose Reason"],
					readonly => $intReasonForClearanceID,
	      			},
				strReason=> {
					label => "Reason for $txt_Clr",
					value => $dref->{'strReason'},
                                        type  => 'text',
					readonly => $strReason,
				},	
				strReasonForClearance=> {
					label => 'Additional Information',
					type => 'textarea',
					value => $dref->{'strReasonForClearance'},
					rows => 5,
                			cols=> 45,
					readonly => $strReasonForClearance,
				},
				strFilingNumber => {
					label => 'Reference Number',
					value => $dref->{'strFilingNumber'},
                    type  => 'text',
					readonly => $strFilingNumber,
				},	
				BTNTEXT=> {
                           label => $intPermitType ? '' : "button text",
                           value => qq[<div class="HTbuttons"> <input type="submit" class="button proceed-button" name="subbut2" value="$update_labelClr" class="HF_submit" id="HFsubbut2"> </div>],
                           type  => 'textvalue',
                       },
                       intPermitType	=> {
                                            label => "Permit Type",
                                            value => $dref->{'intPermitType'},
                                            type  => 'lookup',
                                            options => \%{$Defs::clearancePermitType{$Data->{'Realm'}}},
                                            default=>'0',
                                            #firstoption => ['1','-None-'],
                                            readonly => $intPermitType,
                                        },
                       dtPermitFrom => {
                                        label => "Date Permit From",
                                        value => $dref->{'dtPermitFrom'},
                                        type=>'date',
                                        validate=>'DATE',
                                        format=> 'dd/mm/yyyy',
					readonly => $dtPermitFrom,
noedit=>1,
				},	
				dtPermitTo => {
					label => "Date Permit To",
					value => $dref->{'dtPermitTo'},
					type=>'date',
                                	validate=>'DATE',
                                	format=> 'dd/mm/yyyy',
					readonly => $dtPermitTo,
noedit=>1,
				},	
				PERMITTEXT=> {
                                        label => $intPermitType ? '' : "Permit text",
                                        value => $Data->{'SystemConfig'}{'CLRPermitText'},
                                        type  => 'textvalue',
				},
				intPlayerActive=> {
					label => 'Clear as Player Active ?',
					value => $dref->{'intPlayerActive'},
                                        type  => 'checkbox',
					default=>1,
					readonly=>$intPlayerActive,
					#readonly=>$Data->{'SystemConfig'}{'clrHide_intPlayerActive'},
				},	
				intCoachActive=> {
					label => 'Clear as Coach Active ?',
					value => $dref->{'intCoachActive'},
                                        type  => 'checkbox',
					readonly => $intCoachActive,
				},	
				intMthOfficialActive=> {
					label => 'Clear as Match Official Active ?',
					value => $dref->{'intMthOfficialActive'},
                                        type  => 'checkbox',
					readonly => $intMthOfficialActive,
				},	
				intMiscActive=> {
					label => 'Clear as Misc Active ?',
					value => $dref->{'intMiscActive'},
                                        type  => 'checkbox',
					readonly => $intMiscActive,
				},	
				intVolunteerActive=> {
					label => 'Clear as Volunteer Active ?',
					value => $dref->{'intVolunteerActive'},
                                        type  => 'checkbox',
					readonly => $intVolunteerActive,
				},	
				intClearancePriority=> {
                                        label => "$txt_Clr Priority",
                                        value => $dref->{'intClearancePriority'},
                                        type  => 'lookup',
                                        options => \%Defs::clearance_priority,
                                        firstoption => ['','Select Priority'],
					readonly => $intClearancePriority,
                                },
				
				intHasAgent=> {
					label => 'Player has an Agent ?',
					value => $dref->{'intHasAgent'},
                    type  => 'checkbox',
					readonly=>$showAgentFields,
				},	
				strAgentFirstname=> {
					label => 'Agent Firstname',
					value => $dref->{'strAgentFirstname'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
				strAgentSurname=> {
					label => 'Agent Surname',
					value => $dref->{'strAgentSurname'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
				strAgentNationality=> {
					label => 'Agent Nationality',
					value => $dref->{'strAgentNationality'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
				strAgentLicenseNum=> {
					label => 'Agent License Number',
					value => $dref->{'strAgentLicenseNum'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
				strAgencyName=> {
					label => 'Agency Name',
					value => $dref->{'strAgencyName'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
				strAgencyEmail=> {
					label => 'Agency Email',
					value => $dref->{'strAgentFirstname'},
                    type  => 'text',
					readonly=>$showAgentFields,
				},	
			},
			order => [qw(MemberName NatNum DOB Defaulter develfees intNatCustomBool2 strSuburb strState SourceAssoc SourceClub intReasonForClearanceID strReason strReasonForClearance strFilingNumber intClearancePriority intPlayerActive intCoachActive intMthOfficialActive intMiscActive intVolunteerActive intHasAgent strAgentFirstname strAgentSurname strAgentNationality strAgentLicenseNum strAgencyName strAgencyEmail BTNTEXT PERMITTEXT intPermitType dtPermitFrom dtPermitTo)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'clearance_form',
				submitlabel => $update_label,
				submitlabelOverride => $update_labelOverride,
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $clrupdate,
				addSQL => $clradd,
				beforeaddFunction => \&preClearanceAdd,
                                beforeaddParams => [$Data,$client, $memberID],
				afteraddFunction => \&postClearanceAdd,
				afteraddParams=> [$option,$Data,$Data->{'db'}],
				auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          'Clearance'
        ],
        auditEditParams => [
          $assocID,
          $Data,
          'Update',
          'Clearance'
        ],
				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_list">Return to $txt_Clr</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_list">Return to $txt_Clr</a>
				],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'CL_createnew',
				clrID => $id,
				sourceClubID => $sourceClubID,
				sourceAssocID => $sourceAssocID,
				sourceStateID => $sourceStateID,
				destinationClubID => $destinationClubID,
				destinationAssocID => $destinationAssocID,
				member_natnum => $member_natnum,
				memberID => $memberID,
				realmID => $Data->{'clientValues'}{'Realm'},
			},
		},
	);

	$FieldDefs{'Clearance'}{'fields'}{'dtPermitFrom'}{'compulsory'}=1 if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $params->{'d_intPermitType'} );
	$FieldDefs{'Clearance'}{'fields'}{'dtPermitTo'}{'compulsory'}=1 if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $params->{'d_intPermitType'} );

	$FieldDefs{'Clearance'}{'fields'}{'intPermitType'}{'compulsory'}=0;
	$FieldDefs{'Clearance'}{'fields'}{'dtPermitFrom'}{'compulsory'}=0;
	$FieldDefs{'Clearance'}{'fields'}{'dtPermitTo'}{'compulsory'}=0;
	if ($Data->{'SystemConfig'}{'clrAllowPermits'})	{
		$FieldDefs{'Clearance'}{'fields'}{'dtPermitFrom'}{'compulsory'}=1 if ($params->{'d_intPermitType'} );
		$FieldDefs{'Clearance'}{'fields'}{'dtPermitTo'}{'compulsory'}=1 if ($params->{'d_intPermitType'} );
		$FieldDefs{'Clearance'}{'fields'}{'intPermitType'}{'compulsory'}=1 if (! $intPermitType and ! $params->{'subbut2'} and $params->{'HF_subbutact'} );
	}

	($resultHTML, undef )=handleHTMLForm($FieldDefs{'Clearance'}, undef, $option, '',$db);
	$resultHTML .= Member::TribunalHistory($Data, $memberID, 0);

	#warn("TCTC");
	#use Data::Dumper;
	#print STDERR Dumper($FieldDefs{'Clearance'});

	if($option eq 'display')	{
		#$resultHTML .=allowedAction($Data, 'txn_e') ?qq[ <a href="$target?a=M_TXN_EDIT&amp;tID=$dref->{'intTransactionID'}&amp;client=$client">Edit Details</a> ] : '';
		#$resultHTML .=allowedAction($Data, 'txn_e') ?qq[ <a href="$target?a=M_TXN_EDIT&amp;tID=$dref->{'intTransactionID'}&amp;client=$client">Edit Details NOTE: WRONG URL</a> ] : '';
	}

  
  $resultHTML=qq[
			<div>This member does not have any Transaction information to display.</div>
		] if !ref $dref;
  

  my $validate_permit_type = $Data->{'SystemConfig'}{clrJSValidatePermitType};
  my $validate_permit_length = $Data->{'SystemConfig'}{'clrJSValidatePermitLength'};
  
  $resultHTML=qq[
				<div>
					$resultHTML
                    $validate_permit_type
                    $validate_permit_length
				</div>
		];
  my $heading=qq[];
  return ($resultHTML,$heading);

}

sub preClearanceAdd	{

    ### PURPOSE: Check whether the current member is in a pending clearance, or already in the club.
    
    my($params, $Data, $client, $memberID)=@_;
    my $db = $Data->{'db'};
    my $hasAgent= $params->{'d_intHasAgent'} || 0;
    my $permitType = $params->{'d_intPermitType'} || 0;
    
    
    
    if ($hasAgent and 
        (! $params->{'d_strAgentFirstname'} or ! $params->{'d_strAgentSurname'} or ! $params->{'d_strAgencyEmail'})
    )  {
        my $error = qq[ <div class="warningmsg">You need to fill in Agent fields Firstname, Surname and Email.</div> ];
        return (0,$error);
    }
	if ($Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC and $Data->{'SystemConfig'}{'clrNoMoreAdds'} and !$permitType)	{
		if ($Data->{'SystemConfig'}{'clrAllowAddAssocIDs'} !~ /\|$Data->{'clientValues'}{'assocID'}\|/)	{
			### Don't do this if the assoc ID is in the system config table
			my $error = qq[ <div class="warningmsg">Clearances are unable to be added.  Please contact the $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} administrator with any queries.</div> ];
            return (0,$error);
		}
	}
	   if(( $params->{'d_dtPermitFrom'}  or $params->{'d_dtPermitTo'} or $permitType>0) and  $params->{'subbut2'}) {
  my $error = qq[ <div class="warningmsg">You have entered permit Dates and selected a clearance. Please choose between a permit and a clearance.</div> ];
            return (0,$error);

	}
    print STDERR "CLEARANCE: $Data->{'clientValues'}{'authLevel'} | $Data->{'clientValues'}{'assocID'} | PT $permitType\n";
    
    
    if ($Data->{'SystemConfig'}{'AssocConfig'}{'clrAllowMultiplePermits'} and $permitType)	{
        return (1, '');
    }
   
    if ($Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB && $permitType && $Data->{SystemConfig}{clrInterchangeAgreements} && ($params->{sourceAssocID} != $params->{destinationAssocID})) {
        if (!associations_interchange_agreement($db, $permitType, $params->{sourceAssocID}, $params->{destinationAssocID})) {
            my $error =  qq[<div class="warningmsg">No agreement for permits exist between these $Data->{LevelNames}{$Defs::LEVEL_ASSOC . '_P'}.<br />
                            Please contact your League Administrator for more information on this.
                           </div>];
            return (0, $error);
        }
    }
    

    if ($Data->{'SystemConfig'}{'clrCheckRunningPermits'})	{
        my $permitCheck_st = qq[
			SELECT
				C1.strName as DestinationClubName, 
				C2.strName as SourceClubName, 
				A1.strName  as DestinationAssocName, 
				A1.intAssocID as DestinationAssocID, 
				A2.strName as SourceAssocName, 
				A2.intAssocID as SourceAssocID, 
				C1.intClubID as DestinationClubID,
				C2.intClubID as SourceClubID,
				DATE_FORMAT(dtPermitFrom,'%d/%m/%Y') AS PermitFrom, 
				DATE_FORMAT(dtPermitTo,'%d/%m/%Y') AS PermitTo, 
				A1.strEmail as DestinationAssocEmail, 
				A1.strPhone as DestinationAssocPh, 
				A1.strContact as DestinationAssocContact,  
				A2.strEmail as SourceAssocEmail, 
				A2.strPhone as SourceAssocPh, 
				A2.strContact as SourceAssocContact
			FROM
				tblClearance as C
				LEFT JOIN tblClub as C1 ON (C1.intClubID = C.intDestinationClubID)
				LEFT JOIN tblClub as C2 ON (C2.intClubID = C.intSourceClubID)
				LEFT JOIN tblAssoc as A1 ON (A1.intAssocID= C.intDestinationAssocID)
				LEFT JOIN tblAssoc as A2 ON (A2.intAssocID= C.intSourceAssocID)
			WHERE 
				intMemberID = $memberID
				AND intClearanceStatus=1
				AND CONCAT(DATE_FORMAT(dtPermitTo,'%Y-%m-%d'), ' 23:59:59') >= SYSDATE()
				AND intPermitType >0
		];
        my $query = $db->prepare($permitCheck_st) or query_error($permitCheck_st);
        $query->execute or query_error($permitCheck_st);
        my $error='';
        
        my $runningCount=0;
        while (my $dref = $query->fetchrow_hashref())	{
            #if (check_if_duplicate_permit($permitType, $params->{'sourceClubID'}, $params->{'destinationClubID'}, $dref)) {
            #    $error = qq[<div class="warningmsg">There is already an existing $permitType for the clubs and dates being requested.</div>];
            #    return (0, $error);
            #}

            $runningCount++;
            # If the player is permitted to an association that allows multiple permits - that's OK
            my $multiple_permit_assoc = association_allows_multiple_permits($db, $dref->{'DestinationAssocID'});
            if ($multiple_permit_assoc) {
                next;
            }
             my $source_contact_name="";
            my $source_contact_email ="";
            my $destination_contact_name ="";
            my $destination_contact_email="";
            


	 if($dref->{SourceAssocID} >0){
                my $source_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getclearances=>1)||[];
                my $source_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getprimary=>1)||[];
                if(scalar(@$source_contactObj)>0){
                        $source_contact_name =qq[@$source_contactObj[0]->{strContactFirstname} @$source_contactObj[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$source_contactObjP)>0){
                        $source_contact_name =qq[@$source_contactObjP[0]->{strContactFirstname} @$source_contactObjP[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObjP[0]->{strContactEmail};
                }
        }
        if($dref->{DestinationAssocID} >0){
                my  $destination_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getclearances=>1) ;
                my  $destination_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getprimary=>1) ;
                if(scalar(@$destination_contactObj)>0){
                        $destination_contact_name =qq[@$destination_contactObj[0]->{strContactFirstname} @$destination_contactObj[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$destination_contactObjP)>0){
                        $destination_contact_name =qq[@$destination_contactObjP[0]->{strContactFirstname} @$destination_contactObjP[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObjP[0]->{strContactEmail};
                }
        }


            $dref->{SourceAssocEmail} = $source_contact_email;
            $dref->{SourceAssocContact} = $source_contact_name;

            $dref->{DestinationAssocEmail} = $destination_contact_email;
            $dref->{DestinationAssocContact} = $destination_contact_name; 
            $error .= qq[ 
                	<div class="warningmsg">The selected member is already involved in a current Permit.  Unable to continue until the below transaction is finalised.</div>
				<p>
					<b>Date Permit From:</b> $dref->{PermitFrom}<br>
					<b>Date Permit To:</b> $dref->{PermitTo}<br>
					<b>Permitted From:</b> $dref->{SourceAssocName} ($dref->{SourceClubName})<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{SourceAssocContact}<br>
					Phone: $dref->{SourceAssocPh}&nbsp;&nbsp;Email: $dref->{SourceAssocEmail}<br>
					<b>Permit To:</b> $dref->{DestinationAssocName} ($dref->{DestinationClubName})<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{DestinationAssocContact}<br>
					Phone: $dref->{DestinationAssocPh}&nbsp;&nbsp;Email: $dref->{DestinationAssocEmail}<br>
				</p>
			];
        }
				print STDERR "CLR:$runningCount | $Data->{'SystemConfig'}{'clrCheckRunningPermits'}\n";
				if ($runningCount and $Data->{'SystemConfig'}{'clrCheckRunningPermits'}> 1)	{
					$error = '';
					if ($runningCount > $Data->{'SystemConfig'}{'clrCheckRunningPermits'})	{
						$error = qq[ <div class="warningmsg">Permit is unable to be added.  Maximum number of current Permits exist ($Data->{'SystemConfig'}{'clrCheckRunningPermits'}) for this Player.</div> ];
					}
				}
        return (0,$error) if $error;
	}	
    
    
	if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $permitType and $permitType == 1)	{
        #return (1,'');
	}
    
     
	$memberID ||= 0;
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;
	
	my $st = qq[
			SELECT
				C.intClearanceID,
				C1.strName as DestinationClubName, 
				C2.strName as SourceClubName, 
				A1.strName  as DestinationAssocName, 
				A1.intAssocID as DestinationAssocID, 
				A2.strName as SourceAssocName, 
				A2.intAssocID as SourceAssocID, 
				C1.intClubID as DestinationClubID,
				A2.intAssocID as SourceAssocID, 
                                C2.intClubID as SourceClubID,
				DATE_FORMAT(dtApplied,'%d/%m/%Y') AS AppliedDate, 
				A1.strEmail as DestinationAssocEmail, 
				A1.strPhone as DestinationAssocPh, 
				A1.strContact as DestinationAssocContact,  
				A2.strEmail as SourceAssocEmail, 
				A2.strPhone as SourceAssocPh, A2.strContact as SourceAssocContact
			FROM
				tblClearance as C
				LEFT JOIN tblClub as C1 ON (C1.intClubID = C.intDestinationClubID)
				LEFT JOIN tblClub as C2 ON (C2.intClubID = C.intSourceClubID)
				LEFT JOIN tblAssoc as A1 ON (A1.intAssocID= C.intDestinationAssocID)
				LEFT JOIN tblAssoc as A2 ON (A2.intAssocID= C.intSourceAssocID)
		WHERE intMemberID = $memberID
			AND  intClearanceStatus = $Defs::CLR_STATUS_PENDING
			AND intCreatedFrom =0
	];
	my $query = $db->prepare($st) or query_error($st);
        $query->execute or query_error($st);

	#$st = qq[
	#	SELECT intMemberClubID
	#	FROM tblMember_Clubs
	#	WHERE intMemberID = $memberID
	#		AND intClubID = $destinationClubID
	#		AND intStatus = $Defs::RECSTATUS_ACTIVE
	#		AND intPermit = 0
	#];
	#$query = $db->prepare($st) or query_error($st);
        #$query->execute or query_error($st);
        #my ($intExistingMemberClubID) = $query->fetchrow_array();	

	my $error_text = '';
	my $existingClearance=0;
     
     while (my $dref = $query->fetchrow_hashref())	{
         my $multiple_permit_assoc = association_allows_multiple_permits($db, $dref->{'DestinationAssocID'});
         if ($multiple_permit_assoc) {
             next;
         }
        my $source_contact_name="";
        my $source_contact_email ="";
        my $destination_contact_name ="";
        my $destination_contact_email="";
        if($dref->{SourceAssocID} >0){
                my $source_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getclearances=>1)||[];
                my $source_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{SourceAssocID}  , clubid=>$dref->{SourceClubID} , getprimary=>1)||[];
		if(scalar(@$source_contactObj)>0){
               		$source_contact_name =qq[@$source_contactObj[0]->{strContactFirstname} @$source_contactObj[0]->{strContactSurname}];
                	$source_contact_email = @$source_contactObj[0]->{strContactEmail};
        	}
		elsif(scalar(@$source_contactObjP)>0){
               		$source_contact_name =qq[@$source_contactObjP[0]->{strContactFirstname} @$source_contactObjP[0]->{strContactSurname}];
                	$source_contact_email = @$source_contactObjP[0]->{strContactEmail};
        	}	
	}
        if($dref->{DestinationAssocID} >0){ 
                my  $destination_contactObj = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getclearances=>1) ;
                my  $destination_contactObjP = ContactsObj->getList(dbh=>$db,associd =>$dref->{DestinationAssocID}  , clubid=>$dref->{DestinationClubID} , getprimary=>1) ;
		if(scalar(@$destination_contactObj)>0){
			$destination_contact_name =qq[@$destination_contactObj[0]->{strContactFirstname} @$destination_contactObj[0]->{strContactSurname}];
                	$destination_contact_email = @$destination_contactObj[0]->{strContactEmail};
        	}
		elsif(scalar(@$destination_contactObjP)>0){
			$destination_contact_name =qq[@$destination_contactObjP[0]->{strContactFirstname} @$destination_contactObjP[0]->{strContactSurname}];
                	$destination_contact_email = @$destination_contactObjP[0]->{strContactEmail};
        	}
	}
        $dref->{SourceAssocEmail} = $source_contact_email;
        $dref->{SourceAssocContact} = $source_contact_name;
        $dref->{DestinationAssocEmail} = $destination_contact_email;
        $dref->{DestinationAssocContact} = $destination_contact_name; 
         $existingClearance++;
         $error_text .= qq[
                	<div class="warningmsg">The selected member is already involved in a pending clearance.  Unable to continue until the below transaction is finalised.</div>
				<p>
					<b>Date Requested:</b> $dref->{AppliedDate}<br>
					<b>Requested From:</b> $dref->{SourceAssocName} ($dref->{SourceClubName})<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{SourceAssocContact}<br>
					Phone: $dref->{SourceAssocPh}&nbsp;&nbsp;Email: $dref->{SourceAssocEmail}<br>
					<b>Request To:</b> $dref->{DestinationAssocName} ($dref->{DestinationClubName})<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Contact: $dref->{DestinationAssocContact}<br>
					Phone: $dref->{DestinationAssocPh}&nbsp;&nbsp;Email: $dref->{DestinationAssocEmail}<br>
				</p>
        	];
	}

#	$error_text .= qq[
#                <div class="warningmsg">The selected member is already involved in the destination club</div>
#        ] if $intExistingMemberClubID;
        #return (0,$error_text) if $intExistingClearanceID or $intExistingMemberClubID;
        return (0,$error_text) if $existingClearance;
        return (1,'');

}


sub postClearanceAdd	{

### PURPOSE: This function build's up the starting points between the two clubs then calls getMeetingPoint() to do the grunt work in finding the top node, if its not the association that both clubs belong to.


	my($id,$params,$action,$Data,$db)=@_;
  	return undef if !$db or ! $id;
	my $resultHTML = '';
	if (1==2 and $params->{'sourceAssocID'} == $params->{'destinationAssocID'})	{

	}
	else	{
	
		my $st_assoc_nodes = qq[
			SELECT AN.intAssocID, AN.intNodeID , N.intTypeID, N.intStatusID
			FROM tblAssoc_Node as AN INNER JOIN tblNode as N ON (N.intNodeID = AN.intNodeID)
			WHERE AN.intAssocID IN ($params->{'sourceAssocID'}, $params->{'destinationAssocID'})
				AND AN.intPrimary=1 
		];
    		my $query = $db->prepare($st_assoc_nodes) or query_error($st_assoc_nodes);
    		$query->execute or query_error($st_assoc_nodes);

		my @sourceNodes = ();	
		my @destinationNodes = ();
		my $sourceAssocNodeID=0;
		my $destinationAssocNodeID=0;
		my $sourceTypeID = 0;
		my $destinationTypeID =0;
		my $destinationStatusID =0;
		my $sourceStatusID =0;
	
		my $destinationClubPathID = 0;
		while (my $dref = $query->fetchrow_hashref())	{
			if ($dref->{intAssocID} == $params->{sourceAssocID})	{
				$sourceAssocNodeID = $dref->{intNodeID};
				$sourceTypeID = $dref->{intTypeID};
				$sourceStatusID = $dref->{intStatusID};
			}
			if ($dref->{intAssocID} == $params->{destinationAssocID})	{
				$destinationAssocNodeID = $dref->{intNodeID};
				$destinationTypeID = $dref->{intTypeID};
				$destinationStatusID = $dref->{intStatusID};
			}
		}
		
		
		my $found=0;
		if ($sourceAssocNodeID == $destinationAssocNodeID and $sourceStatusID and $destinationStatusID)	{
			$found=1;
				### DO INSERT AT THIS LEVEL !
		}
		elsif ($params->{'sourceAssocID'} == $params->{'destinationAssocID'})	{
			$found=1;
		}
		else	{
			$found = getMeetingPoint($db, $sourceAssocNodeID, $destinationAssocNodeID, \@sourceNodes, \@destinationNodes, 0);
		}
		if ($params->{'sourceAssocID'} != $params->{'destinationAssocID'})	{
			push @sourceNodes, [$sourceAssocNodeID, $sourceTypeID, $Defs::NODE_LEVEL_CLEARANCE];
			push @destinationNodes, [$destinationAssocNodeID, $destinationTypeID, $Defs::NODE_LEVEL_CLEARANCE];
		}
	
		push @sourceNodes, [$params->{sourceAssocID}, $Defs::LEVEL_ASSOC, $Defs::ASSOC_LEVEL_CLEARANCE];
		push @destinationNodes, [$params->{destinationAssocID}, $Defs::LEVEL_ASSOC, $Defs::ASSOC_LEVEL_CLEARANCE];
		#push @destinationNodes, [$destinationAssocNodeID, $Defs::LEVEL_ASSOC, $Defs::ASSOC_LEVEL_CLEARANCE];
		
		if ($found)	{
			my $insert_st = qq[
				INSERT INTO tblClearancePath
				(intClearanceID, intTypeID, intTableType, intID, intOrder, intDirection, intClearanceStatus)
				VALUES ($id, ?, ?, ?, ?, ?, $Defs::CLR_STATUS_PENDING)
			];
	    		my $qry_insert = $db->prepare($insert_st) or query_error($insert_st);
			my $count=1;
		
			$qry_insert->execute($Defs::LEVEL_CLUB, $Defs::CLUB_LEVEL_CLEARANCE, $params->{'sourceClubID'}, $count, $Defs::DIRECTION_FROM_SOURCE) if $params->{'sourceClubID'};
			my $firstPathID = $qry_insert->{mysql_insertid} || 0;
			
			$count++ if $params->{'sourceClubID'};

			for my $node (reverse @sourceNodes)	{
				#my $type = $count == 2 ? $Defs::ASSOC_LEVEL_CLEARANCE : $Defs::NODE_LEVEL_CLEARANCE;
				$qry_insert->execute($node->[1], $node->[2], $node->[0], $count, $Defs::DIRECTION_FROM_SOURCE);
				$count++;
#				print STDERR "SOURCE: $node->[0]|$node->[1]|$node->[2]\n";
			}
			my $skip_first = 0;
			for my $node (@destinationNodes)	{
				$skip_first++;
				next if $skip_first == 1; ## SKIP FIRST Destination NODE (ie: Its the top one).  IT WAS HANDLED IN SOURCE.
				$qry_insert->execute($node->[1], $node->[2], $node->[0], $count, $Defs::DIRECTION_TO_DESTINATION);
				$count++;
#				print STDERR "DESTINATION: $node->[0]|$node->[1]|$node->[2]\n";
			}
			$qry_insert->execute($Defs::LEVEL_CLUB, $Defs::CLUB_LEVEL_CLEARANCE, $params->{'destinationClubID'}, $count, $Defs::DIRECTION_TO_DESTINATION) if $params->{'destinationClubID'};
			$destinationClubPathID = $qry_insert->{mysql_insertid} || 0;

            if ($Data->{'SystemConfig'}{'checkStateLeaguePermits'}) {
                my ($CCemails, $msg)= CCAssocPermits($Data, $id);
                $Data->{'clrCCEmails'} = $CCemails || '';
                $Data->{'clrCCmsg'}= $msg || '';
            }
			my $st = qq[
				UPDATE tblClearance
				SET intCurrentPathID = 0
				WHERE intClearanceID = $id
			];
				#SET intCurrentPathID = $firstPathID
			$db->do($st);
			my $permitType=0;
			if ($Data->{'SystemConfig'}{'clrAllowPermits'})	{
				$st = qq[
					SELECT 
						intPermitType
					FROM
						tblClearance
					WHERE 
						intClearanceID = $id
				];
    				$query = $db->prepare($st) or query_error($st);
    				$query->execute or query_error($st);
				$permitType = $query->fetchrow_array() || 0;
			}
            checkPrimaryApprover($db, $id);
			if ($id and $Data->{'SystemConfig'}{'clrAllowPermits'} and $permitType and $permitType == 1)	{
				clearancePermitMatchDay($Data, $id, $destinationClubPathID);
			}
			else	{	
				checkAutoConfirms($Data, $id,0);
			}
			$st = qq[
		        SELECT 
				intClearancePathID, 
				intClearanceStatus
		        FROM 
				tblClearancePath
	    		WHERE 
				intClearanceID = $id
        		ORDER BY 
				intOrder DESC
        		LIMIT 1
    		];
    		my $query = $db->prepare($st) or query_error($st);
    		$query->execute or query_error($st);
    		my ($intFinalCPID, $intClearanceStatus) = $query->fetchrow_array();

    		if ($intClearanceStatus == $Defs::CLR_STATUS_APPROVED)  {
        		finaliseClearance($Data, $id);
			$resultHTML = memberLink($Data, $id);
    		}
		
		}
		else	{
			### 
		}
	}
	sendCLREmail($Data, $id, 'ADDED');
	return (0, $resultHTML);
}
sub checkPrimaryApprover    {

    my ($db, $clearanceID) = @_;

    $clearanceID ||=0;
    my $st = qq[
        SELECT 
            CP.intClearancePathID
        FROM 
            tblClearancePath as CP
            INNER JOIN tblClearance as C ON (
                C.intClearanceID=CP.intClearanceID
            )
            INNER JOIN tblClearanceSettings as CS ON (
                    CS.intCheckAssocID IN (C.intSourceAssocID, C.intDestinationAssocID,0)
                    AND CP.intTypeID = CS.intTypeID 
                    AND CP.intID = CS.intID 
		    AND (
                        CS.intClearanceType = C.intPermitType
                        OR
                        (C.intPermitType = 0 and CS.intClearanceType = -99)
						OR 
						(CS.intClearanceType = 0)
                    )
            )
        WHERE
            C.intClearanceID = $clearanceID
            AND intPrimaryApprover = 1
        ORDER BY CP.intTypeID DESC, intDirection
        LIMIT 1
    ];
    my $query = $db->prepare($st) or query_error($st);
    $query->execute or query_error($st);
    my $currentPathID = $query->fetchrow_array() || 0;

    return if ! $currentPathID;

    $st = qq[
        UPDATE
            tblClearancePath
        SET
            intOrder=0
        WHERE
            intClearanceID = $clearanceID
            AND intClearancePathID = $currentPathID
        LIMIT 1
    ];
    $db->do($st);
    $st = qq[
        UPDATE
            tblClearance
        SET
            intCurrentPathID = $currentPathID
        WHERE
            intClearanceID = $clearanceID
        LIMIT 1
    ];
    $db->do($st);
}

sub CCAssocPermits {

    my ($Data, $id) = @_;

	my $st = qq[
                SELECT C.*
                FROM tblClearance as C
                        INNER JOIN tblAssoc as A ON (
                                A.intAssocID = intDestinationAssocID
                AND A.intCCPermits = 1
                        )
                WHERE intClearanceID = $id
        ];
        my $query = $Data->{'db'}->prepare($st) or query_error($st);
        $query->execute or query_error($st);
        my $dref=$query->fetchrow_hashref();
        return ('','') if (! $dref->{intClearanceID});

    my $st_permits = qq[
        SELECT
            DISTINCT A.intAssocID, A.strEmail
        FROM
            tblMember_Associations as MA
			INNER JOIN tblMember_Clubs as MC ON (
            	MC.intMemberID = $dref->{'intMemberID'}
                AND (
                	(MC.intStatus IN (0,1)
                    AND MC.dtPermitEnd >= DATE_ADD(CURRENT_DATE(), INTERVAL -2 YEAR))
                    OR
                    (
											MC.intStatus = 1
											AND (MC.dtPermitEnd = '0000-00-00 00:00:00' or MC.dtPermitEnd IS NULL)
                    )
                )
                AND MA.intMemberID=MC.intMemberID
            )
            INNER JOIN tblAssoc_Clubs as AC ON (
                AC.intClubID=MC.intClubID
            )
            INNER JOIN tblAssoc as A ON (
                A.intAssocID = AC.intAssocID
                AND A.intCCPermits = 1
            )
        WHERE
            A.intRealmID= $Data->{'Realm'}
    ];

	my $qry_assocs = $Data->{'db'}->prepare($st_permits) or query_error($st_permits);
	$qry_assocs->execute or query_error($st_permits);
    my $count=0;
    my $emails = '';
	while (my $aref=$qry_assocs->fetchrow_hashref())    {
        $count++;
        $emails .= qq[;] if $emails;
        $emails .= $aref->{'strEmail'};
    }
    
    my $msg='';
    if ($count) {
        $st = qq[
            UPDATE tblClearance
            SET dtDue = '0000-00-00', dtReminder='0000-00-00'
            WHERE intClearanceID = $id
            LIMIT 1
        ];
        $Data->{'db'}->do($st);
        $msg=$Data->{'SystemConfig'}{'checkStateLeaguePermits_MSG'} || '';
    }

    return ($emails, $msg);
}

sub clearancePermitMatchDay	{

	my ($Data, $clearanceID, $finalPathID) = @_;

	my $st = qq[
		UPDATE
			tblClearance
		SET
			intCurrentPathID = $finalPathID,
			intClearanceStatus = $Defs::CLR_STATUS_APPROVED
		WHERE 
			intClearanceID = $clearanceID
			AND intPermitType=1
		LIMIT 1
	];
	$Data->{'db'}->do($st);

	$st = qq[
		UPDATE
			tblClearancePath as CP
			INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
		SET
			CP.strApprovedBy = 'MATCH DAY PERMIT',
			CP.intClearanceStatus = $Defs::CLR_STATUS_APPROVED
		WHERE 
			CP.intClearanceID = $clearanceID
			AND C.intPermitType=1
	];
	$Data->{'db'}->do($st);
}

sub getMeetingPoint	{

	### PURPOSE: If the meeting point isn't the assoc (ie: both clubs in same assoc), then this function works out how far up structure tree to go till the meeting node is found.

	my ($db, $sourceAssocNodeID, $destinationAssocNodeID, $sourceNodes, $destinationNodes, $count) = @_;

	$count++;
	my $found=0;
	my $st = qq[
		SELECT NL.intNodeLinksID, NL.intParentNodeID, NL.intChildNodeID, N.intTypeID, N.intStatusID
		FROM tblNodeLinks as NL INNER JOIN tblNode as N ON (NL.intParentNodeID = N.intNodeID)
		WHERE NL.intChildNodeID IN ($sourceAssocNodeID, $destinationAssocNodeID)
			AND NL.intPrimary = 1
	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
	my $sourceNodeTypeID = 0;
	my $destinationNodeTypeID = 0;
	my $sourceNodeStatus =0;
	my $destinationNodeStatus=0;
	while (my $dref = $query->fetchrow_hashref())	{
		if ($dref->{intChildNodeID} == $sourceAssocNodeID)	{
			$sourceAssocNodeID = $dref->{intParentNodeID} || 0;
			$sourceNodeTypeID = $dref->{intTypeID} || 0;
			$sourceNodeStatus = $dref->{intStatusID} || 0;
		}
		if ($dref->{intChildNodeID} == $destinationAssocNodeID)	{
			$destinationAssocNodeID = $dref->{intParentNodeID} || 0;
			$destinationNodeTypeID = $dref->{intTypeID} || 0;
			$destinationNodeStatus = $dref->{intStatusID} || 0;
		}
	}

	$found = 1 if ($sourceAssocNodeID == $destinationAssocNodeID);
	$found=0 if (! $sourceNodeStatus or ! $destinationNodeStatus);
#	print STDERR "NODE $found|$sourceAssocNodeID|$destinationAssocNodeID\n";
	if (! $found and $sourceAssocNodeID and $destinationAssocNodeID)	{
		$found = getMeetingPoint($db, $sourceAssocNodeID, $destinationAssocNodeID, $sourceNodes, $destinationNodes, $count);
	}
	push @{$sourceNodes}, [$sourceAssocNodeID, $sourceNodeTypeID, $Defs::NODE_LEVEL_CLEARANCE];
	push @{$destinationNodes}, [$destinationAssocNodeID, $destinationNodeTypeID, $Defs::NODE_LEVEL_CLEARANCE];
	return $found;
}
sub check_valid_date    {
        my($date)=@_;
        my($d,$m,$y)=split /\//,$date;
        use Date::Calc qw(check_date);
        return check_date($y,$m,$d);
}
sub _fix_date  {
  my($date)=@_;
  return '' if !$date;
  my($dd,$mm,$yyyy)=$date=~m:(\d+)/(\d+)/(\d+):;
  if(!$dd or !$mm or !$yyyy)  { return '';}
  if($yyyy <100)  {$yyyy+=2000;}
  return "$yyyy-$mm-$dd";
}

sub clearanceAddManual	{

### PURPOSE: This function is used by the view members screen to add manual clearance history.  This clearance history doesn't have path approvals and has text descriptions for the source/destination nodes.

  my($Data) = @_;
	my $edit=1;
	my $q=new CGI;
  my %params=$q->Vars(); 
	my $id = $params{'clrID'};

	my $db=$Data->{'db'} || undef;
	my $memberID = $Data->{'clientValues'}{'memberID'} || -1;
	my $assocID= $Data->{'clientValues'}{'assocID'} || -1;
	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;

	my $destinationAssocID = $Data->{'clientValues'}{'assocID'} || 0;
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;

	my $realm = $params{'realmID'} || $Data->{'Realm'} || 0;

	$memberID = $memberID || $params{'memberID'} || 0;
	my $statement = qq[
		SELECT *, DATE_FORMAT(dtDOB,'%d/%m/%Y') AS DOB
		FROM tblMember 
		WHERE intMemberID = $memberID
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my $memref = $query->fetchrow_hashref();

	my $body = '';

  	my $resultHTML = '';

	$id ||= 0;
	$statement=qq[
		SELECT *, DATE_FORMAT(dtApplied,'%d/%m/%Y') AS dtApplied
		FROM tblClearance
		WHERE intClearanceID=$id
			AND intMemberID = $memberID
			AND intCreatedFrom = $Defs::CLR_TYPE_MANUAL
	];

	$query = $db->prepare($statement);
	my $RecordData={};
	$query->execute;
	my $dref=$query->fetchrow_hashref();
	my $clrupdate=qq[
		UPDATE tblClearance
			SET --VAL--
		WHERE intClearanceID=$id
			AND intMemberID = $memberID
			AND intCreatedFrom = $Defs::CLR_TYPE_MANUAL
	];
	my $intClearanceYear = $Data->{'SystemConfig'}{'clrClearanceYear'} || 0;
    my $clradd=qq[
        INSERT INTO tblClearance (intMemberID, intRealmID, --FIELDS--, dtApplied, intClearanceStatus, intCreatedFrom, intRecStatus, intClearanceYear)
        VALUES ($memberID, $realm, --VAL--,  SYSDATE(), $Defs::CLR_STATUS_APPROVED, 2, $Defs::RECSTATUS_ACTIVE, $intClearanceYear)
    ];

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        onlyTypes  => '-37',
    );
       
	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_UpdateCLR'} || $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || 'Update Clearance';

	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my %FieldDefs = (
		Clearance => {
			fields => {
				strSourceAssocName => {
					label => 'From Association',
					value => $dref->{strSourceAssocName},
					type=> 'text',
				},
				strSourceClubName => {
					label => 'From Club',
					value => $dref->{strSourceClubName},
					type=> 'text',
				},
				strDestinationAssocName => {
					label => 'To Association',
					value => $dref->{strDestinationAssocName},
					type=> 'text',
				},
				strDestinationClubName => {
					label => 'To Club',
					value => $dref->{strDestinationClubName},
					type=> 'text',
				},
				MemberName => {
					label => "Member Name",
					value => qq[$memref->{strFirstname} $memref->{strSurname}],
					type=> 'text',
					readonly => 1,
				},
				dtApplied => {
					label => 'Date',
					value => $dref->{'dtApplied'},
                     type  => 'text',
					readonly => '1',
				},	
				DOB => {
					label => 'Date of birth',
					value => $memref->{'DOB'},
                                        type  => 'text',
					readonly => '1',
				},	
				strSuburb => {
					label => 'Address Suburb',
					value => $memref->{'strSuburb'},
                                        type  => 'text',
					readonly => '1',
                		},
				strState=> {
					label => 'Address State',
					value => $memref->{'strState'},
                                        type  => 'text',
					readonly => '1',
                		},
				 intReasonForClearanceID => {
        				label => "Reason for $txt_Clr",
				        value => $dref->{intReasonForClearanceID},
				        type  => 'lookup',
        				options => $DefCodes->{-37},
        				order => $DefCodesOrder->{-37},
					firstoption => ['',"Choose Reason"],
	      			},
				strReasonForClearance=> {
					label => 'Additional Information',
					type => 'textarea',
					value => $dref->{'strReasonForClearance'},
					rows => 5,
                			cols=> 45,
				},
				strFilingNumber => {
					label => 'Reference Number',
					value => $dref->{'strFilingNumber'},
                                        type  => 'text',
				},	
				intPlayerActive=> {
					label => 'Clear as Player Active ?',
					value => $dref->{'intPlayerActive'},
                                        type  => 'checkbox',
					default=>1,
					
				},	
				intCoachActive=> {
					label => 'Clear as Coach Active ?',
					value => $dref->{'intCoachActive'},
                                        type  => 'checkbox',
				},	
				intMthOfficialActive=> {
					label => 'Clear as Match Official Active ?',
					value => $dref->{'intMthOfficialActive'},
                                        type  => 'checkbox',
				},	
				intMiscActive=> {
					label => 'Clear as Misc Active ?',
					value => $dref->{'intMiscActive'},
                                        type  => 'checkbox',
				},	
				intVolunteerActive=> {
					label => 'Clear as Volunteer Active ?',
					value => $dref->{'intVolunteerActive'},
                                        type  => 'checkbox',
				},	
				intClearancePriority=> {
                                        label => "$txt_Clr Priority",
                                        value => $dref->{'intClearancePriority'},
                                        type  => 'lookup',
                                        options => \%Defs::clearance_priority,
                                        firstoption => ['','Select Priority'],
                                },
				intClearAction=> {
                                        label => ($option eq 'add' and $Data->{'SystemConfig'}{'Clearances_ClearAction'}) ? "$txt_Clr Action" : '',
                                        type  => 'lookup',
                                        options => \%Defs::clearance_clearAction,
                                        firstoption => ['','Select Action'],
					SkipAddProcessing => 1,
					compulsory => ($option eq 'add' and $Data->{'SystemConfig'}{'Clearances_ClearAction'}) ? 1 : 0,
                                },
				
			},
			order => [qw(dtApplied MemberName DOB strSuburb strState strSourceAssocName strSourceClubName strDestinationAssocName strDestinationClubName intReasonForClearanceID strReasonForClearance strFilingNumber intClearancePriority intClearAction)],
			options => {
				labelsuffix => ':',
				hideblank => 1,
				target => $Data->{'target'},
				formname => 'clearance_form',
				submitlabel => $update_label,
				introtext => 'auto',
				buttonloc => 'bottom',
				updateSQL => $clrupdate,
				addSQL => $clradd,

				auditFunction=> \&auditLog,
        auditAddParams => [
          $Data,
          'Add',
          'Manual Clearance'
        ],
        auditEditParams => [
          $assocID,
          $Data,
          'Update',
          'Manual Clearance'
        ],

				afteraddFunction => \&postManualClrAction,
 				afteraddParams => [$Data,$Data->{'db'}],
				stopAfterAction => 1,
				updateOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_list">Return to $txt_Clr</a>
				],
				addOKtext => qq[
					<div class="OKmsg">Record updated successfully</div> <br>
					<a href="$Data->{'target'}?client=$client&amp;a=CL_list">Return to $txt_Clr</a>
				],
			},
			sections => [ ['main','Details'], ],
			carryfields =>  {
				client => $client,
				a=> 'CL_addmanual',
				clrID => $id,
				destinationClubID => $destinationClubID,
				destinationAssocID => $destinationAssocID,
				memberID => $memberID,
				realmID => $Data->{'clientValues'}{'Realm'},
			},
		},
	);
	($resultHTML, undef )=handleHTMLForm($FieldDefs{'Clearance'}, undef, $option, '',$db);

	$resultHTML=qq[
		<div>This member does not have any Transaction information to display.</div>
	] if !ref $dref;

	$resultHTML=qq[
			<div>
				$resultHTML
			</div>
	];
	my $heading=qq[];
	return ($resultHTML,$heading);
}

sub sendCLREmail	{

### PURPOSE: This function handles the emailing to all the levels of the current status of the clearance.  It contains the text body and subject of the email.

	my ($Data, $cID, $action) = @_;

	return if ($Data->{'SystemConfig'}{'clrNoEmails'});
	return if (($Data->{'SystemConfig'}{'clrEmails_addOnly'} and $action ne 'ADDED') and ($Data->{'SystemConfig'}{'clrEmails_Denial'} and $action ne 'DENIED') and ($Data->{'SystemConfig'}{'clrEmails_Reminder'} and $action !~ /REMINDER/));
	$cID ||= 0;
	my $db = $Data->{'db'};
	return if ! $cID;

	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my $st = qq[
		SELECT CONCAT(M.strFirstname, ' ', M.strSurname) as MemberName, C.*, IF(intDestinationClubID > 0, C1.strName, strDestinationClubName) as DestinationClubName, IF(intSourceClubID > 0 , C2.strName, strSourceClubName) as SourceClubName, IF(intDestinationAssocID > 0, A1.strName, strDestinationAssocName) as DestinationAssocName,IF(intSourceAssocID > 0, A2.strName, strSourceAssocName) as SourceAssocName, CP.intTableType, CP.intTypeID, CP.intID, A2.intAssocTypeID as SourceSubType, A1.intAssocTypeID as DestSubType, DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB,  DATE_FORMAT(C.dtPermitFrom,'%d/%m/%Y') AS dtPermitFrom,DATE_FORMAT(C.dtPermitTo,'%d/%m/%Y') AS dtPermitTo, DATE_FORMAT(C.dtApplied,'%d/%m/%Y') AS dtApplied, DC.strName as DenialCode, C.strReasonForClearance
		FROM tblClearance as C
			INNER JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
			INNER JOIN tblMember as M ON (M.intMemberID = C.intMemberID)
			LEFT JOIN tblClub as C1 ON (C1.intClubID = C.intDestinationClubID)
			LEFT JOIN tblClub as C2 ON (C2.intClubID = C.intSourceClubID)
			LEFT JOIN tblAssoc as A1 ON (A1.intAssocID= C.intDestinationAssocID)
			LEFT JOIN tblAssoc as A2 ON (A2.intAssocID= C.intSourceAssocID)
            LEFT JOIN tblDefCodes as DC ON (DC.intCodeID = CP.intDenialReasonID)
		WHERE C.intClearanceID = $cID
			AND CP.intClearancePathID = C.intCurrentPathID
		LIMIT 1
	];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);
	my $cref = $query->fetchrow_hashref();

	return if ($cref->{SourceSubType} and $cref->{DestSubType} and $cref->{SourceSubType} == $cref->{DestSubType} and $Data->{'SystemConfig'}{'clrNoEmails_sameSubType'});
	my $email_subject = '';
	###BUILD UP TEXT
	my $dtPermit='';
	if (!$Data->{'SystemConfig'}{'clrHide_dtPermitFrom'} and ! $Data->{'SystemConfig'}{'clrHide_dtPermitFrom'} and ($cref->{dtPermitFrom} and $cref->{dtPermitFrom} ne '00/00/0000') or ($cref->{dtPermitTo} and $cref->{dtPermitTo} ne '00/00/0000'))	{
		my $permitType = $cref->{intPermitType} ? qq[Permit Type: $Defs::clearancePermitType{$Data->{'Realm'}}{$cref->{intPermitType}}] : '';
		$dtPermit = qq[
$permitType
Date Permit From: $cref->{dtPermitFrom}
Date Permit To: $cref->{dtPermitTo}
];
	}
	my $additionalInformation='';
        if ($Data->{'SystemConfig'}{'clrEmailAdditionalInfo'} and $cref->{'strReasonForClearance'})     {
                $additionalInformation = qq[Additional Information: $cref->{'strReasonForClearance'}];
        }
	my $email_body = qq[
$txt_Clr Ref. No.: $cref->{intClearanceID}
Member name: $cref->{MemberName}
To Club: $cref->{DestinationClubName}
To Association: $cref->{DestinationAssocName}
Source (From) Club: $cref->{SourceClubName}
Source (From) Association: $cref->{SourceAssocName}
$additionalInformation

$dtPermit
];

	my ($whos_turn, undef, undef) = getNodeDetails($db, $cref->{intTableType}, $cref->{intTypeID}, $cref->{intID});
	my $emailOnlyCurrentLevel = 0;

	my $viewDetails = qq[To view details, please log into the system and click on the List $txt_Clr]. qq[s option];        
	$viewDetails = $Data->{'SystemConfig'}{'clrEmail_detailsLink'} if ($Data->{'SystemConfig'}{'clrEmail_detailsLink'});

	$emailOnlyCurrentLevel = 1 if ($Data->{'SystemConfig'}{'clr_EmailOnlyCurrentLevel'} and $cref->{intPermitType} != 1);
	if ($action eq 'ARLD_REMINDER')	{
		$email_body .= qq[9 days have now elapsed - this $txt_Clr should be acted upon immediately in accordance with Policy.  $viewDetails];
		$email_subject = qq[$txt_Clr Reminder - Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'AFL_REMINDER')	{
		$email_body .= qq[This reminder email regards $txt_Clr Ref. No.: $cref->{intClearanceID} - This clearance was applied for on $cref->{dtApplied} and requires your attention. $viewDetails];
		$email_subject = qq[$txt_Clr Reminder - Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'CANCELLED')	{
		$email_body .= qq[This $txt_Clr has now been cancelled.  $viewDetails];
		$email_subject = qq[$txt_Clr cancelled- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'DENIED')	{
	    $emailOnlyCurrentLevel = 0;
		if ($Data->{'Realm'} == 2)	{
			$email_body .= qq[This $txt_Clr has been denied at $whos_turn level.  Contact should be made with $whos_turn to resolve any issues.];
		}
		else	{
			$email_body .= qq[This $txt_Clr has been denied at $whos_turn level.  Contact should be made with $whos_turn to resolve any issues.  The $txt_Clr should NOT be requested again.];
		}
        $email_body .= qq[The reason given for the denial is: $cref->{DenialCode}] if ($cref->{DenialCode});
		$email_subject = qq[$txt_Clr DENIED- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'REOPEN')	{
	    $emailOnlyCurrentLevel = 0;
		$email_body .= qq[The above $txt_Clr has now been reopened. 

Current Level for Approval: $whos_turn

$viewDetails ];
		$email_subject = qq[$txt_Clr reopened- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'ADDED')	{
		$email_body .= qq[The above $txt_Clr has been added. 

Current Level for Approval: $whos_turn

$viewDetails ];
		$email_subject = qq[New request for $txt_Clr - Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];

		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 1)       { 
			$email_subject = qq[New request for MATCH DAY Permit- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 2)       { 
			$email_subject = qq[New request for LOCAL INTERCHANGE Permit- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 3)       { 
			$email_subject = qq[New request for TEMPORARY TRANSFER- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
		return if ($Data->{'SystemConfig'}{'clrEmail_turnOff_New'});
	}
	if ($action eq 'PATH_UPDATED')	{
		$email_body .= qq[The above $txt_Clr has been updated. 

Current Level for Approval: $whos_turn

$viewDetails
Be sure to check the $txt_Clr to see when its your turn to approve/deny it.];
		$email_subject = qq[$txt_Clr Updated- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
	}
	if ($action eq 'FINALISED')	{
		$email_body .= qq[The above $txt_Clr has been finalised.
$viewDetails
];
                $email_subject = qq[$txt_Clr finalised- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];

		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 1)       { 
			$email_body .= qq[The above Match Day Permit has been finalised. 
$viewDetails
];
			$email_subject = qq[MATCH DAY PERMIT finalised- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 2)       { 
			$email_body .= qq[The above Local Interchange Permit has been finalised. 
$viewDetails
];
			$email_subject = qq[LOCAL INTERCHANGE PERMIT finalised- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
		if ($Data->{'SystemConfig'}{'clrAllowPermits'} and $cref->{intPermitType} == 3)       { 
			$email_body .= qq[The above Temporary Transfer has been finalised. 
$viewDetails
];
			$email_subject = qq[TEMPORARY TRANSFER finalised- Ref. No.:$cref->{intClearanceID}- $cref->{MemberName} - DOB - $cref->{dtDOB}];
		}
	}

	my $st_path = qq[
		SELECT intClearancePathID, intTableType, intTypeID, intID
		FROM tblClearancePath
		WHERE intClearanceID = $cID
	];
    	my $qry_path = $db->prepare($st_path) or query_error($st_path);
    	$qry_path->execute or query_error($st_path);
	my $cc_list = '';
	while (my $dref = $qry_path->fetchrow_hashref())	{
		next if $emailOnlyCurrentLevel and $dref->{intClearancePathID} != $cref->{intCurrentPathID};
		my (undef, undef, $email) = getNodeDetails($db, $dref->{intTableType}, $dref->{intTypeID}, $dref->{intID});
        my $cs_emails = getServicesContactsEmail($Data, $dref->{intTypeID}, $dref->{intID}, $Defs::SC_CONTACTS_CLEARANCES);
        $email = $cs_emails if ($cs_emails);
		$email ||= '';
		if ($email)	{
			$cc_list .= qq[;] if ($cc_list);
			$cc_list .= $email;
		}
	}

	#if ($action eq 'AFL_REMINDER')	{
	#	$cc_list = "bruce\@sportingpulse.com";
	#}
    if ($Data->{'clrCCEmails'}) {
        $cc_list .= qq[;] if ($cc_list);
        $cc_list .= $Data->{'clrCCEmails'};
        $email_body = $email_body . $Data->{'clrCCmsg'};
    }
	
	sendEmail($cc_list, $email_body, $email_subject, $cID, $action);
	## SEND EMAIL
}
sub sendEmail   {

### PURPOSE: Used to send the clearance email.

        my ($email, $message_str, $subject, $cID, $action)=@_;
	my $boundary="====SportingPulse-r53q6w8sgydixlgfxzdkgkh====";
    #    my $contenttype=qq[multipart/mixed; boundary="$boundary"];
	my $contenttype=qq[text/plain; charset="us-ascii"; boundary="$boundary"];

        my $message=qq[

This is a multi-part message in MIME format...

--].$boundary.qq[
Content-Type: text/plain
Content-Disposition: inline
Content-Transfer-Encoding: 8bit\n\n];
#Content-Transfer-Encoding: binary\n\n];

$message='';

        my %mail = (
		To => "$email",
		From  => "$Defs::donotreply_email_name <$Defs::donotreply_email>",
		Subject => $subject,
		Message => $message,
		'Content-Type' => $contenttype,
		'Content-Transfer-Encoding' => "binary"
        );
        $mail{Message}.="$message_str\n\n------------------------------------------\n\n" if $message_str;
        $mail{Message}.="\n\n$Defs::sitename <$Defs::donotreply_email>",

        my $error=1;
        if($mail{To}) {
                if($Defs::global_mail_debug)  { $mail{To}=$Defs::global_mail_debug;}
                open MAILLOG, ">>$Defs::mail_log_file" or print STDERR "Cannot open MailLog $Defs::mail_log_file\n";
                if (sendmail %mail) {
                        print MAILLOG (scalar localtime()).":CLR:$cID $action $mail{To}:Sent OK.\n" ;
                        $error=0;
                }
                else {
                        print MAILLOG (scalar localtime())." CLR:$cID $mail{To}:Error sending mail: $Mail::Sendmail::error \n" ;
                }
                close MAILLOG;
        }
}

sub getDateDue	{

    	my ($Data, $sourceAssocID, $destinationAssocID) = @_;

    	return ('0000-00-00', '0000-00-00') if ! $Data->{'SystemConfig'}{'Clearance_DateDue'};

	    my $destinationStateID = 0;
	    my $sourceStateID = 0;

    	my $st = qq[
		SELECT 
			NL2.intParentNodeID as StateID, ANSource.intAssocID as AssocID
		FROM
			tblAssoc_Node as ANSource
			INNER JOIN tblNodeLinks as NL1 ON (NL1.intChildNodeID = ANSource.intNodeID 
				AND NL1.intPrimary=1)
			INNER JOIN tblNodeLinks as NL2 ON (NL2.intChildNodeID = NL1.intParentNodeID 
				AND NL2.intPrimary=1)
		WHERE 
			ANSource.intAssocID IN ($sourceAssocID, $destinationAssocID)
    	];
    	my $qry= $Data->{'db'}->prepare($st) or query_error($st);
    	$qry->execute or query_error($st);

	while (my $dref=$qry->fetchrow_hashref())	{
		$destinationStateID = $dref->{StateID} if $destinationAssocID == $dref->{AssocID};
		$sourceStateID = $dref->{StateID} if $sourceAssocID == $dref->{AssocID};
	}

	my $StateID = ($destinationStateID == $sourceStateID) ? $destinationStateID : -1;

	$st = qq[
		SELECT 
			dtDue, dtReminder
		FROM 
			tblClearanceDatesDue
		WHERE 
			dtApplied = CURRENT_DATE()
			AND intStateID IN ($StateID, -1)
			AND intRealmID = $Data->{'Realm'}
		ORDER BY intStateID DESC
		LIMIT 1
	];
    	$qry= $Data->{'db'}->prepare($st) or query_error($st);
    	$qry->execute or query_error($st);
	my ($dtDue, $dtReminder) =$qry->fetchrow_array(); 
	$dtDue ||= '0000-00-00';
	$dtReminder ||= '0000-00-00';

	return ($dtDue, $dtReminder);
}

sub postManualClrAction	{

	my($id,$params, $Data,$db)=@_;

	my $clrAction = $params->{'d_intClearAction'} || 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	my $memberID = $Data->{'clientValues'}{'memberID'} || 0;
	my $assocID = $Data->{'clientValues'}{'assocID'} || 0;

	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
	$memberID = 0 if ($memberID == $Defs::INVALID_ID);
	$assocID = 0 if ($assocID == $Defs::INVALID_ID);

	if ($params->{'d_intClearAction'} == 1 and $clubID and $memberID)	{
		## CLEAR MEMBER OUT !
		my $st = qq[
			INSERT INTO tblMember_ClubsClearedOut (
				intRealmID, 
				intAssocID, 
				intClubID, 
				intMemberID, 
				intClearanceID 
			)
                	VALUES (
				$Data->{'Realm'}, 			
				$assocID,
				$clubID,
				$memberID,
				$id
			)
		];
		$db->do($st);
                $st= qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_INACTIVE
                        WHERE
                                intMemberID = $memberID
                                AND intClubID = $clubID
                                AND intStatus = $Defs::RECSTATUS_ACTIVE
                ];
                $db->do($st);
	}
	if ($params->{'d_intClearAction'} == 2 and $clubID and $memberID)	{
		## CLEAR MEMBER IN !
		my $st = qq[
			DELETE FROM 
				tblMember_ClubsClearedOut
                	WHERE 
				intRealmID = $Data->{'Realm'}
                        	AND intAssocID = $assocID
                        	AND intClubID = $clubID
                        	AND intMemberID = $memberID
		];
		$db->do($st);

		$st= qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_ACTIVE
                        WHERE
                                intMemberID = $memberID
                                AND intClubID = $clubID
                                AND intStatus = $Defs::RECSTATUS_INACTIVE
                        ORDER BY intPermit
                        LIMIT 1
                ];
                $db->do($st);
	}

}

sub association_allows_multiple_permits {
    my ($db, $assoc_id) = @_;
    
 	my $st = qq[
                SELECT COUNT(*)
 		        FROM tblAssocConfig
 		        WHERE strOption = 'clrAllowMultiplePermits' 
                AND strValue = '1'
                AND intAssocID = $assoc_id
            ];
    
    my $qry= $db->prepare($st) or query_error($st);
    $qry->execute or query_error($st);
	
    my ($count) = $qry->fetchrow_array(); 
    
    return $count;
}


sub associations_interchange_agreement {
   my ($db, $type, $source_assoc, $destination_assoc) = @_;

   my $source_state = get_state_node_id($db, $source_assoc);
   my $destination_state = get_state_node_id($db, $destination_assoc);
   
   if ($destination_state != $source_state) {
       return 1;
   }

   my $st = qq[
               SELECT 
               COUNT(*)
               FROM tblInterchangeAgreements
               WHERE intAssocID1 = $destination_assoc
               AND intAssocID2 = $source_assoc
               AND intRecStatus = $Defs::RECSTATUS_ACTIVE
               AND intPermitTypeID = $type
           ];
   my $qry= $db->prepare($st);
   $qry->execute();
  
   my ($count) = $qry->fetchrow_array();
   
   return $count;
}

sub get_state_node_id {
    my ($db, $assoc_id) = @_;
    
    my $st = qq[
                SELECT intNodeID 
                FROM tblNode 
                INNER JOIN tblTempNodeStructure ON (tblNode.intNodeID = tblTempNodeStructure.int20_ID)
                WHERE intAssocID = ?
                AND intTypeID = 20 
                ];
    
    my $qry= $db->prepare($st) or query_error($st);
    $qry->execute($assoc_id) or query_error($st);
    
    my ($state_node_id) = $qry->fetchrow_array(); 
    
    return $state_node_id;
    
}

# sub check_if_duplicate_permit {
#     my ($permitType, $source_club_id, $destination_club_id, $existing_permit)  = @_;
#     if (($existing_permit->{''} != $source_club_id) || $existing_permit->{''}) {
#         return 0;
#     }    
    
#     # permit is for a club where a permit already exist, check dates and type
#     # if type == 1, may be covered by type 2.
    
#     return 1;
#}
1;
