#
# $Header: svn://svn/SWM/trunk/web/Clearances.pm 10771 2014-02-21 00:20:57Z cgao $
#

package Clearances;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(checkAutoConfirms handleClearances clearanceHistory sendCLREmail finaliseClearance);
@EXPORT_OK = qw(checkAutoConfirms handleClearances clearanceHistory sendCLREmail finaliseClearance);
use lib '.', '..', '../..', "../comp", '../RegoForm', "../dashboard", "../RegoFormBuilder",'../PaymentSplit', "../user";

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

	return (createClearance($action, $Data), $txt_RequestCLR) if $action eq 'CL_createnew';
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
                        intPersonID,
                        intDestinationClubID,
                        intSourceClubID
                FROM
                        tblClearance
                WHERE
                        intClearanceID = $clearanceID
        ]; 
        my $qry= $db->prepare($st);
        $qry->execute or query_error($st);
        my ($intPersonID, $intDestinationClubID, $intSourceClubID) = $qry->fetchrow_array();

	$st = qq[
		UPDATE tblClearance
		SET intClearanceStatus = $Defs::CLR_STATUS_CANCELLED
		WHERE intClearanceID = $clearanceID
			AND intDestinationClubID = $clubID
	];
	$db->do($st);
	$st = qq[
		UPDATE tblClearancePath as CP 
            INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
		SET CP.intClearanceStatus = $Defs::CLR_STATUS_CANCELLED
		WHERE CP.intClearanceID = $clearanceID
			AND CP.intClearanceStatus = $Defs::CLR_STATUS_PENDING
			AND CP.intDestinationClubID = $clubID
	];
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
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	return qq[$txt_Clr Unabled to be cancelled] if (! $clubID or ! $clearanceID);
  	my $client=setClient($Data->{'clientValues'}) || '';

    my $st = qq[
      SELECT
        C.intClearanceID, 
				C1.strLocalName as DestinationClubName, 
				C2.strLocalName as SourceClubName, 
				C.intDestinationClubID as DestinationClubID,
                C.intSourceClubID as SourceClubID,
				DATE_FORMAT(C.dtApplied,'%d/%m/%Y') AS AppliedDate 
      FROM
				tblClearance as ThisClr
        INNER JOIN tblClearance as C ON (C.intPersonID=ThisClr.intPersonID and C.intClearanceID <> ThisClr.intClearanceID)
        LEFT JOIN tblEntity as C1 ON (C1.intEntityID = C.intDestinationClubID and C1.intEntityLevel = $Defs::LEVEL_CLUB)
        LEFT JOIN tblEntity as C2 ON (C2.intEntityID = C.intSourceClubID and C2.intEntityLevel = $Defs::LEVEL_CLUB)
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
	
 if($dref->{SourceClubID} >0){
                my $source_contactObj = ContactsObj->getList(dbh=>$db,clubid=>$dref->{SourceClubID} , getclearances=>1)||[];
                my $source_contactObjP = ContactsObj->getList(dbh=>$db,clubid=>$dref->{SourceClubID} , getprimary=>1)||[];
                if(scalar(@$source_contactObj)>0){
                        $source_contact_name =qq[@$source_contactObj[0]->{strContactFirstname} @$source_contactObj[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$source_contactObjP)>0){
                        $source_contact_name =qq[@$source_contactObjP[0]->{strContactFirstname} @$source_contactObjP[0]->{strContactSurname}];
                        $source_contact_email = @$source_contactObjP[0]->{strContactEmail};
                }
        }
        if($dref->{DestinationClubID} >0){
                my  $destination_contactObj = ContactsObj->getList(dbh=>$db,clubid=>$dref->{DestinationClubID} , getclearances=>1) ;
                my  $destination_contactObjP = ContactsObj->getList(dbh=>$db, clubid=>$dref->{DestinationClubID} , getprimary=>1) ;
                if(scalar(@$destination_contactObj)>0){
                        $destination_contact_name =qq[@$destination_contactObj[0]->{strContactFirstname} @$destination_contactObj[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObj[0]->{strContactEmail};
                }
                elsif(scalar(@$destination_contactObjP)>0){
                        $destination_contact_name =qq[@$destination_contactObjP[0]->{strContactFirstname} @$destination_contactObjP[0]->{strContactSurname}];
                        $destination_contact_email = @$destination_contactObjP[0]->{strContactEmail};
                }
        }


		$dref->{SourceEmail} = $source_contact_email;
		$dref->{SourceContact} = $source_contact_name;

		$dref->{DestinationEmail} = $destination_contact_email;
		$dref->{DestinationContact} = $destination_contact_name;
		return qq[
			<div class="warningmsg">The selected member is already involved in a pending clearance.  Unable to continue until the below transaction is finalised.</div>
			<p>
					<b>Date Requested:</b> $dref->{AppliedDate}<br>
					<b>Requested From:</b> $dref->{SourceClubName} ($source_contact_name)<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Contact: $dref->{SourceContact}<br>
					Phone: $dref->{SourcePh}&nbsp;&nbsp;Email:  $dref->{SourceEmail}<br>
					<b>Request To:</b> $dref->{DestinationClubName}<br>
					$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Contact: $dref->{DestinationContact}<br>
					Phone: $dref->{DestinationPh}&nbsp;&nbsp;Email: $dref->{DestinationEmail}<br>
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

### PURPOSE: This function displays, for given intPersonID, the clearance history that they have. This is called from within the view member screen.

### At the bottom of this function is the ability to add a manual clearance history record.  For example, if they came from overseas.  These manual records don't have approval paths, but rather, are for historical purposes.

	my ($Data, $intPersonID) = @_;
	$intPersonID ||= 0;
	return '' if ! $intPersonID;

	my $db = $Data->{'db'};
	my $st = qq[
                SELECT 
                    C.*, 
                    SourceClub.strLocalName as SourceClubName, 
                    DestinationClub.strLocalName as DestinationClubName, 
                    DATE_FORMAT(dtApplied,'%d/%m/%Y') AS dtApplied, now() AS Today
                FROM tblClearance as C
			        LEFT JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                    LEFT JOIN tblEntity as SourceClub ON (SourceClub.intEntityID= C.intSourceClubID and SourceClub.intEntityLevel = $Defs::LEVEL_CLUB)
                    LEFT JOIN tblEntity as DestinationClub ON (DestinationClub.intEntityID = C.intDestinationClubID and DestinationClub.intEntityLevel = $Defs::LEVEL_CLUB)
                WHERE C.intPersonID = $intPersonID
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
      name => 'From Club',
      field => 'sourceDetails',
    },	
    {
      name => 'To Club',
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
    $dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
    $dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
		my $selectLink= "$Data->{'target'}?client=$client&amp;cID=$dref->{intClearanceID}&amp;a=CL_view";
		$selectLink= "$Data->{'target'}?client=$client&amp;clrID=$dref->{intClearanceID}&amp;a=CL_editmanual" if ($dref->{intCreatedFrom} == $Defs::CLR_TYPE_MANUAL and $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC);

## TC ## HACKED IN COS TOO MANY BAFF CHANGES ON DEVEL | CHANGE IS CHECKED IN ON DEVEL
    my $clearance_type = '';
     $clearance_type = $Defs::ClearanceTypes{$dref->{intCreatedFrom}};

		$dref->{'sourceDetails'} = qq[$dref->{SourceClubName}];
		$dref->{'destinationDetails'} = qq[$dref->{DestinationClubName}];
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
                SELECT DISTINCT 
                    C.*, 
                    DATE_FORMAT(C.dtApplied,"%d/%m/%Y") AS dtApplied, 
                    CONCAT(M.strLocalSurname, " ", M.strLocalFirstname) as MemberName, 
                    SourceClub.strLocalName as SourceClubName, 
                    DestinationClub.strLocalName as DestinationClubName, 
                    M.strState, 
                    DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB, 
                    strNationalNum,  
                    CP.strOtherDetails1
                FROM tblClearance as C
                    INNER JOIN tblPerson as M ON (M.intPersonID = C.intPersonID)
			        LEFT JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                    LEFT JOIN tblEntity as SourceClub ON (SourceClub.intEntityID = C.intSourceClubID and SourceClub.intEntityLevel = $Defs::LEVEL_CLUB)
                    LEFT JOIN tblEntity as DestinationClub ON (DestinationClub.intEntityID = C.intDestinationClubID and DestinationClub.intEntityLevel = $Defs::LEVEL_CLUB)
                WHERE C.intClearanceID= $cID
		GROUP BY C.intClearanceID
        ];
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $dref = $query->fetchrow_hashref() || undef;

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
        onlyTypes  => '-37',
    );

	my $readonly = 1;
	$readonly=0 if ($Data->{'clientValues'}{'clubID'} == $dref->{intDestinationClubID});	
	$dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
	$dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || 'Update Clearance';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $OtherDetails1= ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'}) ? '0' : '1';
	
	$update_label = '' if $readonly;

	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my %FieldDefs = (
		CLR => {
			fields => {
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
				DestinationClubName => {
					label => 'To Club',
					value => $dref->{'DestinationClubName'},
                    type  => 'text',
					readonly => '1',

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
			},
		order => [qw(ClearanceID dtApplied NatNum MemberName dtDOB strState SourceClubName DestinationClubName ClearanceStatus strOtherDetails1 ClearancePriority ClearanceReason intReasonForClearanceID strReason strReasonForClearance)],
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


	if ($dref->{intCreatedFrom} == 0)	{
		$resultHTML .= qq[<a href="$Data->{'target'}?client=$client&amp;cID=$cID&amp;a=CL_cancel">Cancel $txt_Clr</a>] if ($dref->{intDestinationClubID} == $Data->{'clientValues'}{'clubID'} and $dref->{intClearanceStatus} != $Defs::CLR_STATUS_CANCELLED and $dref->{intClearanceStatus} != $Defs::CLR_STATUS_APPROVED);
		$resultHTML .= qq[<a href="$Data->{'target'}?client=$client&amp;cID=$cID&amp;a=CL_reopen">Reopen Cancelled $txt_Clr</a>] if ($dref->{intDestinationClubID} == $Data->{'clientValues'}{'clubID'} and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_CANCELLED);
		$resultHTML .= showPathDetails($Data, $cID, $dref->{intClearanceStatus});
	}
	else	{
		$resultHTML .= qq[<br><div class="warningmsg">No path details can be shown as this clearance was created offline or is a Manual $txt_Clr History record</div>];
	}

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
			intPersonID,
			intDestinationClubID,
			intSourceClubID
                FROM 
			tblClearance
                WHERE 
			intClearanceID = $id
        ];
        my $qry= $db->prepare($st);
        $qry->execute or query_error($st);
        my ($intPersonID, $intToClubID, $intFromClubID) = $qry->fetchrow_array();
	## If in past then set as inactive
		### ROLL BACK MEMBER
		 my $st_updateSource = qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_ACTIVE
                        WHERE
                                intPersonID = $intPersonID
                                AND intClubID = $intFromClubID
                                AND intStatus = $Defs::RECSTATUS_INACTIVE
                        LIMIT 1
                ];
                $db->do($st_updateSource);
                my $st_clubsCleared = qq[
                        DELETE
                        FROM
                                tblMember_ClubsClearedOut
                        WHERE
                                intPersonID = $intPersonID
                                AND intClubID = $intFromClubID
                ];
                $db->do($st_clubsCleared);
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
		SELECT 
            CP.* , 
            DATE_FORMAT(CP.tTimeStamp,'%d/%m/%Y') AS TimeStamp, 
            CLF.strTitle, 
            C.intCurrentPathID
		FROM tblClearancePath as CP 
            INNER JOIN tblClearance as C ON (C.intClearanceID = CP.intClearanceID)
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
				<th>Denial Reason</th>
	] if (! $Data->{'SystemConfig'}{'clrHide_intDenialReasonID'});
	$body .= qq[
				<th>$Data->{'SystemConfig'}{'clrOtherDetails1_Label'}</th>
	] if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'});
	$body .= qq[
				<th>Additional Information</th>
				<th>Time Updated</th>
			</tr>
	];
	my $denied = 0;



#### 
 my $intID=0;         $intID = $Data->{'clientValues'}{'clubID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
        $intID = $Data->{'clientValues'}{'zoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ZONE);
        $intID = $Data->{'clientValues'}{'regionID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION);
        $intID = $Data->{'clientValues'}{'stateID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_STATE);         $intID = $Data->{'clientValues'}{'natID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_NATIONAL);
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
		my $timestamp = $dref->{intClearanceStatus} ? $dref->{TimeStamp} : '';
		my $level = $Defs::LevelNames{$dref->{intTypeID}};
				#<td><i>$level</i></td>
		$body .= qq[
			<tr>
				<td>$pathnode</td>
				<td>$status</td>
		];
		$body .= qq[
				<td>$dref->{strApprovedBy}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_strApprovedBy'});
		$body .= qq[
				<td>$DefCodes->{-38}{$dref->{intDenialReasonID}}</td>
	] if (! $Data->{'SystemConfig'}{'clrHide_intDenialReasonID'});
	$body .= qq[
				<td>$dref->{'strOtherDetails1'}</td>
	] if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'});
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

### PURPOSE: This function returns the Name, Email address for the passed values.  This is used by various functions such as emailing.

	my ($db, $intTableType, $intTypeID, $intID) = @_;

	$intTableType ||= 0;
	$intTypeID ||= 0;
	$intID ||= 0;

	return '' if ! $intTableType or ! $intTypeID or ! $intID;

	my $tablename = '';
	my $field = '';
	my $where = '';
	$tablename = 'tblEntity';
	$field = 'intEntityID';
#		$where = qq[ AND intStatusID =$Defs::NODE_SHOW ];

	my $st = qq[
		SELECT 
            strLocalName, 
            strEmail 
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
                SELECT DISTINCT 
                    C.*, 
                    CP.intClearanceStatus as PathStatus, 
                    CP.intClearancePathID, 
                    CONCAT(M.strLocalSurname, " ", M.strLocalFirstname) as MemberName, 
                    SourceClub.strLocalName as SourceClubName, 
                    DestinationClub.strLocalName as DestinationClubName, 
                    M.strState, 
                    DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB, 
                    CP.intID, 
                    CP.intTypeID, 
                    CP.intDenialReasonID, 
                    CP.intTableType, 
                    CP.strPathNotes, 
                    CP.strPathFilingNumber, 
                    CP.strApprovedBy, 
                    CP.strOtherDetails1
                FROM tblClearance as C
                        INNER JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
                        INNER JOIN tblPerson as M ON (M.intPersonID = C.intPersonID)
                        LEFT JOIN tblEntity as SourceClub ON (SourceClub.intEntityID = C.intSourceClubID and SourceClub.intEntityLevel = $Defs::LEVEL_CLUB)
                        LEFT JOIN tblEntity as DestinationClub ON (DestinationClub.intEntityID = C.intDestinationClubID and DestinationClub.intEntityLevel = $Defs::LEVEL_CLUB)
                WHERE C.intClearanceID= $cID
			$cpID_WHERE
        ];
	#BAFF HERE
    	my $query = $db->prepare($st) or query_error($st);
    	$query->execute or query_error($st);

	my $dref = $query->fetchrow_hashref() || undef;

	 my $intID=0;
        $intID = $Data->{'clientValues'}{'clubID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_CLUB);
        $intID = $Data->{'clientValues'}{'zoneID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_ZONE);
        $intID = $Data->{'clientValues'}{'regionID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_REGION);
        $intID = $Data->{'clientValues'}{'stateID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_STATE);
        $intID = $Data->{'clientValues'}{'natID'} if ($Data->{'clientValues'}{'currentLevel'} == $Defs::LEVEL_NATIONAL);
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
    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        onlyTypes  => '-38',
    );
       
    $dref->{SourceClubName} ||= $dref->{strSourceClubName} || '';
    $dref->{DestinationClubName} ||= $dref->{strDestinationClubName} || '';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $strApprovedBy=($Data->{'SystemConfig'}{'clrHide_strApprovedBy'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';
	my $intDenialReasonID= ($Data->{'SystemConfig'}{'clrHide_intDenialReasonID'}==1) ? '1' : '0';
	my $OtherDetails1= ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'}) ? '0' : '1';
	
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
                                DestinationClubName => {
                                        label => 'To Club',
                                        value => $dref->{'DestinationClubName'},
                                        type  => 'text',
					readonly => '1',
                                },
                                Reason=> {
                                        label => "Reason for $txt_Clr",
                                        value => $dref->{'strReason'},
                                        type  => 'text',
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
		},
		order => [qw(intClearanceID MemberName dtDOB strState SourceClubName DestinationClubName Reason intClearanceStatus strApprovedBy intDenialReasonID strOtherDetails1 strPathNotes strPathFilingNumber)],
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
	$FieldDefs{'CLR'}{'fields'}{'strOtherDetails1'}{'compulsory'}=1 if ($Data->{'SystemConfig'}{'clrOtherDetails1_Label'} );
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

	if ($dref->{intClearanceID} and $dref->{intPersonID} and $dref->{intClearanceStatus} == $Defs::CLR_STATUS_APPROVED)	{
 		my %tempClientValues = %{$Data->{clientValues}};
        $tempClientValues{memberID} = $dref->{intPersonID};
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
	
	my $st = qq[
		SELECT 
            CP.intClearancePathID, 
            CP.intID, 
            CP.intTypeID, 
            M.dtDOB, 
            N.intStatusID, 
            N.intNodeID, 
            intDirection
		FROM tblClearance as C 
			INNER JOIN tblPerson as M ON (M.intPersonID = C.intPersonID)
			INNER JOIN tblClearancePath as CP ON (C.intClearanceID = CP.intClearanceID)
			LEFT JOIN tblNode as N ON (N.intNodeID = CP.intID AND CP.intTableType = $Defs::NODE_LEVEL_CLEARANCE)
		WHERE C.intClearanceID = $cID
			AND C.intClearanceStatus = 0
			AND CP.intClearanceStatus IN (0,2)
		ORDER BY CP.intOrder
	];
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my $st_path_update = qq[
		UPDATE tblClearancePath
		SET strApprovedBy = 'Auto Approved', intClearanceStatus = ?
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
		my $intAutoApproval = getClearanceSettings($Data, $dref->{intID}, $dref->{intTypeID}, $dref->{dtDOB}, $dref->{intDirection});
		if ($dref->{intNodeID} and $dref->{intStatusID} eq '0' and $intAutoApproval == 0)	{
			$intAutoApproval = $Defs::CLR_AUTO_APPROVE;
		}
		if ($intAutoApproval == $Defs::CLR_AUTO_APPROVE)	{
			my $clearancePathStatus = $intAutoApproval;
			$qry_path_update->execute($clearancePathStatus, $dref->{intClearancePathID}) or query_error($st_path_update);
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

	my($Data, $intID, $intTypeID, $dtDOB, $ruleDirection)=@_;

	my $db = $Data->{'db'};
	$ruleDirection ||= $Defs::CLR_BOTH;
	
	my $st = qq[
		SELECT 
            intClearanceSettingID, 
            intAutoApproval , 
            intRuleDirection
		FROM tblClearanceSettings
		WHERE intID = $intID
			AND intTypeID = $intTypeID
			AND (dtDOBStart <= '$dtDOB' or dtDOBStart = '0000-00-00' or dtDOBStart IS NULL)
				AND (dtDOBEnd >= '$dtDOB' or dtDOBEnd = '0000-00-00' or dtDOBEnd IS NULL)
			AND intRuleDirection IN ($ruleDirection, $Defs::CLR_BOTH)
		ORDER BY intRuleDirection DESC, dtDOBStart
		LIMIT 1
	];
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my ($intClearanceSettingID, $intAutoApproval, $intRuleDirection) = $query->fetchrow_array();
	$intRuleDirection ||= $Defs::CLR_BOTH;
	$intClearanceSettingID ||= 0;
	$intAutoApproval ||= 0;
	if (! $intClearanceSettingID)	{
		$intAutoApproval = $Data->{'SystemConfig'}{'clrDefaultApprovalAction'} || 0;
	}

	return $intAutoApproval;
	
	
}

sub finaliseClearance	{

### PURPOSE: Once the clearance has been finalised, this function inserts the appropriate person_registration records.

### Once done, it notifies all the levels via email of the current clearance status (ie:Finalised).

	my ($Data, $cID) = @_;

	### If successful, move person and notify everyone.
	my $db = $Data->{'db'};

	my $st = qq[
		SELECT 
            C.intPersonID, 
            C.intDestinationClubID, 
            C.intSourceClubID, 
            M.intGender, 
            DATE_FORMAT(M.dtDOB, "%Y%m%d") as DOBAgeGroup
		FROM tblClearance as C
			INNER JOIN tblPerson as M ON (M.intPersonID = C.intPersonID)
		WHERE intClearanceID = $cID
	];
	my $query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);

	my ($intPersonID, $intClubID, $intSourceClubID, $Gender, $DOBAgeGroup) = $query->fetchrow_array();
	$intPersonID ||= 0;
	$intClubID ||= 0;
	$intSourceClubID ||= 0;
	$Gender ||= 0;
	$DOBAgeGroup ||= '';

	return if ! $intPersonID or ! $intClubID;

	my $genAgeGroup||=new GenAgeGroup ($Data->{'db'},$Data->{'Realm'}, $Data->{'RealmSubType'});
	my $ageGroupID =$genAgeGroup->getAgeGroup($Gender, $DOBAgeGroup) || 0;

	my $intMA_Status = $Defs::RECSTATUS_ACTIVE;

	$st = qq[
		SELECT intMemberClubID
		FROM tblMember_Clubs
		WHERE intPersonID = $intPersonID
			AND intClubID = $intClubID
			AND intStatus = $Defs::RECSTATUS_ACTIVE
		LIMIT 1
	];
	$query = $db->prepare($st) or query_error($st);
	$query->execute or query_error($st);
	my $intMemberClubID = $query->fetchrow_array();
	$intMemberClubID ||= 0;

	$st = qq[
		INSERT INTO tblMember_Clubs
		(intPersonID, intClubID, intStatus)
		VALUES ($intPersonID, $intClubID, $Defs::RECSTATUS_ACTIVE)
	];

	$st = qq[
		UPDATE tblMember_Clubs
		SET intStatus = $Defs::RECSTATUS_ACTIVE
		WHERE intPersonID = $intPersonID
			AND intMemberClubID = $intMemberClubID
	] if $intMemberClubID;
	$db->do($st);

	if ($Data->{'SystemConfig'}{'clrInactiveSourceClub'} and $intClubID != $intSourceClubID )   {
		$st =qq[
			UPDATE tblMember_Clubs
			SET intStatus = $Defs::RECSTATUS_INACTIVE
			WHERE intPersonID = $intPersonID
				AND intClubID = $intSourceClubID
				AND intStatus = $Defs::RECSTATUS_ACTIVE
		];
		$db->do($st);
	}

		$st = qq[
			SELECT intMemberTypeID
			FROM tblMember_Types
			WHERE intPersonID = $intPersonID 
				AND intTypeID=$Defs::MEMBER_TYPE_PLAYER
		];
		my $query = $db->prepare($st) or query_error($st);
		$query->execute or query_error($st);
		my $intMemberTypeID =$query->fetchrow_array() || 0;
		if ($intMemberTypeID)	{
			$st = qq[
				UPDATE tblMember_Types
				SET intRecStatus = $Defs::RECSTATUS_ACTIVE
				WHERE intMemberTypeID = $intMemberTypeID
			];
			$db->do($st);
		}
		else	{
			$st = qq[
				INSERT INTO tblMember_Types
				(intPersonID, intRecStatus, intTypeID)
				VALUES ($intPersonID, $Defs::RECSTATUS_ACTIVE, $Defs::MEMBER_TYPE_PLAYER)
			];
			$db->do($st);
		}
		$st = qq[
			UPDATE tblPerson
			SET intPlayer = 1
			WHERE intPersonID=$intPersonID
		];
		$db->do($st);
	

	$st = qq[
		UPDATE tblPerson
		SET intStatus = $Defs::RECSTATUS_ACTIVE
		WHERE intPersonID = $intPersonID
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
			AND intClubID = $intClubID
			AND intPersonID = $intPersonID
	];
	$db->do($st);

	$st = qq[
	    INSERT INTO tblMember_ClubsClearedOut
		(intRealmID, intClubID, intPersonID, intClearanceID)
		VALUES ($Data->{'Realm'}, $intSourceClubID, $intPersonID, $cID)
	];
	$db->do($st);

	sendCLREmail($Data, $cID, 'FINALISED');

}

sub createClearance	{

### PURPOSE: This function is used to create the clearance.  It prepares all of the screens in the create clearance wizard and then passes control to clearanceForm() (a HTMLForm function) to actually display the clearance questions and insert the records into db.

	my ($action, $Data) = @_;


	#my $db = $Data->{'db'};
	my $db = connectDB('reporting');
	my $q=new CGI;
        my %params=$q->Vars();
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';

	
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;
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
	if (! $destinationClubID)	{
		$body .=qq[Club not found];
		return $body;
	}

	if	(! $memberID and ! $params{'member_surname'} and ! $params{'member_dob'} and ! $params{'member_natnum'} and ! $params{'member_loggedsurname'} and ! $params{'member_systemsurname'} and ! $params{'member_systemdob'})	{
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
			$strWhere .= qq[ AND M.strLocalSurname =$tParams{'member_surname'}];
		}
		if ($params{'member_loggedsurname'})	{
			$strWhere .= qq[ AND M.strLocalSurname =$tParams{'member_loggedsurname'}];
		}
		if ($params{'member_systemsurname'})	{
			$strWhere .= qq[ AND M.strLocalSurname =$tParams{'member_systemsurname'}];
		}
		if ($params{'member_systemdob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_systemdob'}];
		}
		if ($params{'member_dob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_dob'}];
		}
		if ($sourceClubID)	{
			$strWhere .= qq[ AND MC.intClubID = $sourceClubID];
		}

		if ($params{'member_dob'})	{
			$strWhere .= qq[ AND M.dtDOB =$tParams{'member_dob'}];
		}
		if ($sourceClubID)	{
			$strWhere .= qq[ AND MC.intClubID = $sourceClubID];
		}

		my $CLRD_OUT_JOIN = qq[ LEFT JOIN tblMember_ClubsClearedOut as CLRD_OUT ON (CLRD_OUT.intClubID = C.intClubID AND CLRD_OUT.intPersonID = M.intPersonID)];
		my $CLRD_OUT_WHERE = ''; #$Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} ? qq[ AND CLRD_OUT.intPersonID IS NULL] : '';

		my $st = qq[
			SELECT DISTINCT 
                M.intPersonID, 
                M.strLocalFirstname, 
                M.strLocalSurname, 
                M.strNationalNum, 
                DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS DOB, 
                M.dtDOB, 
                MC.intClubID, 
                C.strLocalName as ClubName, 
                DATE_FORMAT(MAX(CLR.dtFinalised),'%d/%m/%Y') AS CLR_DATE, 
                IF(MC.intStatus = 1, 'Y', 'N') as Club_STATUS, 
                DATE_FORMAT(MA.dtLastRegistered, '%d/%m/%Y') AS LastRegistered, 
                CLRD_OUT.intPersonID as CLRD_ID, 
                MAX(MC.intPrimaryClub) as PrimaryClub
			FROM tblPerson as M 
				INNER JOIN tblMember_Clubs as MC ON (MC.intPersonID = M.intPersonID)
				INNER JOIN tblEntity as C ON (C.intEntityID= MC.intClubID)
				LEFT JOIN tblClearance as CLR ON (CLR.intPersonID = M.intPersonID AND CLR.intDestinationClubID = C.intClubID)
				$CLRD_OUT_JOIN
			WHERE 
                M.intRealmID = $Data->{'Realm'}
				AND C.intClubID <> $Data->{'clientValues'}{'clubID'}
				AND C.intRecStatus <> $Defs::RECSTATUS_DELETED
				AND MC.intStatus <> $Defs::RECSTATUS_DELETED
				$strWhere
				$CLRD_OUT_WHERE
			GROUP BY M.intPersonID, C.intClubID
			ORDER BY MAX(CLR.dtFinalised) DESC, M.strLocalSurname, M.strLocalFirstname, M.dtDOB
		];
		
		my $userID=getID($Data->{'clientValues'}, $Data->{'clientValues'}{'authLevel'}) || 0;
		$CLRD_OUT_JOIN = qq[ LEFT JOIN tblMember_ClubsClearedOut as CLRD_OUT ON (CLRD_OUT.intClubID = C.intClubID AND CLRD_OUT.intPersonID = M.intPersonID)];

		my $query = $db->prepare($st) or query_error($st);
	    $query->execute or query_error($st);

		my ($sourceClub, undef, undef) = getNodeDetails($db, $Defs::CLUB_LEVEL_CLEARANCE, $Defs::LEVEL_CLUB, $sourceClubID);
		my $txt_RequestCLR =  $Data->{'SystemConfig'}{'txtRequestCLR'} || 'Request a Clearance';
		my $clrBlob=  $Data->{'SystemConfig'}{'ClearancesBlob'} || '';
		$body .= qq[
			<p>Select a member from the club <b>$sourceClub</b> in which to $txt_RequestCLR for.</p>$clrBlob
                	<table class="listTable">
				<tr>
					<th>&nbsp;</th>
					<th>Surname</th>
					<th>Firstname</th>
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
			my $href = qq[client=$params{'client'}&amp;sourceClubID=$dref->{'intClubID'}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}];
			$href = qq[client=$params{'client'}&amp;sourceClubID=$dref->{'intClubID'}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}] if ($params{'member_loggedsurname'});
			$href = qq[client=$params{'client'}&amp;sourceClubID=$dref->{'intClubID'}&amp;a=CL_createnew&amp;member_natnum=$params{'member_natnum'}] if ($params{'member_systemsurname'});
			$body .= qq[
				<tr>
			];
			if ($Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} and $dref->{CLRD_ID})	{
				$body .= qq[<td><b>CLEARED OUT</b></td>];
			}
			else	{
				$body .= qq[<td><a href="$Data->{'target'}?$href&amp;memberID=$dref->{intPersonID}">select</a></td>];
			}
			$body .= qq[
					<td>$dref->{strLocalSurname}</td>
					<td>$dref->{strLocalFirstname}</td>
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
	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;

	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;

	my $member_natnum= $params->{'member_natnum'} || 0;
	my $sourceClubID = $params->{'sourceClubID'} || 0;
	my $realm = $params->{'realmID'} || $Data->{'Realm'} || 0;

	my ($sourceClub, undef, undef) = getNodeDetails($db, $Defs::CLUB_LEVEL_CLEARANCE, $Defs::LEVEL_CLUB, $sourceClubID);
	$memberID = $memberID || $params->{'memberID'} || 0;
	my $statement = qq[
		SELECT 
            *,     
            DATE_FORMAT(dtDOB,'%d/%m/%Y') AS DOB
		FROM tblPerson 
		WHERE intPersonID = $memberID
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
	my $intClearanceYear =$Data->{'SystemConfig'}{'clrClearanceYear'} || 0;

    my $clradd=qq[
        INSERT INTO tblClearance (intPersonID, intDestinationClubID, intSourceClubID, intRealmID, --FIELDS--, dtApplied, intClearanceStatus, intRecStatus, intClearanceYear )
            VALUES ($memberID, $destinationClubID, $sourceClubID, $realm, --VAL--,  SYSDATE(), $Defs::CLR_STATUS_PENDING, $Defs::RECSTATUS_ACTIVE,  $intClearanceYear)
    ];

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        onlyTypes  => '-37',
    );
       
	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my $intReasonForClearanceID = ($Data->{'SystemConfig'}{'clrHide_intReasonForClearanceID'}==1) ? '1' : '0';
	my $strReasonForClearance =($Data->{'SystemConfig'}{'clrHide_strReasonForClearance'}==1) ? '1' : '0';
	my $strReason=($Data->{'SystemConfig'}{'clrHide_strReason'}==1) ? '1' : '0';
	my $strFilingNumber = ($Data->{'SystemConfig'}{'clrHide_strFilingNumber'} == 1) ? '1' : '0';
	my $intClearancePriority= ($Data->{'SystemConfig'}{'clrHide_intClearancePriority'}==1) ? '1' : '0';

	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || "Update $txt_Clr";
	my $update_labelClr= $Data->{'SystemConfig'}{'txtUpdateLabelClr_CLR'} || "Update $txt_Clr";
	my $update_labelOverride= $Data->{'SystemConfig'}{'txtUpdateLabelClrOverride'} || "Update $txt_Clr";
	my %FieldDefs = (
		Clearance => {
			fields => {
				SourceClub => {
					label => 'Source Club',
					value => $sourceClub,
					type=> 'text',
					readonly => 1,
				},
				MemberName => {
					label => "Member Name",
					value => qq[$memref->{strLocalFirstname} $memref->{strLocalSurname}],
					type=> 'text',
					readonly => 1,
				},
				NatNum=> {
					label => $Data->{'SystemConfig'}{'NationalNumName'},
					value => $memref->{'strNationalNum'},
                    type  => 'text',
					readonly => '1',
                },
				DOB => {
					label => 'Date of birth',
					value => $memref->{'DOB'},
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
				intClearancePriority=> {
                    label => "$txt_Clr Priority",
                    value => $dref->{'intClearancePriority'},
                    type  => 'lookup',
                    options => \%Defs::clearance_priority,
                    firstoption => ['','Select Priority'],
					readonly => $intClearancePriority,
                },
			},
			order => [qw(MemberName NatNum DOB strState SourceClub intReasonForClearanceID strReason strReasonForClearance strFilingNumber intClearancePriority)],
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
				destinationClubID => $destinationClubID,
				member_natnum => $member_natnum,
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

sub preClearanceAdd	{

    ### PURPOSE: Check whether the current member is in a pending clearance, or already in the club.
    
    my($params, $Data, $client, $memberID)=@_;
    my $db = $Data->{'db'};
    
	if ($Data->{'SystemConfig'}{'clrNoMoreAdds'})	{
	    my $error = qq[ <div class="warningmsg">Clearances are unable to be added.  Please contact the $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} administrator with any queries.</div> ];
        return (0,$error);
	}
    
     
	$memberID ||= 0;
	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;
	
	my $st = qq[
			SELECT
				C.intClearanceID,
				C1.strLocalName as DestinationClubName, 
				C2.strLocalName as SourceClubName, 
				C1.intEntityID as DestinationClubID,
                C2.intEntityID as SourceClubID,
				DATE_FORMAT(dtApplied,'%d/%m/%Y') AS AppliedDate 
			FROM
				tblClearance as C
				LEFT JOIN tblEntity as C1 ON (C1.intEntityID = C.intDestinationClubID and C1.intEntityLevel = $Defs::LEVEL_CLUB)
				LEFT JOIN tblEntity as C2 ON (C2.intEntityID = C.intSourceClubID and C2.intEntityLevel = $Defs::LEVEL_CLUB)
		WHERE intPersonID = $memberID
			AND  intClearanceStatus = $Defs::CLR_STATUS_PENDING
			AND intCreatedFrom =0
	];
	my $query = $db->prepare($st) or query_error($st);
        $query->execute or query_error($st);

	my $error_text = '';
	my $existingClearance=0;
     
     while (my $dref = $query->fetchrow_hashref())	{
        my $source_contact_name="";
        my $source_contact_email ="";
        my $destination_contact_name ="";
        my $destination_contact_email="";
        if($dref->{SourceClubID} >0){
                my $source_contactObj = ContactsObj->getList(dbh=>$db, clubid=>$dref->{SourceClubID} , getclearances=>1)||[];
                my $source_contactObjP = ContactsObj->getList(dbh=>$db, clubid=>$dref->{SourceClubID} , getprimary=>1)||[];
		if(scalar(@$source_contactObj)>0){
               		$source_contact_name =qq[@$source_contactObj[0]->{strContactFirstname} @$source_contactObj[0]->{strContactSurname}];
                	$source_contact_email = @$source_contactObj[0]->{strContactEmail};
        	}
		elsif(scalar(@$source_contactObjP)>0){
               		$source_contact_name =qq[@$source_contactObjP[0]->{strContactFirstname} @$source_contactObjP[0]->{strContactSurname}];
                	$source_contact_email = @$source_contactObjP[0]->{strContactEmail};
        	}	
	}
        if($dref->{DestinationClubID} >0){ 
                my  $destination_contactObj = ContactsObj->getList(dbh=>$db,clubid=>$dref->{DestinationClubID} , getclearances=>1) ;
                my  $destination_contactObjP = ContactsObj->getList(dbh=>$db,clubid=>$dref->{DestinationClubID} , getprimary=>1) ;
		if(scalar(@$destination_contactObj)>0){
			$destination_contact_name =qq[@$destination_contactObj[0]->{strContactFirstname} @$destination_contactObj[0]->{strContactSurname}];
                	$destination_contact_email = @$destination_contactObj[0]->{strContactEmail};
        	}
		elsif(scalar(@$destination_contactObjP)>0){
			$destination_contact_name =qq[@$destination_contactObjP[0]->{strContactFirstname} @$destination_contactObjP[0]->{strContactSurname}];
                	$destination_contact_email = @$destination_contactObjP[0]->{strContactEmail};
        	}
	}
        $dref->{SourceEmail} = $source_contact_email;
        $dref->{SourceContact} = $source_contact_name;
        $dref->{DestinationEmail} = $destination_contact_email;
        $dref->{DestinationContact} = $destination_contact_name; 
         $existingClearance++;
         $error_text .= qq[
                	<div class="warningmsg">The selected member is already involved in a pending clearance.  Unable to continue until the below transaction is finalised.</div>
				<p>
					<b>Date Requested:</b> $dref->{AppliedDate}<br>
					<b>Requested From:</b> $dref->{SourceClubName}<br>
					<b>Request To:</b> $dref->{DestinationClubName}<br>
				</p>
        	];
	}

        return (0,$error_text) if $existingClearance;
        return (1,'');

}


sub postClearanceAdd	{

### PURPOSE: This function build's up the starting points between the two clubs then calls getMeetingPoint() to do the grunt work in finding the top node

	my($id,$params,$action,$Data,$db)=@_;
  	return undef if !$db or ! $id;
	my $resultHTML = '';

		my @sourceNodes = ();	
		my @destinationNodes = ();
		my $sourceNodeID=0;
		my $destinationNodeID=0;
		my $sourceTypeID = 0;
		my $destinationTypeID =0;
		my $destinationStatusID =0;
		my $sourceStatusID =0;
	
		my $destinationClubPathID = 0;
		
		my $found = getMeetingPoint($db, $params->{'sourceClubID'}, $params->{'destinationClubID'}, \@sourceNodes, \@destinationNodes);
	
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
				$qry_insert->execute($node->[1], 3, $node->[0], $count, $Defs::DIRECTION_FROM_SOURCE);
				$count++;
			}
			my $skip_first = 0;
			for my $node (@destinationNodes)	{
				$skip_first++;
				next if $skip_first == 1; ## SKIP FIRST Destination NODE (ie: Its the top one).  IT WAS HANDLED IN SOURCE.
				$qry_insert->execute($node->[1], 3, $node->[0], $count, $Defs::DIRECTION_TO_DESTINATION);
				$count++;
			}
			$qry_insert->execute($Defs::LEVEL_CLUB, $Defs::CLUB_LEVEL_CLEARANCE, $params->{'destinationClubID'}, $count, $Defs::DIRECTION_TO_DESTINATION) if $params->{'destinationClubID'};
			$destinationClubPathID = $qry_insert->{mysql_insertid} || 0;

			my $st = qq[
				UPDATE tblClearance
				SET intCurrentPathID = 0
				WHERE intClearanceID = $id
			];
				#SET intCurrentPathID = $firstPathID
			$db->do($st);
			checkAutoConfirms($Data, $id,0);
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
	
	sendCLREmail($Data, $id, 'ADDED');
	return (0, $resultHTML);
}

sub getMeetingPoint	{

	### PURPOSE: This function works out how far up structure tree to go till the meeting entities are found.

	my ($db, $sourceClubID, $destinationClubID, $sourceNodes, $destinationNodes) = @_;
	my $found=0;

	my $st = qq[
		SELECT 
            intChildID, 
            intParentID, 
            intParentLevel
		FROM 
            tblTempEntityStructure
		WHERE 
            intChildID IN ($sourceClubID, $destinationClubID)
            AND intChildLevel = 3
            AND intParentLevel > 3
        ORDER BY intParentLevel ASC
	];
    my $query = $db->prepare($st) or query_error($st);
    $query->execute or query_error($st);

    my %EntityStructure = ();
	while (my $dref = $query->fetchrow_hashref())	{
        $EntityStructure{$dref->{'intChildID'}}{$dref->{'intParentLevel'}} = $dref->{'intParentID'};
    }

    my @Levels = (10,20,30,100);
    foreach my $level (@Levels) {
        my $sourceEntityID = $EntityStructure{$sourceClubID}{$level} || 0;
        my $destinationEntityID = $EntityStructure{$destinationClubID}{$level} || 0;
        if ($sourceEntityID and $destinationEntityID and $sourceEntityID == $destinationEntityID)   {
            $found=1;
        }
	    push @{$sourceNodes}, [$sourceEntityID, $level] if ($sourceEntityID);
	    push @{$destinationNodes}, [$destinationEntityID, $level] if ($destinationEntityID);
        last if $found;
    }

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
	my $client=setClient($Data->{'clientValues'}) || '';
	my $target=$Data->{'target'} || '';
	my $option=$edit ? ($id ? 'edit' : 'add')  :'display' ;

	my $destinationClubID = $Data->{'clientValues'}{'clubID'} || 0;

	my $realm = $params{'realmID'} || $Data->{'Realm'} || 0;

	$memberID = $memberID || $params{'memberID'} || 0;
	my $statement = qq[
		SELECT 
            *, 
            DATE_FORMAT(dtDOB,'%d/%m/%Y') AS DOB
		FROM tblPerson 
		WHERE intPersonID = $memberID
	];
	my $query = $db->prepare($statement);
	$query->execute;
	my $memref = $query->fetchrow_hashref();

	my $body = '';

  	my $resultHTML = '';

	$id ||= 0;
	$statement=qq[
		SELECT 
            *, 
            DATE_FORMAT(dtApplied,'%d/%m/%Y') AS dtApplied
		FROM tblClearance
		WHERE intClearanceID=$id
			AND intPersonID = $memberID
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
			AND intPersonID = $memberID
			AND intCreatedFrom = $Defs::CLR_TYPE_MANUAL
	];
	my $intClearanceYear = $Data->{'SystemConfig'}{'clrClearanceYear'} || 0;
    my $clradd=qq[
        INSERT INTO tblClearance (intPersonID, intRealmID, --FIELDS--, dtApplied, intClearanceStatus, intCreatedFrom, intRecStatus, intClearanceYear)
        VALUES ($memberID, $realm, --VAL--,  SYSDATE(), $Defs::CLR_STATUS_APPROVED, 2, $Defs::RECSTATUS_ACTIVE, $intClearanceYear)
    ];

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'},
        onlyTypes  => '-37',
    );
       
	my $update_label = $Data->{'SystemConfig'}{'txtUpdateLabel_UpdateCLR'} || $Data->{'SystemConfig'}{'txtUpdateLabel_CLR'} || 'Update Clearance';

	my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
	my %FieldDefs = (
		Clearance => {
			fields => {
				strSourceClubName => {
					label => 'From Club',
					value => $dref->{strSourceClubName},
					type=> 'text',
				},
				strDestinationClubName => {
					label => 'To Club',
					value => $dref->{strDestinationClubName},
					type=> 'text',
				},
				MemberName => {
					label => "Member Name",
					value => qq[$memref->{strLocalFirstname} $memref->{strLocalSurname}],
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
			order => [qw(dtApplied MemberName DOB strState strSourceClubName strDestinationClubName intReasonForClearanceID strReasonForClearance strFilingNumber intClearancePriority intClearAction)],
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
		SELECT 
            CONCAT(M.strLocalFirstname, ' ', M.strLocalSurname) as MemberName, 
            C.*, 
            IF(intDestinationClubID > 0, C1.strLocalName, strDestinationClubName) as DestinationClubName, 
            IF(intSourceClubID > 0 , C2.strLocalName, strSourceClubName) as SourceClubName, 
            CP.intTableType, 
            CP.intTypeID, 
            CP.intID, 
            DATE_FORMAT(M.dtDOB,'%d/%m/%Y') AS dtDOB,  
            DATE_FORMAT(C.dtApplied,'%d/%m/%Y') AS dtApplied, 
            DC.strName as DenialCode, 
            C.strReasonForClearance
		FROM tblClearance as C
			INNER JOIN tblClearancePath as CP ON (CP.intClearanceID = C.intClearanceID)
			INNER JOIN tblPerson as M ON (M.intPersonID = C.intPersonID)
			LEFT JOIN tblEntity as C1 ON (C1.intEntityID = C.intDestinationClubID and C1.intEntityLevel = $Defs::LEVEL_CLUB)
			LEFT JOIN tblEntity as C2 ON (C2.intEntityID = C.intSourceClubID and C2.intEntityLevel = $Defs::LEVEL_CLUB)
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
	my $additionalInformation='';
        if ($Data->{'SystemConfig'}{'clrEmailAdditionalInfo'} and $cref->{'strReasonForClearance'})     {
                $additionalInformation = qq[Additional Information: $cref->{'strReasonForClearance'}];
        }
	my $email_body = qq[
$txt_Clr Ref. No.: $cref->{intClearanceID}
Member name: $cref->{MemberName}
To Club: $cref->{DestinationClubName}
Source (From) Club: $cref->{SourceClubName}
$additionalInformation

];

	my ($whos_turn, undef, undef) = getNodeDetails($db, $cref->{intTableType}, $cref->{intTypeID}, $cref->{intID});
	my $emailOnlyCurrentLevel = 0;

	my $viewDetails = qq[To view details, please log into the system and click on the List $txt_Clr]. qq[s option];        
	$viewDetails = $Data->{'SystemConfig'}{'clrEmail_detailsLink'} if ($Data->{'SystemConfig'}{'clrEmail_detailsLink'});

	$emailOnlyCurrentLevel = 1 if ($Data->{'SystemConfig'}{'clr_EmailOnlyCurrentLevel'});
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

	}

	my $st_path = qq[
		SELECT 
            intClearancePathID, 
            intTableType, 
            intTypeID, 
            intID
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

    if ($Data->{'clrCCEmails'}) {
        $cc_list .= qq[;] if ($cc_list);
        $cc_list .= $Data->{'clrCCEmails'};
        $email_body = $email_body . $Data->{'clrCCmsg'};
    }
	
	sendEmail($cc_list, $email_body, $email_subject, $cID, $action);
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

sub postManualClrAction	{

	my($id,$params, $Data,$db)=@_;

	my $clrAction = $params->{'d_intClearAction'} || 0;
	my $clubID = $Data->{'clientValues'}{'clubID'} || 0;
	my $memberID = $Data->{'clientValues'}{'memberID'} || 0;

	$clubID = 0 if ($clubID == $Defs::INVALID_ID);
	$memberID = 0 if ($memberID == $Defs::INVALID_ID);

	if ($params->{'d_intClearAction'} == 1 and $clubID and $memberID)	{
		## CLEAR MEMBER OUT !
		my $st = qq[
			INSERT INTO tblMember_ClubsClearedOut (
				intRealmID, 
				intClubID, 
				intPersonID, 
				intClearanceID 
			)
                	VALUES (
				$Data->{'Realm'}, 			
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
                                intPersonID = $memberID
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
                        	AND intClubID = $clubID
                        	AND intPersonID = $memberID
		];
		$db->do($st);

		$st= qq[
                        UPDATE
                                tblMember_Clubs
                        SET
                                intStatus = $Defs::RECSTATUS_ACTIVE
                        WHERE
                                intPersonID = $memberID
                                AND intClubID = $clubID
                                AND intStatus = $Defs::RECSTATUS_INACTIVE
                        LIMIT 1
                ];
                $db->do($st);
	}

}

1;
