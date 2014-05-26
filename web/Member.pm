#
# $Header: svn://svn/SWM/trunk/web/Member.pm 11652 2014-05-22 07:18:57Z sliu $
#

package Member;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  handleMember
  getAutoMemberNum
  member_details
  setupMemberTypes
  updateMemberNotes
  preMemberAdd
  check_valid_date
  postMemberUpdate
  loadMemberDetails
);

use strict;
use lib '.', '..', 'sportstats';
use Defs;

use Reg_common;
use Utils;
use HTMLForm;
use Countries;
use Postcodes;
use CustomFields;
use FieldLabels;
use ConfigOptions qw(ProcessPermissions);
use GenCode;
use AuditLog;
use MemberPackages;
use Tags;
use DeQuote;
use Duplicates;
use ProdTransactions;
use EditMemberClubs;
use CGI qw(cookie unescape);
use Payments;
use TransLog;
use Transactions;
use ConfigOptions;
use ListMembers;

use MemberRecords;

use Clearances;
use MemberHistory;
use Seasons;
use GenAgeGroup;
use GridDisplay;
use InstanceOf;

use FieldCaseRule;
use HomeMember;
use InstanceOf;
use Photo;
use AccreditationDisplay;
use DefCodes;
use MemberPreferences;
use MemberRecordType;

use Log;
use Data::Dumper;

use PrimaryClub;
use DuplicatePrevention;
sub handleMember {
    my ( $action, $Data, $memberID ) = @_;

    my $resultHTML = '';
    my $memberName = my $title = '';

    if ( $Data->{'clientValues'}{'clubID'} ne $Defs::INVALID_ID ) {
        my $club = $Data->{'clientValues'}{'clubID'};

        #Work out if this player is on permit
        my $st = qq[ 
            SELECT 
                intPermit ,
	            intMemberClubID
            FROM 
                tblMember_Clubs 
            WHERE 
                intMemberID=$memberID 
                AND intClubID=$club 
                AND intStatus=$Defs::RECSTATUS_ACTIVE 
            ORDER BY 
                intPermit ASC
        ];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute;
        my ( $onPermit, $mcID ) = $query->fetchrow_array();
        $Data->{'MemberOnPermit'} = $onPermit || 0;
        $Data->{'MemberActiveInClub'} = 1 if ($mcID);
    }
    my $clrd_out = 0;
    if ( $Data->{'SystemConfig'}{'Clearances_FilterClearedOut'} ) {
        my $club = $Data->{'clientValues'}{'clubID'};
        my $st   = qq[ 
			SELECT 
				intMemberID, 
				MCC.intClubID,
				strName as ClubName 
			FROM 
				tblMember_ClubsClearedOut as MCC 
					INNER JOIN tblClub as C ON (C.intClubID = MCC.intClubID) 
			WHERE 
				intMemberID=$memberID 
				AND intAssocID = $Data->{'clientValues'}{'assocID'}
		];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute;
        my $clubs = '';
        while ( my $dref = $query->fetchrow_hashref() ) {
            $clrd_out = 1 if ( $dref->{'intClubID'} == $club );
            $clubs .= qq[, ] if $clubs;
            $clubs .= $dref->{'ClubName'};
        }
        $Data->{'MemberClrdOut'} = $clubs ? qq[<b>Cleared Out of: $clubs</b>] : '';
        $Data->{'MemberClrdOut_ofClub'}        = $clrd_out if ( $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_CLUB );
        $Data->{'MemberClrdOut_ofCurrentClub'} = $clrd_out if ( $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC );
    }

    if ( $action =~ /M_PH_/ ) {
        my $newaction = '';
        ( $resultHTML, $title, $newaction ) = handle_photo( $action, $Data, $memberID );
        $action = $newaction if $newaction;
    }
    if ( $action =~ /^M_HID/ ) {
        delMemberHistory( $Data, $memberID );
        $action = 'M_HOME';
    }
    if ( $action =~ /^M_DT/ ) {
        #Member Details
        ( $resultHTML, $title ) = member_details( $action, $Data, $memberID );
    }
    elsif ( $action =~ /^M_A/ ) {
	    #Member Details
        ( $resultHTML, $title ) = member_details( $action, $Data, $memberID );
	}
    elsif ( $action =~ /^M_LSROup/ ) {
        ( $resultHTML, $title ) = bulkMemberRolloverUpdate( $Data, $action );
    }
    elsif ( $action =~ /^M_LSRO/ ) {
        ( $resultHTML, $title ) = bulkMemberRollover( $Data, $action );
    }
    elsif ( $action =~ /^M_L/ ) {
        ( $resultHTML, $title ) = listMembers( $Data, $memberID, $action );
    }
    elsif ( $action =~ /^M_PRS_L/ ) {
        ( $resultHTML, $title ) = listMembers( $Data, $memberID, $action );
    }
    elsif ( $action =~ /M_TG_/ ) {
        ( $resultHTML, $title ) = handleTags( $action, $Data, $memberID );
    }
    elsif ( $action =~ /M_CLB_/ ) {
        ( $resultHTML, $title ) = handleMemberClub( $action, $Data, $memberID );
    }
    elsif ( $action =~ /M_PRODTXN_/ ) {
        ( $resultHTML, $title ) = handleProdTransactions( $action, $Data, $memberID );
    }
    elsif ( $action =~ /M_TXN_/ ) {
        ( $resultHTML, $title ) = Transactions::handleTransactions( $action, $Data, $memberID );
    }
    elsif ( $action =~ /M_TXNLog/ ) {
        ( $resultHTML, $title ) = TransLog::handleTransLogs( $action, $Data, $memberID );
    }
    elsif ( $action =~ /M_PAY_/ ) {
        ( $resultHTML, $title ) = handlePayments( $action, $Data, 0 );
    }
    elsif ( $action =~ /^M_DUP_/ ) {
        ( $resultHTML, $title ) = MemberDupl( $action, $Data, $memberID );
    }
    elsif ( $action =~ /^M_DEL/ ) {

        #($resultHTML,$title)=delete_member($Data, $memberID);
    }
    elsif ( $action =~ /^M_TRANSFER/ ) {
        ( $resultHTML, $title ) = MemberTransfer($Data);
    }
    elsif ( $action =~ /^M_TAG/ ) {
        ( $resultHTML, $title ) = Tags::listTags( $Data, $memberID, $action );
    }
    elsif ( $action =~ /M_CLUBS/ ) {
        my ( $clubStatus, $clubs, $teams ) = showClubTeams( $Data, $memberID );
        $clubs      = qq[<div class="warningmsg">No $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} History found</div>] if !$clubs;
        $resultHTML = $clubs;
        $title      = "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} History";
    }
    elsif ( $action =~ /M_SEASONS/ ) {
        ( $resultHTML, $title ) = showSeasonSummary( $Data, $memberID );
    }
    elsif ( $action =~ /M_CLR/ ) {
        $resultHTML = clearanceHistory( $Data, $memberID ) || '';
        my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
        $title = $txt_Clr . " History";
    }
    elsif ( $action =~ /^M_HOME/ ) {
        my ( $FieldDefinitions, $memperms ) = member_details( '', $Data, $memberID, {}, 1 );
        ( $resultHTML, $title ) = showMemberHome( $Data, $memberID, $FieldDefinitions, $memperms );
    }
    elsif ( $action =~ /^M_NACCRED/ ) {
        ( $resultHTML, $title ) = handleAccreditationDisplay( $action, $Data, $memberID );
    }
    elsif ( $action =~ /^M_PREFS/ ) {
        ( $resultHTML, $title ) = memberPreferences( $action, $Data, $memberID );
    }
    else {
        print STDERR "Unknown action $action\n";
    }
    return ( $resultHTML, $title );
}

sub updateMemberNotes {

    my ( $db, $assocID, $memberID, $notes_ref ) = @_;
    $memberID ||= 0;
    my $st_deceased = qq[
        UPDATE tblMember
        SET intDeceased = 0, tTimeStamp = tTimeStamp
        WHERE intMemberID = ?  AND intDeceased IS NULL
        LIMIT 1
	];
    $db->do( $st_deceased, undef, $memberID );

    my $fromsync    = $notes_ref->{'fromsync'} || 0;
    my @noteFields  = (qw(strNotes strMedicalNotes strMemberCustomNotes1 strMemberCustomNotes2 strMemberCustomNotes3 strMemberCustomNotes4 strMemberCustomNotes5 ));
    my %Notes       = ();
    my %notes_ref_l = %{$notes_ref};

    #deQuote($db, \%notes_ref_l);
    my ( $insert_cols, $insert_vals, $update_vals ) = ( "", "", "" );
    my @value_list;

    for my $f (@noteFields) {
        next if ( !exists $notes_ref_l{ 'd_' . $f } and !exists $notes_ref_l{$f} );

        $Notes{$f} = $notes_ref_l{ 'd_' . $f } || $notes_ref_l{$f} || '';
        my $fieldname = $f;
        $fieldname = "strMemberNotes"        if $f eq 'strNotes';
        $fieldname = "strMemberMedicalNotes" if $f eq 'strMedicalNotes';
        $insert_cols .= qq[, $fieldname];

        $insert_vals .= qq[, ?];
        $update_vals .= qq[, $fieldname = ? ];
        push @value_list, $Notes{$f};
    }

    my $st = qq[
        INSERT INTO tblMemberNotes
            (intNotesMemberID, intNotesAssocID $insert_cols)
        VALUES 
            ($memberID, $assocID $insert_vals)
        ON DUPLICATE KEY UPDATE tTimeStamp=NOW() $update_vals
    ];

    my $query = $db->prepare($st);
    $query->execute( @value_list, @value_list );

    if ( !$fromsync ) {
        $st = qq[
            UPDATE tblMember_Associations
            SET tTimeStamp=NOW()
            WHERE intMemberID = ? AND intAssocID = ?
		];
        $db->do( $st, undef, $memberID, $assocID );
    }

}

sub MemberTransfer {

    my ($Data) = @_;

    my $client           = setClient( $Data->{'clientValues'} ) || '';
    my $body             = '';
    my $cgi              = new CGI;
    my %params           = $cgi->Vars();
    my $db               = $Data->{'db'};
    my $transfer_natnum  = $params{'transfer_natnum'} || '';
    my $transfer_surname = $params{'transfer_surname'} || '';
    my $transfer_dob     = $params{'transfer_dob'} || '';
    my $memberID         = $params{'memberID'} || 0;
    $transfer_dob = '' if !check_valid_date($transfer_dob);
    $transfer_dob = _fix_date($transfer_dob) if ( check_valid_date($transfer_dob) );
    deQuote( $db, \$transfer_natnum );
    deQuote( $db, \$transfer_surname );
    deQuote( $db, \$transfer_dob );
    my $confirmed = $params{'transfer_confirm'} || 0;
    my $assocTypeIDWHERE = exists $Data->{'SystemConfig'}{'MemberTransfer_AssocType'} ? qq[ AND A.intAssocTypeID = $Data->{'SystemConfig'}{'MemberTransfer_AssocType'} ] : '';
    my $st = qq[
		SELECT 
            M.intMemberID, 
            A.strName, 
            A.intAssocID, 
            MA.intRecStatus, 
            CONCAT(M.strFirstname, ' ', M.strSurname) as MemberName, 
            DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB, 
            DATE_FORMAT(dtDOB, "%Y%m%d") as DOBAgeGroup, 
            M.intGender
		FROM tblMember as M
			INNER JOIN tblMember_Associations as MA ON (MA.intMemberID = M.intMemberID)
			INNER JOIN tblAssoc as A ON (A.intAssocID = MA.intAssocID)
		WHERE M.intRealmID = $Data->{'Realm'}
			$assocTypeIDWHERE
			AND M.strSurname = $transfer_surname
			AND (M.strNationalNum = $transfer_natnum OR M.dtDOB= $transfer_dob)
			AND M.intStatus = $Defs::MEMBERSTATUS_ACTIVE
	];
    $st .= qq[ AND M.intMemberID = $memberID] if $memberID;

    if ( !$params{'transfer_surname'} and ( !$params{'transfer_dob'} or !$params{'transfer_surname'} ) ) {
        my $assocType = '';
        my $assocTypeIDWHERE = exists $Data->{'SystemConfig'}{'MemberTransfer_AssocType'} ? qq[ AND intSubTypeID = $Data->{'SystemConfig'}{'MemberTransfer_AssocType'} ] : '';
        if ($assocTypeIDWHERE) {
            my $st = qq[
				SELECT strSubTypeName
				FROM tblRealmSubTypes
				WHERE intRealmID = $Data->{'Realm'}
		                        $assocTypeIDWHERE
			];
            my $query = $db->prepare($st);
            $query->execute;
            my $dref = $query->fetchrow_hashref() || undef;
            $assocType = qq[ <b>(from $dref->{strSubTypeName} only)</b>];
        }
        $body .= qq[
			<form action="$Data->{'target'}" method="POST" style="float:left;" onsubmit="document.getElementById('btnsubmit').disabled=true;return true;">
                                <p>If you wish to Transfer a member to this Association $assocType, please fill in the Surname and $Data->{'SystemConfig'}{'NationalNumName'} or Date of Birth below and click <b>Transfer Member</b>.</p>

                        <table>
				<tr><td><span class="label">Member's Surname:</td><td><span class="formw"><input type="text" name="transfer_surname" value=""></td></tr>
				<tr><td><b>AND</b></td></tr>
				<tr><td>&nbsp;</td></tr>
				<tr><td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td><td><span class="formw"><input type="text" name="transfer_natnum" value=""></td></tr>
				<tr><td><b>OR</b></td></tr>
				<tr><td><span class="label">Member's Date of Birth:</td><td><span class="formw"><input type="text" name="transfer_dob" value="">&nbsp;<i>dd/mm/yyyy</li></td></tr>
			</table>
                                <input type="hidden" name="a" value="M_TRANSFER">
                                <input type="hidden" name="client" value="$client">
                                <input type="submit" value="Transfer Member" id="btnsubmit" name="btnsubmit"  class="button proceed-button">
                        </form>
		];
    }
    elsif ( !$confirmed and !$memberID ) {
        my $query = $db->prepare($st);
        $query->execute;
        $body .= qq[
                                <p>Please select a member to be transferred and click the <b>select</b> link.</p>
                        <p>
                        	<table>
                               	<tr><td>&nbsp;</td>		
								<td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td>
                               	<td><span class="label">Member's Name:</td>
                               	<td><span class="label">Member's Date Of Birth:</td>
                               	<td><span class="label">Linked To:</td>
							</tr>
		];
        my $count = 0;
        while ( my $dref = $query->fetchrow_hashref() ) {
            $count++;
            my $href = qq[client=$client&amp;a=M_TRANSFER&amp;transfer_surname=$params{'transfer_surname'}&amp;transfer_dob=$params{'transfer_dob'}&amp;transfer_natnum=$params{'transfer_natnum'}];
            $body .= qq[<tr><td><a href="$Data->{'target'}?$href&amp;memberID=$dref->{intMemberID}">select</a></td>
							<td>$dref->{strNationalNum}</td>
							<td>$dref->{MemberName}</td>
							<td>$dref->{dtDOB}</td>
							<td>$dref->{strName}</td></tr>];
        }
        $body .= qq[</table>];
        if ( !$count ) {
            $body = qq[<p class="warningmsg">No Members found</p>];
        }

    }
    elsif ( !$confirmed and $memberID ) {
        my $query = $db->prepare($st);
        $query->execute;
        $body .= qq[
                        <form action="$Data->{'target'}" method="POST" style="float:left;" onsubmit="document.getElementById('btnsubmit').disabled=true;return true;">
                                <p>Please review the member to be transferred and click the <b>Confirm Transfer</b> button below.</p>

                        <p>
                                <table>
                                <tr><td><span class="label">$Data->{'SystemConfig'}{'NationalNumName'}:</td><td><span class="formw">:$params{'transfer_natnum'}</td></tr>
                                <tr><td><span class="label">Member's Surname:</td><td><span class="formw">:$params{'transfer_surname'}</td></tr>
                                <tr><td><span class="label">Member's DOB:</td><td><span class="formw">:$params{'transfer_dob'}</td></tr>
                                <tr><td><span class="label">Linked to:</td><td>&nbsp;</td></tr>
                ];
        my $count     = 0;
        my $thisassoc = 0;
        while ( my $dref = $query->fetchrow_hashref() ) {
            $thisassoc = 1 if ( $dref->{intAssocID} == $Data->{'clientValues'}{'assocID'} );
            $count++;
            $body .= qq[<tr><td colspan="2">$dref->{strName}</td></tr>];
        }
        $body .= qq[
                                </table><br>
                                <input type="hidden" name="a" value="M_TRANSFER">
                                <input type="hidden" name="transfer_confirm" value="1">
                                <input type="hidden" name="transfer_natnum" value="$params{'transfer_natnum'}">
                                <input type="hidden" name="transfer_surname" value="$params{'transfer_surname'}">
                                <input type="hidden" name="transfer_dob" value="$params{'transfer_dob'}">
                                <input type="hidden" name="memberID" value="$memberID">
                                <input type="hidden" name="client" value="$client">
                                <input type="submit" value="Confirm transfer" id="btnsubmit" name="btnsubmit"  class="button proceed-button">
                        </form>
                ];
        $body = qq[<p class="warningmsg">Member already exists in this Association</p>] if ($thisassoc);
        if ( !$count ) {
            $body = qq[<p class="warningmsg">Member not found</p>];
        }
    }
    elsif ($confirmed) {
        $st .= qq[ LIMIT 1];
        my $query = $db->prepare($st);
        $query->execute;
        my ( $memberID, undef, $oldAssocID, $recstatus, undef, undef, $DOBAgeGroup, $Gender ) = $query->fetchrow_array();
        $DOBAgeGroup ||= '';
        $Gender      ||= 0;
        $memberID    ||= 0;
        my $assocID      = $Data->{clientValues}{'assocID'} || 0;
        my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
        my %types        = ();

        #$types{'int#PlayerStatus'} = 1;
        if ( !$types{'intPlayerStatus'} and !$types{'intCoachStatus'} and !$types{'intUmpireStatus'} and !$types{'intMiscStatus'} and !$types{'intVolunteerStatus'} and !$types{'intOther1Status'} and !$types{'intOther2Status'} ) {
            $types{'intPlayerStatus'} = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_PLAYER or $Data->{'SystemConfig'}{'TransferAsPlayer'} );
            $types{'intCoachStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_COACH );
            $types{'intUmpireStatus'} = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_UMPIRE );
            $types{'intMiscStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_MISC );
            $types{'intVolunteerStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_VOLUNTEER );
        }
        $types{'intMSRecStatus'} = 1;
        if ( $memberID and $assocID ) {
            my $genAgeGroup ||= new GenAgeGroup( $Data->{'db'}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $assocID );
            my $ageGroupID = $genAgeGroup->getAgeGroup( $Gender, $DOBAgeGroup ) || 0;
            my $upd_st = qq[
				UPDATE 
					tblMember_Associations
				SET 
					intRecStatus=1
				WHERE
					intMemberID= $memberID
					AND intAssocID = $assocID
				LIMIT 1
			];
            $db->do($upd_st);
            my $ins_st = qq[
				INSERT IGNORE INTO tblMember_Associations
				(intMemberID, intAssocID, intRecStatus)
				VALUES ($memberID, $assocID, 1)
			];
            $db->do($ins_st);
            Seasons::insertMemberSeasonRecord( $Data, $memberID, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, 0, $ageGroupID, \%types );
            $ins_st = qq[
				INSERT INTO tblMember_Types
                    (intMemberID, intTypeID, intSubTypeID, intActive, intAssocID, intRecStatus)
                VALUES 
                    ($memberID,$Defs::MEMBER_TYPE_PLAYER,0,1,$assocID, 1)
			];
            $db->do($ins_st);
            Transactions::insertDefaultRegoTXN( $db, $Defs::LEVEL_MEMBER, $memberID, $assocID );

            if ( $Data->{clientValues}{'clubID'} and $Data->{clientValues}{'clubID'} > 0 ) {
                $ins_st = qq[
					INSERT INTO tblMember_Clubs
					    (intMemberID, intClubID, intStatus)
					VALUES 
                        ($memberID, $Data->{clientValues}{'clubID'}, 1)
				];
                $db->do($ins_st);
                Seasons::insertMemberSeasonRecord( $Data, $memberID, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, $Data->{'clientValues'}{'clubID'}, $ageGroupID, \%types );
            }
            my $mem_st = qq[
				UPDATE tblMember
				SET intPlayer = 1
				WHERE intMemberID = $memberID
				LIMIT 1
			];
            $db->do($mem_st);
            my %tempClientValues = %{ $Data->{clientValues} };
            $tempClientValues{memberID}     = $memberID;
            $tempClientValues{currentLevel} = $Defs::LEVEL_MEMBER;
            my $tempClient = setClient( \%tempClientValues );
            $body = qq[ <div class="OKmsg">The member has been transferred</div><br><a href="$Data->{'target'}?client=$tempClient&amp;a=M_HOME">click here to display members record</a>];

            if ( $Data->{'SystemConfig'}{'MemberTransferCustomFields'} ) {
                my $st = qq[
					INSERT IGNORE INTO tblMemberNotes
					(
						intNotesMemberID, 
						intNotesAssocID, 
						strMemberNotes, 
						strMemberMedicalNotes, 
						strMemberCustomNotes1, 
						strMemberCustomNotes2, 
						strMemberCustomNotes3, 
						strMemberCustomNotes4, 
						strMemberCustomNotes5
					)
					SELECT 
						$memberID, 
						$assocID, 
						strMemberNotes, 
						strMemberMedicalNotes, 
						strMemberCustomNotes1, 
						strMemberCustomNotes2, 
						strMemberCustomNotes3, 
						strMemberCustomNotes4, 
						strMemberCustomNotes5
					FROM tblMemberNotes
						INNER JOIN tblAssoc as A ON (
							A.intAssocID = intNotesAssocID
							AND intAssocTypeID = $Data->{'RealmSubType'}
						)
					WHERE intNotesMemberID = $memberID
						AND intNotesAssocID = $oldAssocID
				];
                $db->do($st);

                $st = qq[
					UPDATE tblMember_Associations as MA 
						INNER JOIN tblMember_Associations as MAold ON (
							MAold.intMemberID = MA.intMemberID
							AND MAold.intAssocID=$oldAssocID
						)
						INNER JOIN tblAssoc as Aold ON (
							Aold.intAssocID = MAold.intAssocID
						)
					SET 
						MA.strCustomStr1 = MAold.strCustomStr1, 
						MA.strCustomStr2 = MAold.strCustomStr2, 
						MA.strCustomStr3 = MAold.strCustomStr3, 
						MA.strCustomStr4 = MAold.strCustomStr4, 
						MA.strCustomStr5 = MAold.strCustomStr5, 
						MA.strCustomStr6 = MAold.strCustomStr6, 
						MA.strCustomStr7 = MAold.strCustomStr7, 
						MA.strCustomStr8 = MAold.strCustomStr8, 
						MA.strCustomStr9 = MAold.strCustomStr9, 
						MA.strCustomStr10= MAold.strCustomStr10,
						MA.strCustomStr11= MAold.strCustomStr11,
						MA.strCustomStr12= MAold.strCustomStr12,
						MA.strCustomStr13= MAold.strCustomStr13,
						MA.strCustomStr14= MAold.strCustomStr14, 
						MA.strCustomStr15= MAold.strCustomStr15, 
						MA.strCustomStr16= MAold.strCustomStr16, 
						MA.strCustomStr17= MAold.strCustomStr17, 
						MA.strCustomStr18= MAold.strCustomStr18, 
						MA.strCustomStr19= MAold.strCustomStr19, 
						MA.strCustomStr20= MAold.strCustomStr20,
						MA.strCustomStr21= MAold.strCustomStr21,
						MA.strCustomStr22= MAold.strCustomStr22,
						MA.strCustomStr23= MAold.strCustomStr23,
						MA.strCustomStr24= MAold.strCustomStr24, 
						MA.strCustomStr25= MAold.strCustomStr25, 
						MA.dblCustomDbl1 = MAold.dblCustomDbl1,
						MA.dblCustomDbl2 = MAold.dblCustomDbl2,
						MA.dblCustomDbl3 = MAold.dblCustomDbl3,
						MA.dblCustomDbl4 = MAold.dblCustomDbl4,
						MA.dblCustomDbl5 = MAold.dblCustomDbl5,
						MA.dblCustomDbl6 = MAold.dblCustomDbl6,
						MA.dblCustomDbl7 = MAold.dblCustomDbl7,
						MA.dblCustomDbl8 = MAold.dblCustomDbl8,
						MA.dblCustomDbl9 = MAold.dblCustomDbl9,
						MA.dblCustomDbl10 = MAold.dblCustomDbl10,
						MA.dblCustomDbl11 = MAold.dblCustomDbl11,
						MA.dblCustomDbl12 = MAold.dblCustomDbl12,
						MA.dblCustomDbl13 = MAold.dblCustomDbl13,
						MA.dblCustomDbl14 = MAold.dblCustomDbl14,
						MA.dblCustomDbl15 = MAold.dblCustomDbl15,
						MA.dblCustomDbl16 = MAold.dblCustomDbl16,
						MA.dblCustomDbl17 = MAold.dblCustomDbl17,
						MA.dblCustomDbl18 = MAold.dblCustomDbl18,
						MA.dblCustomDbl19 = MAold.dblCustomDbl19,
						MA.dblCustomDbl20 = MAold.dblCustomDbl20,
						MA.dtCustomDt1 = MAold.dtCustomDt1, 
						MA.dtCustomDt2 = MAold.dtCustomDt2, 
						MA.dtCustomDt3 = MAold.dtCustomDt3, 
						MA.dtCustomDt4 = MAold.dtCustomDt4, 
						MA.dtCustomDt5 = MAold.dtCustomDt5, 
						MA.dtCustomDt6 = MAold.dtCustomDt6, 
						MA.dtCustomDt7 = MAold.dtCustomDt7, 
						MA.dtCustomDt8 = MAold.dtCustomDt8, 
						MA.dtCustomDt9 = MAold.dtCustomDt9, 
						MA.dtCustomDt10 = MAold.dtCustomDt10, 
						MA.dtCustomDt11 = MAold.dtCustomDt11, 
						MA.dtCustomDt12 = MAold.dtCustomDt12, 
						MA.dtCustomDt13 = MAold.dtCustomDt13, 
						MA.dtCustomDt14 = MAold.dtCustomDt14, 
						MA.dtCustomDt15 = MAold.dtCustomDt15, 
						MA.intCustomLU1 = MAold.intCustomLU1,
						MA.intCustomLU2 = MAold.intCustomLU2,
						MA.intCustomLU3 = MAold.intCustomLU3,
						MA.intCustomLU4 = MAold.intCustomLU4,
						MA.intCustomLU5 = MAold.intCustomLU5,
						MA.intCustomLU6 = MAold.intCustomLU6,
						MA.intCustomLU7 = MAold.intCustomLU7,
						MA.intCustomLU8 = MAold.intCustomLU8,
						MA.intCustomLU9 = MAold.intCustomLU9,
						MA.intCustomLU10 = MAold.intCustomLU10,
						MA.intCustomLU11 = MAold.intCustomLU11,
						MA.intCustomLU12 = MAold.intCustomLU12,
						MA.intCustomLU13 = MAold.intCustomLU13,
						MA.intCustomLU14 = MAold.intCustomLU14,
						MA.intCustomLU15 = MAold.intCustomLU15,
						MA.intCustomLU16 = MAold.intCustomLU16,
						MA.intCustomLU17 = MAold.intCustomLU17,
						MA.intCustomLU18 = MAold.intCustomLU18,
						MA.intCustomLU19 = MAold.intCustomLU19,
						MA.intCustomLU20 = MAold.intCustomLU20,
						MA.intCustomLU21 = MAold.intCustomLU21,
						MA.intCustomLU22 = MAold.intCustomLU22,
						MA.intCustomLU23 = MAold.intCustomLU23,
						MA.intCustomLU24 = MAold.intCustomLU24,
						MA.intCustomLU25 = MAold.intCustomLU25,
						MA.intCustomBool1 = MAold.intCustomBool1,
						MA.intCustomBool2 = MAold.intCustomBool2,
						MA.intCustomBool3 = MAold.intCustomBool3,
						MA.intCustomBool4 = MAold.intCustomBool4,
						MA.intCustomBool5 = MAold.intCustomBool5
						MA.intCustomBool6 = MAold.intCustomBool6,
						MA.intCustomBool7 = MAold.intCustomBool7,
				WHERE MA.intMemberID = $memberID
					AND MA.intAssocID = $assocID
					AND Aold.intAssocTypeID = $Data->{'RealmSubType'}
				];
                $db->do($st);

            }
        }
    }
    else {
        return ( "Invalid Option", "Transfer Member" );
    }
    return ( $body, "Member Transfer" );

}

sub member_details {
    my ( $action, $Data, $memberID, $prefillData, $returndata ) = @_;
    $returndata ||= 0;
    my $option = 'display';
    $option = 'edit' if $action eq 'M_DTE' and allowedAction( $Data, 'm_e' );
    $option = 'add'  if $action eq 'M_A'   and allowedAction( $Data, 'm_a' );
    $option = 'add' if ( $Data->{'RegoForm'} and !$memberID );
    $memberID = 0 if $option eq 'add';
    my $hideWebCamTab = $Data->{SystemConfig}{hide_webcam_tab} ? qq[&hwct=1] : '';
    my $assoc_obj = getInstanceOf( $Data, 'assoc', $Data->{'clientValues'}{'assocID'} );
    my $field = loadMemberDetails( $Data->{'db'}, $memberID, $Data->{'clientValues'}{'assocID'} ) || ();
    

    if ( $prefillData and ref $prefillData ) {
        if ($memberID) {
            for my $k ( keys %{$prefillData} ) { $field->{$k} ||= $prefillData->{$k} if $prefillData->{$k}; }
        }
        else {
            $field = $prefillData;
        }
    }
    my $natnumname = $Data->{'SystemConfig'}{'NationalNumName'} || 'National Number';
    my $FieldLabels   = FieldLabels::getFieldLabels( $Data, $Defs::LEVEL_MEMBER );
    my @countries     = getCountriesArray($Data);
    my %countriesonly = ();
    for my $c (@countries) {
        $countriesonly{$c} = $c;
    }
    my $countries = getCountriesHash($Data);
    my $state_options = get_state_map();

    my ($DefCodes, $DefCodesOrder) = getDefCodes(
        dbh        => $Data->{'db'}, 
        realmID    => $Data->{'Realm'},
        subRealmID => $Data->{'RealmSubType'} || $field->{'intAssocTypeID'},
        assocID    => $Data->{'clientValues'}{'assocID'},
        hideCodes  => $Data->{'SystemConfig'}{'AssocConfig'}{'hideDefCodes'},
    );

    my %SchoolGrades = ();
    my @SchoolGradesOrder = ();
    if ( $Data->{'SystemConfig'}{'Schools'} ) {
        my $statement = qq[
            SELECT intGradeID, strName
            FROM tblSchoolGrades
            WHERE intSchoolRealm=$Data->{'SystemConfig'}{'Schools'}
            ORDER BY intOrder 
        ];
        my $query = $Data->{'db'}->prepare($statement);
        $query->execute;
        while ( my ( $id, $strName,$intOrder ) = $query->fetchrow_array ) {
            $SchoolGrades{$id} = $strName || '';
            push @SchoolGradesOrder, $id;
	    }
    }
    my $MemberPackages = getMemberPackages($Data) || '';
    my $CustomFieldNames = CustomFields::getCustomFieldNames( $Data, $field->{'intAssocTypeID'} ) || '';
    my $fieldsdefined = 1;
    if ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC ) {

        #Check to see if display fields are defined
        my $found = 0;
        if ( $Data->{'SystemConfig'}{'DontCheckAssocConfig'} ) {
            $found = 1;
        }
        else {
            for my $k ( keys %{ $Data->{'Permissions'}{'Member'} } ) {
                if (    $Data->{'Permissions'}{'Member'}{$k} eq 'Editable'
                     or $Data->{'Permissions'}{'Member'}{$k} eq 'ReadOnly'
                     or $Data->{'Permissions'}{'Member'}{$k} eq 'Compulsory'
                     or $Data->{'Permissions'}{'Member'}{$k} eq 'AddOnlyCompulsory' )
                {
                    $found = 1;
                    last;
                }
            }
        }
        $fieldsdefined = 0 if !$found;
    }
    if ( !$fieldsdefined and !$Data->{'RegoForm'} ) {
        my %cl = %{ $Data->{'clientValues'} };
        $cl{'currentLevel'} = $Defs::LEVEL_ASSOC;
        my $cl  = setClient( \%cl );
        my $txt = qq[
			<p class="warning">No fields have been configured to display</p>
			<p>To configure which fields to display you must go into the <a href="$Data->{'target'}?a=FC_C_d&amp;client=$cl">$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Configuration options</a>.</p>
		];
        return ( $txt, 'Add a New Member' );
    }
    if ( $option eq 'add' and $Data->{'SystemConfig'}{'Schools'} and !$Data->{'SystemConfig'}{'ForgetSchool'} ) {

        #Schools are enabled and we are adding a new member.
        #Check to see if there is a school cookie and set variables appropriately
        my $schoolcookie_val = cookie($Defs::SCHOOL_COOKIE) || '';
        if ($schoolcookie_val) {
            my ( $sname, $sid, $ssub ) = split /\|/, $schoolcookie_val;
            $field->{'strSchoolName'}   ||= $sname || '';
            $field->{'strSchoolSuburb'} ||= $ssub  || '';
            $field->{'intSchoolID'}     ||= $sid   || 0;
        }
    }
    my %genderoptions = ();
    for my $k ( keys %Defs::PersonGenderInfo ) {
        next if !$k;
        next if ( $Data->{'SystemConfig'}{'NoUnspecifiedGender'} and $k eq $Defs::GENDER_NONE );
        $genderoptions{$k} = $Defs::PersonGenderInfo{$k} || '';
    }

    my $client = setClient( $Data->{'clientValues'} ) || '';
    my $RecStatus_readonly = ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC and !$Data->{'SystemConfig'}{'AllowClubsAssocStatus'} ) ? 1 : 0;

    my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);

    my $interestHeader = qq[Interests];
    $interestHeader = $Data->{'SystemConfig'}{'InterestsHeader'} if $Data->{'SystemConfig'}{'InterestsHeader'};
    if ( $assocSeasons->{'allowSeasons'} and $option eq 'add' ) {
        my $txt_SeasonName = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
        $interestHeader = qq[Add Member for $assocSeasons->{'newRegoSeasonName'} $txt_SeasonName as];
    }
    my $addressvalidation = '';
    if ( $Data->{'SystemConfig'}{'AddressValidation'} and ( $option eq 'add' or $option eq 'edit' ) ) {
        $addressvalidation = qq[
			<script language="JavaScript" type="text/javascript" src="js/thickbox.js"></script>
    <link rel="stylesheet" type="text/css" href="css/thickbox.css">


			<script language="JavaScript" type="text/javascript" src="js/validateaddress.js"></script>
			<br><br><br><input type="button" value="Validate Address" onclick="validateaddress('http://devel.pnp-local.com.au/warren/qas650/sample/php/control.php');">
		];
    }
    my $photolink = '';
    if ($field->{'intMemberID'}) {
        my $hash = authstring($field->{'intMemberID'});
        $photolink = qq[<img src = "getphoto.cgi?pa=$field->{'intMemberID'}f$hash" onerror="this.style.display='none'" height='200px'>];
    }
    my $field_case_rules = get_field_case_rules({dbh=>$Data->{'db'}, client=>$client, type=>'Member'});
	my @reverseYNOrder = ('',1,0);

    my $mrt_config = ($Data->{'SystemConfig'}{'EnableMemberRecords'}) ? get_current_mrt_config($Data) : {};

    my %FieldDefinitions = (
        fields => {
            strNationalNum => {
                label       => $FieldLabels->{'strNationalNum'},
                value       => $field->{strNationalNum},
                type        => 'text',
                size        => '14',
                readonly    => 1,
                sectionname => 'details',
            },
            strMemberNo => {
                label       => $FieldLabels->{'strMemberNo'},
                value       => $field->{strMemberNo},
                type        => 'text',
                size        => '15',
                maxsize     => '15',
                sectionname => 'details',
            },
            intRecStatus => {
                label         => $FieldLabels->{'intRecStatus'},
                value         => $field->{intRecStatus},
                type          => 'checkbox',
                sectionname   => 'details',
                default       => 1,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                noadd         => 1,
                readonly      => $RecStatus_readonly,
            },
            intMemberToHideID => {
                label         => $FieldLabels->{'intMemberToHideID'},
                value         => $field->{'intMemberToHideID'} ? 0 : 1,
                type          => 'checkbox',
                sectionname   => 'other',
                default       => 1,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                readonly => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC ) ? 1 : 0,
                SkipProcessing => 1,
            },

            ## ADDED BY TC - 01/07/08
            intDefaulter => {
                label => $Data->{'SystemConfig'}{'Defaulter'} ? $Data->{'SystemConfig'}{'Defaulter'} : $FieldLabels->{'intDefaulter'},
                value => $field->{intDefaulter},
                type  => 'checkbox',
                sectionname   => 'details',
                default       => 0,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
                noadd         => 1,
            },
            ##

            strSalutation => {
                label       => $FieldLabels->{'strSalutation'},
                value       => $field->{strSalutation},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'details',
            },
            strFirstname => {
                label       => $FieldLabels->{'strFirstname'},
                value       => $field->{strFirstname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,

                #onChange   => 1,
            },
            strMiddlename => {
                label       => $FieldLabels->{'strMiddlename'},
                value       => $field->{strMiddlename},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',

                #onChange   => 1,
            },
            strSurname => {
                label       => $Data->{'SystemConfig'}{'strSurname_Text'} ? $Data->{'SystemConfig'}{'strSurname_Text'} : $FieldLabels->{'strSurname'},
                value       => $field->{strSurname},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
                first_page  => 1,

                #onChange   => 1,
            },
            strMaidenName => {
                label       => $FieldLabels->{'strMaidenName'},
                value       => $field->{strMaidenName},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
            },
            strPreferredName => {
                label       => $FieldLabels->{'strPreferredName'},
                value       => $field->{strPreferredName},
                type        => 'text',
                size        => '40',
                maxsize     => '50',
                sectionname => 'details',
            },
            dtDOB => {
                label       => $FieldLabels->{'dtDOB'},
                value       => $field->{dtDOB},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                sectionname => 'details',
                validate    => 'DATE',
                first_page  => 1,

                #onChange   => 1,
            },
            strPlaceofBirth => {
                label       => $FieldLabels->{'strPlaceofBirth'},
                value       => $field->{strPlaceofBirth},
                type        => 'text',
                size        => '30',
                maxsize     => '45',
                sectionname => 'details',
            },
            strCountryOfBirth => {
                label       => $FieldLabels->{'strCountryOfBirth'},
                value       => $field->{strCountryOfBirth},
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'other',
                firstoption => [ '', 'Select Country' ],
            },
            strMotherCountry => {
                label       => $FieldLabels->{'strMotherCountry'},
                value       => $field->{strMotherCountry},
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'details',
                firstoption => [ '', 'Select Country' ],
            },
            strFatherCountry => {
                label       => $FieldLabels->{'strFatherCountry'},
                value       => $field->{strFatherCountry},
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'details',
                firstoption => [ '', 'Select Country' ],
            },
            intGender => {
                label       => $FieldLabels->{'intGender'},
                value       => $field->{intGender},
                type        => 'lookup',
                options     => \%genderoptions,
                sectionname => 'details',
                firstoption => [ '', " " ],
                first_page  => 1,
            },

            strAddress1 => {
                label       => $FieldLabels->{'strAddress1'},
                value       => $field->{strAddress1},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strAddress2 => {
                label       => $FieldLabels->{'strAddress2'},
                value       => $field->{strAddress2},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strSuburb => {
                label       => $FieldLabels->{'strSuburb'},
                value       => $field->{strSuburb},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strState => {
                label       => $FieldLabels->{'strState'},
                value       => $field->{strState},
                type        => 'text',
                size        => '50',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strCityOfResidence => {
                label       => $FieldLabels->{'strCityOfResidence'},
                value       => $field->{strCityOfResidence},
                type        => 'text',
                size        => '30',
                maxsize     => '45',
                sectionname => 'contact',
            },
            strCountry => {
                label       => $FieldLabels->{'strCountry'},
                value       => $field->{strCountry} || ( $Data->{'SystemConfig'}{'AssocConfig'}{'useAssocCountry'} ? $assoc_obj->getValue('strCountry') : '' ),
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'contact',
                firstoption => [ '', 'Select Country' ],
            },
            strPostalCode => {
                label       => $FieldLabels->{'strPostalCode'},
                value       => $field->{strPostalCode},
                posttext    => $addressvalidation,
                type        => 'text',
                size        => '15',
                maxsize     => '15',
                sectionname => 'contact',
                script      => qq[
                    function onSelectionChange( event, ui ) {
                      event.preventDefault();
                      if (ui.item) {
                          jQuery('#l_strSuburb').val(ui.item.value.suburb);
                          jQuery('#l_strPostalCode').val(ui.item.value.postcode);
                          jQuery('#l_strState').val(ui.item.value.state);
                      }
                    }

                    jQuery(function() {
                      autocomplete_conf = {
                        source: function( request, response ) {
                          \$.ajax({
                            url: "ajax/aj_data_request.cgi",
                            dataType: "json",
                            data: {
                              client: "$client",
                              key: 'postcode',
                              maxRows: 12,
                              q: request.term
                            },
                            success: function( data ) {
                              response( \$.map( data.items, function( item ) {
                                return {
                                    label: item.postcode + ", " + item.suburb + ", " + item.state,
                                    value: item
                                }
                              }));
                            },
                          });
                        },
                        minLength: 3,
                        focus: onSelectionChange,
                        select: onSelectionChange,
                        open: function() {
                          jQuery( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
                        },
                        close: function() {
                          jQuery( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
                        }
                    };
                    jQuery( '#l_strSuburb' ).autocomplete( autocomplete_conf );
                    jQuery( '#l_strPostalCode' ).autocomplete( autocomplete_conf );
                    jQuery( '#l_strState' ).autocomplete( autocomplete_conf );
                    });
                ],
            },
            strPhoneHome => {
                label       => $FieldLabels->{'strPhoneHome'},
                value       => $field->{strPhoneHome},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strPhoneWork => {
                label       => $FieldLabels->{'strPhoneWork'},
                value       => $field->{strPhoneWork},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strPhoneMobile => {
                label       => $FieldLabels->{'strPhoneMobile'},
                value       => $field->{strPhoneMobile},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strPager => {
                label       => $FieldLabels->{'strPager'},
                value       => $field->{strPager},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strFax => {
                label       => $FieldLabels->{'strFax'},
                value       => $field->{strFax},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'contact',
            },
            strEmail => {
                label       => $FieldLabels->{'strEmail'},
                value       => $field->{strEmail},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'contact',
                validate    => 'EMAIL',
            },
            strEmail2 => {
                label       => $FieldLabels->{'strEmail2'},
                value       => $field->{strEmail2},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'contact',
                validate    => 'EMAIL',
            },
            intOccupationID => {
                label       => $FieldLabels->{'intOccupationID'},
                value       => $field->{intOccupationID},
                type        => 'lookup',
                options     => $DefCodes->{-9},
                order       => $DefCodesOrder->{-9},
                sectionname => 'other',
                firstoption => [ '', " " ],
            },
            intEthnicityID => {
                label       => $FieldLabels->{'intEthnicityID'},
                value       => $field->{intEthnicityID},
                type        => 'lookup',
                options     => $DefCodes->{-8},
                order       => $DefCodesOrder->{-8},
                sectionname => 'details',
                firstoption => [ '', " " ],
            },
            intMailingList => {
                label             => $FieldLabels->{'intMailingList'},
                value             => $field->{intMailingList},
                type              => 'checkbox',
                sectionname       => 'details',
                displaylookup     => { 1 => 'Yes', 0 => 'No' },
                default           => 1,
                SkipAddProcessing => 1,
            },
            intLifeMember => {
                label             => $FieldLabels->{'intLifeMember'},
                value             => $field->{intLifeMember},
                type              => 'checkbox',
                sectionname       => 'financial',
                default           => 0,
                displaylookup     => { 1 => 'Yes', 0 => 'No' },
                SkipAddProcessing => 1,
            },
            intDeceased => {
                label         => $FieldLabels->{'intDeceased'},
                value         => $field->{intDeceased},
                type          => 'checkbox',
                sectionname   => 'details',
                default       => 0,
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },
            strLoyaltyNumber => {
                label             => $FieldLabels->{'strLoyaltyNumber'},
                value             => $field->{strLoyaltyNumber},
                type              => 'text',
                size              => '20',
                maxsize           => '20',
                sectionname       => 'other',
                SkipAddProcessing => 1,
            },
            intFinancialActive => {
                label             => $FieldLabels->{'intFinancialActive'},
                value             => $field->{intFinancialActive},
                type              => 'checkbox',
                sectionname       => 'financial',
                default           => 0,
                displaylookup     => { 1 => 'Yes', 0 => 'No' },
                SkipAddProcessing => 1,
            },
            intMemberPackageID => {
                label             => $FieldLabels->{'intMemberPackageID'},
                value             => $field->{intMemberPackageID},
                type              => 'lookup',
                options           => $MemberPackages,
                sectionname       => 'financial',
                firstoption       => [ '', " " ],
                SkipAddProcessing => 1,
            },
            curMemberFinBal => {
                label             => $FieldLabels->{'curMemberFinBal'},
                value             => $field->{curMemberFinBal},
                type              => 'text',
                size              => '10',
                maxsize           => '10',
                sectionname       => 'financial',
                SkipAddProcessing => 1,
            },
            strPreferredLang => {
                label       => $FieldLabels->{'strPreferredLang'},
                value       => $field->{strPreferredLang},
                type        => 'text',
                size        => '20',
                maxsize     => '50',
                sectionname => 'identification',
            },
            strPassportIssueCountry => {
                label       => $FieldLabels->{'strPassportIssueCountry'},
                value       => uc( $field->{strPassportIssueCountry} ),
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'identification',
                firstoption => [ '', " " ],
            },
            strPassportNationality => {
                label       => $FieldLabels->{'strPassportNationality'},
                value       => uc( $field->{strPassportNationality} ),
                type        => 'lookup',
                options     => \%countriesonly,
                sectionname => 'identification',
                firstoption => [ '', " " ],
            },
            strPassportNo => {
                label       => $FieldLabels->{'strPassportNo'},
                value       => $field->{strPassportNo},
                type        => 'text',
                size        => '20',
                maxsize     => '50',
                sectionname => 'identification',
            },
            dtPassportExpiry => {
                label       => $FieldLabels->{'dtPassportExpiry'},
                value       => $field->{dtPassportExpiry},
                type        => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'identification',
                validate    => 'DATE',
            },
            strBirthCertNo => {
                label       => $FieldLabels->{'strBirthCertNo'},
                value       => $field->{strBirthCertNo},
                type        => 'text',
                size        => '20',
                maxsize     => '50',
                sectionname => 'identification',
            },
            strHealthCareNo => {
                label       => $FieldLabels->{'strHealthCareNo'},
                value       => $field->{strHealthCareNo},
                type        => 'text',
                size        => '20',
                maxsize     => '50',
                sectionname => 'identification',
            },
            intIdentTypeID => {
                label       => $FieldLabels->{'intIdentTypeID'},
                value       => $field->{intIdentTypeID},
                type        => 'lookup',
                options     => $DefCodes->{-31},
                order       => $DefCodesOrder->{-31},
                sectionname => 'identification',
                firstoption => [ '', " " ],
            },
            strIdentNum => {
                label => $Data->{'SystemConfig'}{'strIdentNum_Text'} ? $Data->{'SystemConfig'}{'strIdentNum_Text'} : $FieldLabels->{'strIdentNum'},
                value => $field->{strIdentNum},
                type  => 'text',
                size  => '20',
                maxsize     => '25',
                sectionname => 'identification',
            },
            dtPoliceCheck => {
                label => $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheck_Text'} : $FieldLabels->{'dtPoliceCheck'},
                value => $field->{dtPoliceCheck},
                type  => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'identification',
                validate    => 'DATE',
            },
            dtPoliceCheckExp => {
                label => $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} ? $Data->{'SystemConfig'}{'dtPoliceCheckExp_Text'} : $FieldLabels->{'dtPoliceCheckExp'},
                value => $field->{dtPoliceCheckExp},
                type  => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'identification',
                validate    => 'DATE',
            },
            strPoliceCheckRef => {
                label       => $FieldLabels->{'strPoliceCheckRef'},
                value       => $field->{strPoliceCheckRef},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'identification',
            },
            intFavStateTeamID => {
                label       => $FieldLabels->{'intFavStateTeamID'},
                value       => $field->{intFavStateTeamID},
                type        => 'lookup',
                options     => $DefCodes->{-33},
                order       => $DefCodesOrder->{-33},
                sectionname => 'other',
                firstoption => [ '', ' ' ],
            },
            intFavNationalTeamID => {
                label       => $FieldLabels->{'intFavNationalTeamID'},
                value       => $field->{intFavNationalTeamID},
                type        => 'lookup',
                options     => $DefCodes->{-34},
                order       => $DefCodesOrder->{-34},
                sectionname => 'other',
                firstoption => [ '', ' ' ],
            },
            intFavNationalTeamMember => {
                label         => $FieldLabels->{'intFavNationalTeamMember'},
                value         => $field->{intFavNationalTeamMember},
                type          => 'checkbox',
                sectionname   => 'other',
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },
            intAttendSportCount => {
                label       => $FieldLabels->{'intAttendSportCount'},
                value       => $field->{intAttendSportCount},
                type        => 'text',
                size        => '15',
                maxsize     => '15',
                validate    => 'NUMBER',
                sectionname => 'other',
            },
            intWatchSportHowOftenID => {
                label       => $FieldLabels->{'intWatchSportHowOftenID'},
                value       => $field->{intWatchSportHowOftenID},
                type        => 'lookup',
                options     => $DefCodes->{-1004},
                order       => $DefCodesOrder->{-1004},
                sectionname => 'other',
                firstoption => [ '', ' ' ],
            },
            strEmergContName => {
                label       => $FieldLabels->{'strEmergContName'},
                value       => $field->{strEmergContName},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strEmergContNo => {
                label       => $FieldLabels->{'strEmergContNo'},
                value       => $field->{strEmergContNo},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strEmergContNo2 => {
                label       => $FieldLabels->{'strEmergContNo2'},
                value       => $field->{strEmergContNo2},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strEmergContRel => {
                label       => $FieldLabels->{'strEmergContRel'},
                value       => $field->{strEmergContRel},
                type        => 'text',
                size        => '30',
                maxsize     => '100',
                sectionname => 'contact',
            },
            strP1Salutation => {
                label       => $FieldLabels->{'strP1Salutation'},
                value       => $field->{strP1Salutation},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP2Salutation => {
                label       => $FieldLabels->{'strP2Salutation'},
                value       => $field->{strP2Salutation},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            intP1Gender => {
                label       => $FieldLabels->{'intP1Gender'},
                value       => $field->{intP1Gender},
                type        => 'lookup',
                options     => \%genderoptions,
                sectionname => 'details',
                firstoption => [ '', " " ],
                sectionname => 'parent',
            },
            intP2Gender => {
                label       => $FieldLabels->{'intP2Gender'},
                value       => $field->{intP2Gender},
                type        => 'lookup',
                options     => \%genderoptions,
                sectionname => 'details',
                firstoption => [ '', " " ],
                sectionname => 'parent',
            },
            strP1FName => {
                label       => $FieldLabels->{'strP1FName'},
                value       => $field->{strP1FName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },
            strP1SName => {
                label       => $FieldLabels->{'strP1SName'},
                value       => $field->{strP1SName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },
            strP2FName => {
                label       => $FieldLabels->{'strP2FName'},
                value       => $field->{strP2FName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },
            strP2SName => {
                label       => $FieldLabels->{'strP2SName'},
                value       => $field->{strP2SName},
                type        => 'text',
                size        => '30',
                maxsize     => '50',
                sectionname => 'parent',
            },
            strP1Phone => {
                label       => $FieldLabels->{'strP1Phone'},
                value       => $field->{strP1Phone},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP2Phone => {
                label       => $FieldLabels->{'strP2Phone'},
                value       => $field->{strP2Phone},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP1Phone2 => {
                label       => $FieldLabels->{'strP1Phone2'},
                value       => $field->{strP1Phone2},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP2Phone2 => {
                label       => $FieldLabels->{'strP2Phone2'},
                value       => $field->{strP2Phone2},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP1PhoneMobile => {
                label       => $FieldLabels->{'strP1PhoneMobile'},
                value       => $field->{strP1PhoneMobile},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP2PhoneMobile => {
                label       => $FieldLabels->{'strP2PhoneMobile'},
                value       => $field->{strP2PhoneMobile},
                type        => 'text',
                size        => '20',
                maxsize     => '30',
                sectionname => 'parent',
            },
            strP1Email => {
                label       => $FieldLabels->{'strP1Email'},
                value       => $field->{strP1Email},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'parent',
                validate    => 'EMAIL',
            },
            strP2Email => {
                label       => $FieldLabels->{'strP2Email'},
                value       => $field->{strP2Email},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'parent',
                validate    => 'EMAIL',
            },
            strP1Email2 => {
                label       => $FieldLabels->{'strP1Email2'},
                value       => $field->{strP1Email2},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'parent',
                validate    => 'EMAIL',
            },
            strP2Email2 => {
                label       => $FieldLabels->{'strP2Email2'},
                value       => $field->{strP2Email2},
                type        => 'text',
                size        => '50',
                maxsize     => '200',
                sectionname => 'parent',
                validate    => 'EMAIL',
            },
            strEyeColour => {
                label       => $FieldLabels->{'strEyeColour'},
                value       => $field->{strEyeColour},
                type        => 'lookup',
                options     => $DefCodes->{-11},
                order       => $DefCodesOrder->{-11},
                sectionname => 'other',
                firstoption => [ '', " " ],
                sectionname => 'details',
            },
            strHairColour => {
                label       => $FieldLabels->{'strHairColour'},
                value       => $field->{strHairColour},
                type        => 'lookup',
                options     => $DefCodes->{-10},
                order       => $DefCodesOrder->{-10},
                sectionname => 'other',
                firstoption => [ '', " " ],
                sectionname => 'details',
            },
            strHeight => {
                label       => $FieldLabels->{'strHeight'},
                value       => $field->{strHeight},
                type        => 'text',
                size        => '5',
                maxsize     => '20',
                sectionname => 'details',
                format_txt  => 'cm',
            },
            strWeight => {
                label       => $FieldLabels->{'strWeight'},
                value       => $field->{strWeight},
                type        => 'text',
                size        => '5',
                maxsize     => '20',
                sectionname => 'details',
                format_txt  => 'kg',
            },

            dtFirstRegistered => {
                label => $Data->{'SystemConfig'}{'FirstRegistered_title'} ? $Data->{'SystemConfig'}{'FirstRegistered_title'} : $FieldLabels->{'dtFirstRegistered'},
                value => $field->{dtFirstRegistered},
                type  => 'date',
                format            => 'dd/mm/yyyy',
                sectionname       => 'other',
                validate          => 'DATE',
                SkipAddProcessing => 1,
            },
            dtLastRegistered => {
                label             => $FieldLabels->{'dtLastRegistered'},
                value             => $field->{dtLastRegistered},
                type              => 'date',
                format            => 'dd/mm/yyyy',
                sectionname       => 'other',
                validate          => 'DATE',
                SkipAddProcessing => 1,
            },
            dtRegisteredUntil => {
                label             => $FieldLabels->{'dtRegisteredUntil'},
                value             => $field->{dtRegisteredUntil},
                type              => 'date',
                format            => 'dd/mm/yyyy',
                sectionname       => 'other',
                SkipAddProcessing => 1,
                readonly          => ( $Data->{'Realm'} == 13 ) ? 0 : 1,
                auditField        => 1, 
            },
            dtLastUpdate => {
                label       => 'Last Updated',
                value       => $field->{tTimeStamp},
                type        => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'other',
                readonly    => 1,
            },
            dtCreatedOnline => {
                label       => 'Date Created Online',
                value       => $field->{dtCreatedOnline},
                type        => 'date',
                sectionname => 'other',
                noedit      => 1,
                readonly    => 1,
            },
            dtSuspendedUntil => {
                label       => $FieldLabels->{'dtSuspendedUntl'},
                value       => $field->{dtSuspendedUntil},
                type        => 'date',
                format      => 'dd/mm/yyyy',
                sectionname => 'other',
                readonly    => 1,
            },
            strNotes => {
                label             => $FieldLabels->{'strNotes'},
                value             => $field->{strMemberNotes},
                type              => 'textarea',
                sectionname       => 'other',
                rows              => 5,
                cols              => 45,
                SkipAddProcessing => 1,
                SkipProcessing    => 1,
            },
            intHowFoundOutID => {
                label       => $FieldLabels->{intHowFoundOutID},
                value       => $field->{intHowFoundOutID},
                type        => 'lookup',
                options     => $DefCodes->{-1001},
                order       => $DefCodesOrder->{-1001},
                firstoption => [ '', " " ],
                sectionname => 'other',
            },
            intP1AssistAreaID => {
                label       => $FieldLabels->{intP1AssistAreaID},
                value       => $field->{intP1AssistAreaID},
                type        => 'lookup',
                options     => $DefCodes->{-1002},
                order       => $DefCodesOrder->{-1002},
                firstoption => [ '', " " ],
                sectionname => 'parent',
            },
            intP2AssistAreaID => {
                label       => $FieldLabels->{intP2AssistAreaID},
                value       => $field->{intP2AssistAreaID},
                type        => 'lookup',
                options     => $DefCodes->{-1002},
                order       => $DefCodesOrder->{-1002},
                firstoption => [ '', " " ],
                sectionname => 'parent',
            },
            intMedicalConditions => {
                label         => $FieldLabels->{'intMedicalConditions'},
                value         => $field->{intMedicalConditions},
                type          => 'checkbox',
                sectionname   => 'medical',
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },
            intAllergies => {
                label         => $FieldLabels->{'intAllergies'},
                value         => $field->{intAllergies},
                type          => 'checkbox',
                sectionname   => 'medical',
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },
            intAllowMedicalTreatment => {
                label         => $FieldLabels->{'intAllowMedicalTreatment'},
                value         => $field->{intAllowMedicalTreatment},
                type          => 'checkbox',
                sectionname   => 'medical',
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },
            strMedicalNotes => {
                label             => $FieldLabels->{'strMedicalNotes'},
                value             => $field->{strMemberMedicalNotes},
                type              => 'textarea',
                sectionname       => 'medical',
                rows              => 5,
                cols              => 45,
                SkipAddProcessing => 1,
                SkipProcessing    => 1,
            },
            strSchoolName => {
                label => $Data->{'SystemConfig'}{'Schools'} ? $FieldLabels->{'strSchoolName'} : '',
                value => $field->{strSchoolName},
                type  => 'text',
                size  => '40',
                sectionname    => 'other',
                disabled       => 1,
                SkipProcessing => 1,
            },
            strSchoolSuburb => {
                label => $Data->{'SystemConfig'}{'Schools'} ? $FieldLabels->{'strSchoolSuburb'} : '',
                value => $field->{strSchoolSuburb},
                type  => 'text',
                size  => '30',
                sectionname    => 'other',
                disabled       => 1,
                SkipProcessing => 1,
            },
            intSchoolID => {
                label => $Data->{'SystemConfig'}{'Schools'} ? $FieldLabels->{'intSchoolID'} : '',
                value => $field->{intSchoolID},
                type  => 'hidden',

                pretext =>
                q[<input type="button" onclick="document.getElementById('schoolframe').style.display='block';this.style.display='none';" value="Select School" style='background-image: none; background-color:#F0F0F0;' id="schoolsearchbtn">XXXCOMPULSORYICONXXX<iframe src="schools.cgi?fn=m_form&amp;anchorid=d_intSchoolID&amp;anchorname=d_strSchoolName&amp;anchorsuburb=d_strSchoolSuburb&amp;srealm=]
                . $Data->{'SystemConfig'}{'Schools'}
                . q[" frameborder=0 style="margin-left:20px;margin-top:10px;height:270px;width:488px;border:0px;display:none;" name="schoolframe" id="schoolframe"></iframe>],

                sectionname => 'other',
                disabled    => 1,
                nodisplay   => 1,
            },
            intGradeID => {    #School Grades
                label       => $FieldLabels->{intGradeID},
                value       => $field->{intGradeID},
                type        => 'lookup',
                options     => \%SchoolGrades,
                order       => \@SchoolGradesOrder,
                firstoption => [ '', " " ],
                sectionname => 'other',
            },
            intConsentSignatureSighted => {
                label => $Data->{'SystemConfig'}{'SignatureSightedText'} ? $Data->{'SystemConfig'}{'SignatureSightedText'} : $FieldLabels->{'intConsentSignatureSighted'},
                value => $field->{intConsentSignatureSighted},
                type  => 'checkbox',
                sectionname   => 'other',
                displaylookup => { 1 => 'Yes', 0 => 'No' },
            },

            intDeRegister=> {
                label => ($Data->{'SystemConfig'}{'AllowDeRegister'} ? "DeRegister Player" : ''),
                value => $field->{intDeRegister},
                type  => 'checkbox',
                sectionname => 'details',
                displaylookup => {1 => 'Yes', 0 => 'No'},
                readonly=>($Data->{'clientValues'}{'authLevel'}<=$Defs::LEVEL_REGION and $Data->{'SystemConfig'}{'AllowDeRegister'} ? 1 : 0),
            },
            intPhotoUseApproval => {
                label       => $FieldLabels->{intPhotoUseApproval},
                value       => $field->{intPhotoUseApproval},
                type        => 'lookup',
                sectionname => 'other',
                options     => { 1 => 'Yes', 0 => 'No' },
                order     => \@reverseYNOrder,
            },
            PhotoUpload => {
                label => 'Photo',
                type  => 'htmlblock',
                value => q[
                <div id="photoupload_result">] . $photolink . q[</div>
                <div id="photoupload_form"></div>
                <input type="button" value = " Upload Photo " id = "photoupload" class="button generic-button">
                <input type="hidden" name = "d_PhotoUpload" value = "] . ( $photolink ? 'valid' : '' ) . q[">
                <script>
                jQuery('#photoupload').click(function() {
                        jQuery('#photoupload_form').html('<iframe src="regoformphoto.cgi?client=] . $client . $hideWebCamTab . q[" style="width:750px;height:650px;border:0px;"></iframe>');
                        jQuery('#photoupload_form').dialog({
                                width: 800,
                                height: 700,
                                modal: true,
                                title: 'Upload Photo'
                            });
                    });
                </script>
                ],
                SkipAddProcessing => 1,
                SkipProcessing    => 1,
            },
            SPident   => { type => '_SPACE_', sectionname => 'citizenship' },
            SPcontact => { type => '_SPACE_', sectionname => 'contact' },
            SPdetails => { type => '_SPACE_', sectionname => 'details' },

            ($Data->{'SystemConfig'}{'EnableMemberRecords'}) ? (
                MemberRecordTypeList => {
                    label => 'Member Record Type',
                    type => 'lookup',
                    options => get_mrt_select_options($Data),
                    (not $mrt_config->{'OneRolePerMember'}) ? (
                        multiple => 1,
                        size => 5,
                    ) : (),
                    sectionname => 'records',
                    SkipProcessing => 1,
                    visible_for_edit => 0,
                }
            ) : (
                intPlayer => {
                    label       => $FieldLabels->{'intPlayer'},
                    OLDlabel    => !$memberID ? $FieldLabels->{'intPlayer'} : '',
                    value       => $field->{intPlayer},
                    type        => 'checkbox',
                    sectionname => 'interests',
                    oldreadonly => ( $option eq 'add' ) ? 0 : 1,
                    first_page  => 1,

                    default => $Data->{'SystemConfig'}{'NoPlayerDefault'} ? 0 : 1,

                    readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1,

                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                },
                intCoach => {
                    label         => $FieldLabels->{'intCoach'},
                    value         => $field->{intCoach},
                    type          => 'checkbox',
                    sectionname   => 'interests',
                    oldreadonly   => ( $option eq 'add' ) ? 0 : 1,
                    first_page    => 1,
                    displaylookup => { 1 => 'Yes', 0 => 'No' },

                    readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1,
                },
                intUmpire => {
                    label         => $FieldLabels->{'intUmpire'},
                    value         => $field->{intUmpire},
                    type          => 'checkbox',
                    sectionname   => 'interests',
                    oldreadonly   => ( $option eq 'add' ) ? 0 : 1,
                    first_page    => 1,
                    displaylookup => { 1 => 'Yes', 0 => 'No' },

                    readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1,
                },
                intOfficial => {
                    label         => $FieldLabels->{'intOfficial'},
                    value         => $field->{intOfficial},
                    type          => 'checkbox',
                    sectionname   => 'interests',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    first_page    => 1,

                   readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1, 
                },
                intMisc => {
                    label         => $FieldLabels->{'intMisc'},
                    value         => $field->{intMisc},
                    type          => 'checkbox',
                    sectionname   => 'interests',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    first_page    => 1,

                    readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1, 
                },
                intVolunteer => {
                    label         => $FieldLabels->{'intVolunteer'},
                    value         => $field->{intVolunteer},
                    type          => 'checkbox',
                    sectionname   => 'interests',
                    displaylookup => { 1 => 'Yes', 0 => 'No' },
                    first_page    => 1,

                    readonly => ( $option eq 'add' or !$assocSeasons->{'allowSeasons'} or $Data->{'RegoFormID'} ) ? 0 : 1, 
                }
            ),
        },
        order => [
        qw(strNationalNum strMemberNo intRecStatus intDefaulter strSalutation strFirstname strPreferredName strMiddlename strSurname strMaidenName dtDOB strPlaceofBirth strCountryOfBirth strMotherCountry strFatherCountry intGender strAddress1 strAddress2 strSuburb strCityOfResidence strState strPostalCode strCountry strPhoneHome strPhoneWork strPhoneMobile strPager strFax strEmail strEmail2 SPcontact intOccupationID intDeceased intDeRegister intPhotoUseApproval strLoyaltyNumber intMailingList intFinancialActive intMemberPackageID curMemberFinBal intLifeMember strPreferredLang strPassportIssueCountry strPassportNationality strPassportNo dtPassportExpiry strBirthCertNo strHealthCareNo intIdentTypeID strIdentNum dtPoliceCheck dtPoliceCheckExp strPoliceCheckRef intPlayer intCoach intUmpire intOfficial intMisc intVolunteer strEmergContName strEmergContNo strEmergContNo2 strEmergContRel strP1Salutation strP1FName strP1SName intP1Gender strP1Phone strP1Phone2 strP1PhoneMobile strP1Email strP1Email2 intP1AssistAreaID strP2Salutation strP2FName strP2SName intP2Gender strP2Phone strP2Phone2 strP2PhoneMobile strP2Email strP2Email2 intP2AssistAreaID strEyeColour strHairColour intEthnicityID strHeight strWeight MemberRecordTypeList
        ),

        map("strNatCustomStr$_", (1..15)),
        map("dblNatCustomDbl$_", (1..10)),
        map("dtNatCustomDt$_", (1..5)),
        map("intNatCustomLU$_", (1..10)),
        map("intNatCustomBool$_", (1..5)),

        map("strCustomStr$_", (1..25)),
        map("dblCustomDbl$_", (1..20)),
        map("dtCustomDt$_", (1..15)),
        map("intCustomLU$_", (1..25)),
        map("intCustomBool$_", (1..7)),
        map("strMemberCustomNotes$_", (1..5)),

        qw(
        intSchoolID strSchoolName strSchoolSuburb intGradeID
        intFavStateTeamID intFavNationalTeamID strNotes SPdetails dtFirstRegistered dtLastRegistered dtRegisteredUntil dtLastUpdate dtCreatedOnline
        intHowFoundOutID
        intMedicalConditions
        intAllergies
        intAllowMedicalTreatment
        strMedicalNotes
        intConsentSignatureSighted intAttendSportCount intWatchSportHowOftenID intFavNationalTeamMember
        )
        ],
        fieldtransform => {
            textcase => {
                strFirstname => $field_case_rules->{'strFirstname'} || '',
                strSurname   => $field_case_rules->{'strSurname'}   || '',
                strSuburb    => $field_case_rules->{'strSuburb'}    || '',
            }
        },
        sections => [
        [ 'regoform',       q{} ],
        [ 'interests',      $interestHeader],
        [ 'details',        'Personal Details' ],
        [ 'contact',        'Contact Details' ],
        [ 'identification', 'Identification' ],
        [ 'profile',        'Profile' ],
        [ 'contracts',      'Contracts' ],
        [ 'citizenship',    'Citizenship' ],
        [ 'parent',         'Parent/Guardian' ],
        [ 'financial',      'Financial' ],
        [ 'medical',        'Medical' ],
        [ 'jumpers',        $Data->{'SystemConfig'}{'Custom_JumperNumber'} ? $Data->{'SystemConfig'}{'Custom_JumperNumber'} : 'Jumper Numbers'], 
        [ 'custom1',        $Data->{'SystemConfig'}{'MF_CustomGroup1'} ],
        [ 'other',          'Other Details' ],
        [ 'records',        'Initial Member Records' ],
        ],
        options => {
            labelsuffix          => ':',
            hideblank            => 1,
            target               => $Data->{'target'},
            formname             => 'm_form',
            submitlabel          => $Data->{'lang'}->txt( 'Update ' . $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} ),
            introtext            => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
            buttonloc            => $Data->{'SystemConfig'}{'HTMLFORM_ButtonLocation'} || 'both',
            OptionAfterProcessed => 'display',
            updateSQL            => qq[
            UPDATE tblMember, tblMember_Associations
            SET --VAL--
            WHERE tblMember.intMemberID=$memberID
                AND tblMember_Associations.intMemberID=$memberID
                AND tblMember_Associations.intAssocID=$Data->{'clientValues'}{'assocID'}
            ],
            addSQL => qq[
            INSERT INTO tblMember (intRealmID, dtCreatedOnline, --FIELDS--)
            VALUES ($Data->{'Realm'}, CURRENT_DATE(), --VAL--)
            ],
            NoHTML               => 1,
            afterupdateFunction  => \&postMemberUpdate,
            afterupdateParams    => [ $option, $Data, $Data->{'db'}, $memberID, $field ],
            afteraddFunction     => \&postMemberUpdate,
            afteraddParams       => [ $option, $Data, $Data->{'db'} ],
            beforeaddFunction    => \&preMemberAdd,
            beforeaddParams      => [ $option, $Data, $Data->{'db'} ],
            afteraddAction       => 'edit',

            auditFunction  => \&auditLog,
            auditAddParams => [
            $Data,
            'Add',
            'Member'
            ],
            auditEditParams => [
            $memberID,
            $Data,
            'Update',
            'Member',
            ],
            auditEditParamsAddFields => 1,

            LocaleMakeText        => $Data->{'lang'},
            pre_button_bottomtext => $Data->{'SystemConfig'}{'MemberFooterText'} || '',
        },
        carryfields => {
            client => $client,
            a      => $action,
        },
    );


    ######################################################
    # generate custom fileds definitions
    ######################################################

    # map("strNatCustomStr$_", (1..15)),
    for my $i (1..15) {
        my $fieldname = "strNatCustomStr$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'text',
            size  => '30',
            maxsize     => '50',
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("dblNatCustomDbl$_", (1..10)),
    for my $i (1..10) {
        my $fieldname = "dblNatCustomDbl$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'text',
            size  => '10',
            maxsize     => '15',
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("dtNatCustomDt$_", (1..5)),
    for my $i (1..5) {
        my $fieldname = "dtNatCustomDt$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'date',
            format      => 'dd/mm/yyyy',
            sectionname => 'other',
            validate    => 'DATE',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("intNatCustomLU$_", (1..10)),
    my @intNatCustomLU_DefsCodes = (undef, -53, -54, -55, -64, -65, -66, -67, -68,-69,-70);
    for my $i (1..10) {
        my $fieldname = "intNatCustomLU$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'lookup',
            options     => $DefCodes->{$intNatCustomLU_DefsCodes[$i]},
            order       => $DefCodesOrder->{$intNatCustomLU_DefsCodes[$i]},
            firstoption => [ '', " " ],
            sectionname => 'other',
            readonly    => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("intNatCustomBool$_", (1..5)),
    for my $i (1..5) {
        my $fieldname = "intNatCustomBool$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label => $CustomFieldNames->{$fieldname}[0] || '',
            value => $field->{$fieldname},
            type  => 'checkbox',
            sectionname   => 'other',
            displaylookup => { 1 => 'Yes', 0 => 'No' },
            readonly      => ( $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL and $Data->{'SystemConfig'}{"NationalOnly_$fieldname"} ? 1 : 0 ),
        };
    }

    # map("strCustomStr$_", (1..25)),
    for my $i (1..25) {
        my $fieldname = "strCustomStr$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0],
            value             => $field->{$fieldname},
            type              => 'text',
            size              => '30',
            maxsize           => '50',
            sectionname       => 'other',
            SkipAddProcessing => 1,
        };
    }
    $FieldDefinitions{'fields'}{'strCustomStr16'}{'size'} = 50;
    $FieldDefinitions{'fields'}{'strCustomStr16'}{'maxsize'} = 200;

    # map("dblCustomDbl$_", (1..20)),
    for my $i (1..20) {
        my $fieldname = "dblCustomDbl$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0],
            value             => $field->{$fieldname},
            type              => 'text',
            size              => '10',
            maxsize           => '15',
            sectionname       => 'other',
            SkipAddProcessing => 1,
        };
    }

    # map("dtCustomDt$_", (1..15)),
    for my $i (1..15) {
        my $fieldname = "dtCustomDt$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0],
            value             => $field->{$fieldname},
            type              => 'date',
            format            => 'dd/mm/yyyy',
            sectionname       => 'other',
            validate          => 'DATE',
            SkipAddProcessing => 1,
        };
    }

    # map("intCustomLU$_", (1..25)),
    my @intCustomLU_DefCodes = (undef, -50, -51, -52, -57, -58, -59, -60, -61, 
        -62, -63, -97, -98, -99, -100, -101, -102, -103, -104, -105, -106, 
        -107, -108, -109, -110, -111);
    for my $i (1..25) {
        my $fieldname = "intCustomLU$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0],
            value             => $field->{$fieldname},
            type              => 'lookup',
            options           => $DefCodes->{$intCustomLU_DefCodes[$i]},
            order             => $DefCodesOrder->{$intCustomLU_DefCodes[$i]},
            firstoption       => [ '', " " ],
            sectionname       => 'other',
            SkipAddProcessing => 1,
        };
    }

    # map("intCustomBool$_", (1..7)),
    for my $i (1..7) {
        my $fieldname = "intCustomBool$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0] || '',
            value             => $field->{$fieldname},
            type              => 'checkbox',
            sectionname       => 'other',
            displaylookup     => { 1 => 'Yes', 0 => 'No' },
            SkipAddProcessing => 1,
        };
    }

    # map("strMemberCustomNotes$_", (1..5)),
    for my $i (1..5) {
        my $fieldname = "strMemberCustomNotes$i";
        $FieldDefinitions{'fields'}{$fieldname} = {
            label             => $CustomFieldNames->{$fieldname}[0],
            value             => $field->{$fieldname},
            type              => 'textarea',
            sectionname       => 'other',
            rows              => 5,
            cols              => 45,
            SkipAddProcessing => 1,
            SkipProcessing    => 1,
        };
    }

    # Jumper number stuff
    if ($Data->{'SystemConfig'}{'AssocConfig'}{'AllowJumperNumberOnMembersEdit'} && $memberID){    
        # If Assoc level, then all clubs in Assoc
        # If at club, then get active teams in the club for this player
        # If team, then only show team default for that team only (maybe read only for club?)
        my $current_level = $Data->{'clientValues'}{'authLevel'};
        my $assocID = $Data->{'clientValues'}{'assocID'};
        my $clubID = $Data->{'clientValues'}{'clubID'};
        my $teamID = $Data->{'clientValues'}{'teamID'};
    
        my $db = $Data->{'db'};
        
        # Search for all clubs and teams they may be in
        my $team_search_sql = qq[
            SELECT
                a.intAssocID,
                a.intCurrentSeasonID,
                a.intNewRegoSeasonID,
                ac.intCompID,
                ac.strTitle,
                ac.intNewSeasonID,
                mt.intMemberID,
                t.intClubID,
                t.intTeamID,
                t.strName,
                s.strSeasonName
            FROM
                tblAssoc as a
                INNER JOIN tblAssoc_Comp as ac on (
                    a.intAssocID = ac.intAssocID
                    AND ac.intNewSeasonID in (a.intCurrentSeasonID, a.intNewRegoSeasonID) 
                )
                INNER JOIN tblMember_Teams as mt on (
                    ac.intCompID = mt.intCompID
                ) 
                LEFT JOIN tblTeam as t on (
                    mt.intTeamID = t.intTeamID
                    AND t.intRecStatus > 0
                )
                LEFT JOIN tblSeasons as s on (
                    ac.intNewSeasonID = s.intSeasonID
                )
            WHERE
                a.intAssocID = ?
                AND mt.intMemberID = ?
        ];
        
        my $club_search_sql = qq[
            SELECT
                a.intAssocID,
                a.intCurrentSeasonID,
                a.intNewRegoSeasonID,
                ac.intClubID,
                mc.intMemberID,
                c.intClubID,
                c.strName
            FROM
                tblAssoc as a
                INNER JOIN tblAssoc_Clubs as ac on (
                    a.intAssocID = ac.intAssocID
                )
                INNER JOIN tblMember_Clubs as mc on (
                    ac.intClubID = mc.intClubID
                ) 
                LEFT JOIN tblClub as c on (
                    mc.intClubID = c.intClubID
                    AND c.intRecStatus > 0
                )
            WHERE
                a.intAssocID = ?
                AND mc.intMemberID = ?;
        ];
        
        my $team_search_stmt = $db->prepare($team_search_sql);
        my $club_search_stmt = $db->prepare($club_search_sql);
        
        $team_search_stmt->execute($assocID, $memberID);
        $club_search_stmt->execute($assocID, $memberID);
            
        my $clubs_and_teams_map;
        
        TEAM: while (my $row = $team_search_stmt->fetchrow_hashref()){
            my $intClubID = $row->{'intClubID'} || 0;
            
            if($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_TEAM){
                next TEAM;
            }
            elsif ( $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_TEAM && $row->{'intTeamID'} != $teamID ){
                next TEAM;
            }
            elsif ( $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB && $intClubID != $clubID ){
                next TEAM;
            }
            
            $clubs_and_teams_map->{'clubs'}->{$intClubID}->{'teams'}->{$row->{'intTeamID'}}->{'name'} = $row->{'strName'};
            
            # If we want to sub sort by seasons, we can store that info as well
            #$clubs_and_teams_map->{'clubs'}->{$intClubID}->{'seasons'}->{$row->{'intNewSeasonID'}}->{'teams'}->{$row->{'intTeamID'}}->{'name'} = $row->{'strName'};
            #$clubs_and_teams_map->{'clubs'}->{$intClubID}->{'seasons'}->{$row->{'intNewSeasonID'}}->{'name'} = $row->{'strSeasonName'};
        }
        
        CLUB: while (my $row = $club_search_stmt->fetchrow_hashref()){
            if($Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_TEAM){
                next CLUB;
            }
            elsif ( $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_TEAM && !defined $clubs_and_teams_map->{'clubs'}->{$row->{'intClubID'}} ){
                next CLUB;
            }
            elsif ( $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB && $row->{'intClubID'} != $clubID ){
                next CLUB;
            }
            
            $clubs_and_teams_map->{'clubs'}->{$row->{'intClubID'}}->{'name'} = $row->{'strName'};
            
        }
        
        my $order = 0;
        my $jumper_label = $Data->{'SystemConfig'}{'Custom_JumperNumber'} ? $Data->{'SystemConfig'}{'Custom_JumperNumber'} : 'Number';
        
        # Loop over the clubs and teams
        foreach my $club (keys %{$clubs_and_teams_map->{'clubs'}}){
            my $club_default = ''; # Club default 
            
            # Fetch all defaults for this club
            my $player_numbers_refs = get_player_number({
                'dbh' => $db,
                'club_id' => $club,
                'assoc_id' => $assocID,
                'member_id' => $memberID,
                'return_all_teams' => 1,
            });
            
            # Only for legit clubs (some teams are clubless)
            if ( $club && $club > 0 ){
                # get club default number
                $club_default = $player_numbers_refs->{-1}->{'strJumperNum'}; # Keyed by team, so -1 (no team) for club default
                
                # Need to protect valid 0 values
                if (!defined $club_default){
                    $club_default = '';
                }
    
                # Club Header
                $FieldDefinitions{'fields'}{"PlayerNumberClub_header_$order"} = {
                    label             => $clubs_and_teams_map->{'clubs'}->{$club}->{'name'} || '',
                    value             => '',
                    type              => 'header',
                    order             => $order,
                    sectionname       => 'jumpers',
                    neverHideBlank    => 1,
                    SkipAddProcessing => 1,                
                };
                push @{$FieldDefinitions{'order'}}, "PlayerNumberClub_header_$order";
                $order++;
                
                # Club default
                $FieldDefinitions{'fields'}{'PlayerNumberClub_' . $assocID . '_' . $club . '_-1_' . $memberID . '_' . $order} = {
                    label             => "Default $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} $jumper_label"|| '',
                    value             => $club_default,
                    type              => 'jumper', 
                    order             => $order,
                    sectionname       => 'jumpers',
                    neverHideBlank    => 1,
                    SkipAddProcessing => 1,
                    title             => 'Number between 0 and 99',
                };
                push @{$FieldDefinitions{'order'}}, 'PlayerNumberClub_' . $assocID . '_' . $club . '_-1_' . $memberID . '_' . $order;
                $order++;
                
            }
    
            foreach my $team ( keys %{$clubs_and_teams_map->{'clubs'}->{$club}->{'teams'}} ){
                # get team default number
                my $team_default = $player_numbers_refs->{$team}->{'strJumperNum'}; 
                
                # Need to protect valid 0 values
                if (!defined $team_default){
                    $team_default = '';
                }
                
                my $team_name = $clubs_and_teams_map->{'clubs'}->{$club}->{'teams'}->{$team}->{'name'} || 'Unnamed Team';
                
                # Club default
                $FieldDefinitions{'fields'}{'PlayerNumberTeam_' . $assocID . '_' . $club . '_' . $team . '_' . $memberID . '_' . $order} = {
                    label             => $team_name . ' default ' . $jumper_label, 
                    value             => $team_default, 
                    type              => 'jumper', 
                    order             => $order,
                    sectionname       => 'jumpers',
                    neverHideBlank    => 1,
                    SkipAddProcessing => 1,
                    placeholder       => $club_default,
                    title             => 'Number between 0 and 99',
                    
                };
                push @{$FieldDefinitions{'order'}}, 'PlayerNumberTeam_' . $assocID . '_' . $club . '_' . $team . '_' . $memberID . '_' . $order;
                $order++;
            }
        }
    }

    my $resultHTML = '';
    my $fieldperms = $Data->{'Permissions'};

    my $memperm = ProcessPermissions($fieldperms, \%FieldDefinitions, 'Member',);

    if ( $Data->{'SystemConfig'}{'Schools'} and $memperm->{'intSchoolID'} ) {
        $memperm->{'strSchoolName'}   = 1;
        $memperm->{'strSchoolSuburb'} = 1;
    }
    if($Data->{'SystemConfig'}{'AllowDeRegister'}) {
        $memperm->{'intDeRegister'}=1;
    }

    my %configchanges = ();
    if ( $Data->{'SystemConfig'}{'MemberFormReLayout'} ) {
        %configchanges = eval( $Data->{'SystemConfig'}{'MemberFormReLayout'} );
    }

    return \%FieldDefinitions if $Data->{'RegoForm'};
    return ( \%FieldDefinitions, $memperm ) if $returndata;
    my $processed = 0;
    my $header ='';
    my $tabs = '';
    ( $resultHTML, $processed, $header, $tabs ) = handleHTMLForm( \%FieldDefinitions, $memperm, $option, '', $Data->{'db'}, \%configchanges );

    if ($option ne 'display') {
        $resultHTML .= '';
    }
$tabs = '
<div class="new_tabs_wrap">
<ul class="new_tabs">
  '.$tabs.'
</ul>
	<span class="showallwrap"><a href="#showall" class="showall">Show All</a></span>
</div>
								';
my $member_photo = qq[
        <div class="member-edit-info">
<div class="photo">$photolink</div>
        <span class="button-small mobile-button"><a href="?client='.$client.'&amp;a=M_PH_d">Add/Edit Photo</a></span>
        <h4>Documents</h4>
        <span class="button-small generic-button"><a href="?client='.$client.'&amp;a=DOC_L">Add Document</a></span>
      </div>
];
$member_photo = '' if($option eq 'add');
$tabs = '' if($option eq 'add');
	$resultHTML =qq[
 $tabs 
$member_photo
      <div class="member-edit-form">$resultHTML</div><style type="text/css">.pageHeading{font-size:48px;font-family:"DINMedium",sans-serif;letter-spacing:-2px;margin:40px 0;}.ad_heading{margin: 36px 0 0 0;}</style>] if!$processed;
    $resultHTML = qq[<p>$Data->{'MemberClrdOut'}</p> $resultHTML] if $Data->{'MemberClrdOut'};
    $option = 'display' if $processed;
    my $chgoptions = '';
    my $title = ( !$field->{strFirstname} and !$field->{strSurname} ) ? "Add New $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}" : "$field->{strFirstname} $field->{strSurname}";
    if ( $option eq 'display' ) {

        $chgoptions .= qq[<a href="$Data->{'target'}?client=$client&amp;a=M_DEL"  onclick="return confirm('Are you sure you want to Delete this $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}');"><img src="images/delete_icon.gif" border="0" alt="Delete $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}" title="Delete $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}"></a>]
          if ( allowedAction( $Data, 'm_d' ) and $Data->{'SystemConfig'}{'AllowMemberDelete'} );

        $chgoptions = '' if $Data->{'SystemConfig'}{'LockMember'};

        $chgoptions = qq[<div class="changeoptions">$chgoptions</div>] if $chgoptions;

        $resultHTML = $resultHTML;

        my @taboptions = ();
        my @tabdata    = ();
        my ( $clubStatus, $clubs, $teams ) = showClubTeams( $Data, $memberID );
        $clubs ||= '';
        $teams ||= '';
        push @taboptions, [ 'memclubs_dat', $Data->{'LevelNames'}{ $Defs::LEVEL_CLUB . "_P" } ] if $clubs;
        push @taboptions, [ 'memteams_dat', $Data->{'LevelNames'}{ $Defs::LEVEL_TEAM . "_P" } ] if $teams;
        push @tabdata, qq[<div id="memclubs_dat">$clubs</div>] if $clubs;
        push @tabdata, qq[<div id="memteams_dat">$teams</div>] if $teams;

        my ( $memseason_vals, $memseasons ) = listMemberSeasons( $Data, $memberID );
        if ($memseasons) {
            for my $i ( @{$memseason_vals} ) {
                push @tabdata, $i;
            }
            my $season_Name = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
            my $seasonSummary = $Data->{'SystemConfig'}{'txtSeasonSummary'} ? $Data->{'SystemConfig'}{'txtSeasonSummary'} : qq[Full $season_Name Summary];

            push @taboptions, [ 'assocseason_dat', $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} . " Summary" ];
            push @taboptions, [ 'clubseason_dat',  $Data->{'LevelNames'}{$Defs::LEVEL_CLUB} . " Summary" ];
            push @taboptions, [ 'allseason_dat',   $seasonSummary ];
        }

        if ( $clubStatus == $Defs::RECSTATUS_INACTIVE and $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_CLUB ) {
            $chgoptions = '';
            $title .= " - <b><i>Restricted Access</i></b> ";
        }

        $title = $chgoptions . $title;
        $title .= " - ON PERMIT " if $Data->{'MemberOnPermit'};

        my $otherassocs = checkOtherAssocs( $Data, $memberID ) || '';
        if ($otherassocs) {
            push @tabdata, qq[<div id="otherassocs_dat">$otherassocs</div>];
            push @taboptions, [ 'otherassocs_dat', 'Associations' ];
        }
        my $clearancehistory = clearanceHistory( $Data, $memberID ) || '';
        if ($clearancehistory) {
            push @tabdata, qq[<div id="clearancehistory_dat">$clearancehistory</div>];
            my $txt_Clr = $Data->{'SystemConfig'}{'txtCLR'} || 'Clearance';
            push @taboptions, [ 'clearancehistory_dat', "$txt_Clr History" ];
        }
        my $memhistory = '';
        if ( $Data->{'SystemConfig'}{'showOldMemberHistory'} ) {
            $memhistory = getMemberHistory( $Data, $memberID );
        }
        if ($memhistory) {
            push @tabdata, qq[<div id="memhistory_dat">$memhistory</div>];
            push @taboptions, [ 'memhistory_dat', 'Member History' ];
        }

        #$resultHTML .= loadMemberExpiry($Data->{'db'},$memberID) if $Data->{'SystemConfig'}{'DisplayContractExpiry'};

        my $tabstr    = '';
        my $tabheader = '';

        #for my $i (0 .. $#taboptions)	{
        #	#$tabstr .= qq{<h3><a href = "#">$taboptions[$i][1]</a></h3>};
        #	$tabheader.= qq{<li><a href = "#$taboptions[$i][0]">$taboptions[$i][1]</a></li>};
        #	$tabstr .= $tabdata[$i] ? $tabdata[$i] : '<div></div>';
        #}
        $tabheader = qq[<ul>$tabheader</ul>] if $tabheader;
	if ($tabstr) {
            $Data->{'AddToPage'}->add( 'js_bottom', 'inline', "jQuery('#membertabs').tabs();" );

            $resultHTML .= qq[
				<div class = "small-widget-text">
				<div id="membertabs" style="float:left;clear:right;width:99%;">
					$tabheader
					$tabstr
				</div><!-- end membertabs -->
				</div>
			];
        }

        my $defaulterstatus = defaulter_check( $memberID, $Data->{'SystemConfig'}{'Defaulter'}, $Data );

        my $inSeason     = 0;
        my $SeasonStatus = 0;
        ( $inSeason, $SeasonStatus ) = Seasons::isMemberInSeason( $Data, $memberID, $Data->{'clientValues'}{'assocID'}, $Data->{'clientValues'}{'clubID'}, $assocSeasons->{'newRegoSeasonID'} );

        if (
             (
                  !$Data->{'SystemConfig'}{'memberReReg_notInactive'}
               or ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC and $Data->{'clientValues'}{'clubID'} eq $Defs::INVALID_ID )
               or ( $Data->{'MemberActiveInClub'} and !$Data->{'MemberClrdOut_ofClub'} )
             )
             and $SeasonStatus < 1
             and (allowedAction( $Data, 'm_a' ) or allowedAction( $Data, 'm_e' ) )
          )
        {
            my $txt_Name = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
            my $action = $Data->{'clientValues'}{'clubID'} > 0 ? 'SN_MSviewCADD' : 'SN_MSviewADD';
            my $clubHidden = '';
            if ( $Data->{'clientValues'}{'clubID'} > 0 ) {
                $clubHidden = qq[<input type="hidden" name ="d_intClubID" value="$Data->{'clientValues'}{'clubID'}">];
            }
            my $msID = '';
            if ( $SeasonStatus == -1 ) {
                $action = $Data->{'clientValues'}{'clubID'} > 0 ? 'SN_MSviewCEDIT' : 'SN_MSviewEDIT';
                $msID = qq[<input type="hidden" name ="msID" value="$inSeason">];
            }
            my $txt = qq[
				<div class="warningbox">This Member is NOT REGISTERED in $txt_Name, $assocSeasons->{'newRegoSeasonName'}. 
					<form action="$Data->{'target'}" method="POST">
						<input type="submit" name="subbutton" value="Register" class="button proceed-button">
						<input type="hidden" name ="client" value="$client">
						<input type="hidden" name ="a" value="$action">
						<input type="hidden" name ="d_intSeasonID" value="$assocSeasons->{'newRegoSeasonID'}">
						$msID
                        $clubHidden
					</form>
				</div>
			];
            $txt = '' if ( $Data->{'SystemConfig'}{'LockSeasons'}      and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC );
            $txt = '' if ( $Data->{'SystemConfig'}{'LockSeasonsCRL'}   and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC );
            $txt = '' if ( $Data->{'MemberClrdOut_ofCurrentClub'}      and $Data->{'clientValues'}{'authLevel'} <= $Defs::LEVEL_ASSOC );
            $txt = '' if ( $assoc_obj->getValue('intHideClubRollover') and $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_ASSOC );
            $resultHTML = $txt . $resultHTML;

        }

        $resultHTML = $defaulterstatus . $resultHTML if $defaulterstatus;

    }
    return ( $resultHTML, $title );
}

sub loadMemberDetails {
    my ( $db, $id, $assocID ) = @_;
    return {} if !$id;

    my $statement = qq[
	SELECT 
		tblMember.*, 
		MA.intRecStatus, 
		DATE_FORMAT(dtPassportExpiry,'%d/%m/%Y') AS dtPassportExpiry, 
		DATE_FORMAT(dtNatCustomDt1,'%d/%m/%Y') AS dtNatCustomDt1, 
		DATE_FORMAT(dtNatCustomDt2,'%d/%m/%Y') AS dtNatCustomDt2, 
		DATE_FORMAT(dtCustomDt1,'%d/%m/%Y') AS dtCustomDt1, 
		DATE_FORMAT(dtCustomDt2,'%d/%m/%Y') AS dtCustomDt2, 
		DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB, 
		dtDOB AS dtDOB_RAW, 
		DATE_FORMAT(dtLastRegistered,'%d/%m/%Y') AS dtLastRegistered, 
		DATE_FORMAT(dtRegisteredUntil,'%d/%m/%Y') AS dtRegisteredUntil, 
		DATE_FORMAT(dtFirstRegistered,'%d/%m/%Y') AS dtFirstRegistered, 
		DATE_FORMAT(dtPoliceCheck,'%d/%m/%Y') AS dtPoliceCheck, 
		DATE_FORMAT(dtPoliceCheckExp,'%d/%m/%Y') AS dtPoliceCheckExp, 
		DATE_FORMAT(dtCreatedOnline,'%d/%m/%Y') AS dtCreatedOnline, 
		DATE_FORMAT(MA.tTimeStamp,'%d/%m/%Y') AS tTimeStamp,
		MA.strCustomStr1, 
		MA.strCustomStr2, 
		MA.strCustomStr3, 
		MA.strCustomStr4, 
		MA.strCustomStr5, 
		MA.strCustomStr6, 
		MA.strCustomStr7, 
		MA.strCustomStr8, 
		MA.strCustomStr9, 
		MA.strCustomStr10, 
		MA.strCustomStr11, 
		MA.strCustomStr12, 
		MA.strCustomStr13, 
		MA.strCustomStr14, 
		MA.strCustomStr15, 
		MA.strCustomStr16, 
		MA.strCustomStr17, 
		MA.strCustomStr18, 
		MA.strCustomStr19, 
		MA.strCustomStr20, 
		MA.strCustomStr21, 
		MA.strCustomStr22, 
		MA.strCustomStr23, 
		MA.strCustomStr24, 
		MA.strCustomStr25, 
		MA.dblCustomDbl1, 
		MA.dblCustomDbl2, 
		MA.dblCustomDbl3, 
		MA.dblCustomDbl4, 
		MA.dblCustomDbl5, 
		MA.dblCustomDbl6, 
		MA.dblCustomDbl7, 
		MA.dblCustomDbl8, 
		MA.dblCustomDbl9, 
		MA.dblCustomDbl10,   
		MA.dblCustomDbl11, 
		MA.dblCustomDbl12, 
		MA.dblCustomDbl13, 
		MA.dblCustomDbl14, 
		MA.dblCustomDbl15, 
		MA.dblCustomDbl16, 
		MA.dblCustomDbl17, 
		MA.dblCustomDbl18, 
		MA.dblCustomDbl19, 
		MA.dblCustomDbl20,   
		DATE_FORMAT(MA.dtCustomDt1, '%d/%m/%Y') AS dtCustomDt1, 
		DATE_FORMAT(MA.dtCustomDt2, '%d/%m/%Y') AS dtCustomDt2, 
		DATE_FORMAT(MA.dtCustomDt3, '%d/%m/%Y') AS dtCustomDt3,  
		DATE_FORMAT(MA.dtCustomDt4, '%d/%m/%Y') AS dtCustomDt4,  
		DATE_FORMAT(MA.dtCustomDt5, '%d/%m/%Y') AS dtCustomDt5, 
		DATE_FORMAT(MA.dtCustomDt6, '%d/%m/%Y') AS dtCustomDt6, 
		DATE_FORMAT(MA.dtCustomDt7, '%d/%m/%Y') AS dtCustomDt7, 
		DATE_FORMAT(MA.dtCustomDt8, '%d/%m/%Y') AS dtCustomDt8,  
		DATE_FORMAT(MA.dtCustomDt9, '%d/%m/%Y') AS dtCustomDt9,  
		DATE_FORMAT(MA.dtCustomDt10,'%d/%m/%Y') AS dtCustomDt10, 
		DATE_FORMAT(MA.dtCustomDt11,'%d/%m/%Y') AS dtCustomDt11, 
		DATE_FORMAT(MA.dtCustomDt12,'%d/%m/%Y') AS dtCustomDt12, 
		DATE_FORMAT(MA.dtCustomDt13,'%d/%m/%Y') AS dtCustomDt13,  
		DATE_FORMAT(MA.dtCustomDt14,'%d/%m/%Y') AS dtCustomDt14,  
		DATE_FORMAT(MA.dtCustomDt15,'%d/%m/%Y') AS dtCustomDt15, 
		MA.intCustomLU1, 
		MA.intCustomLU2, 
		MA.intCustomLU3, 
		MA.intCustomLU4, 
		MA.intCustomLU5, 
		MA.intCustomLU6, 
		MA.intCustomLU7, 
		MA.intCustomLU8, 
		MA.intCustomLU9, 
		MA.intCustomLU10, 
		MA.intCustomLU11, 
		MA.intCustomLU12, 
		MA.intCustomLU13, 
		MA.intCustomLU14, 
		MA.intCustomLU15, 
		MA.intCustomLU16, 
		MA.intCustomLU17, 
		MA.intCustomLU18, 
		MA.intCustomLU19, 
		MA.intCustomLU20, 
		MA.intCustomLU21, 
		MA.intCustomLU22, 
		MA.intCustomLU23, 
		MA.intCustomLU24, 
		MA.intCustomLU25, 
		MA.intCustomBool1,  
		MA.intCustomBool2,  
		MA.intCustomBool3,  
		MA.intCustomBool4,  
		MA.intCustomBool5, 
		MA.intCustomBool6, 
		MA.intCustomBool7, 
		DATE_FORMAT(dtNatCustomDt3,'%d/%m/%Y') AS dtNatCustomDt3, 
		DATE_FORMAT(dtNatCustomDt4,'%d/%m/%Y') AS dtNatCustomDt4, 
		DATE_FORMAT(dtNatCustomDt5,'%d/%m/%Y') AS dtNatCustomDt5, 
		tblSchool.strName AS strSchoolName, 
		tblSchool.strSuburb AS strSchoolSuburb, 
		A.intAssocTypeID, 
		MA.intLifeMember, 
		MA.curMemberFinBal, 
		MA.intFinancialActive, 
		MA.intMemberPackageID,
		MA.strLoyaltyNumber, 
		MA.intMailingList,
		MN.strMemberNotes,
		MN.strMemberMedicalNotes,
		MN.strMemberCustomNotes1,
		MN.strMemberCustomNotes2,
		MN.strMemberCustomNotes3,
		MN.strMemberCustomNotes4,
		MN.strMemberCustomNotes5
		FROM 
			tblMember 
			LEFT  JOIN tblMember_Associations AS MA ON (
				MA.intMemberID=tblMember.intMemberID 
				AND MA.intAssocID = ?
			)
			LEFT JOIN tblAssoc AS A ON (MA.intAssocID=A.intAssocID)
			LEFT JOIN tblSchool ON (tblMember.intSchoolID=tblSchool.intSchoolID)
			LEFT JOIN tblMemberNotes as MN ON (
				MN.intNotesMemberID = tblMember.intMemberID
				AND MN.intNotesAssocID=MA.intAssocID
			)
    	WHERE 
		    tblMember.intMemberID = ?
	];

    my $query = $db->prepare($statement);
    $query->execute(
                     $assocID,
                     $id,
    );
    my $field = $query->fetchrow_hashref();
    if ($field) {
        if ( !defined $field->{dtDOB} ) {
            $field->{dtDOB_year} = $field->{dtDOB_month} = $field->{dtDOB_day} = $field->{dtDOB} = '';
        }
        else {
            ( $field->{dtDOB_year}, $field->{dtDOB_month}, $field->{dtDOB_day} ) = $field->{dtDOB_RAW} =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
        }
    }

    $query->finish;

    foreach my $key ( keys %{$field} ) {
        if ( !defined $field->{$key} ) { $field->{$key} = ''; }
    }
    return $field;
}

sub postMemberUpdate {
    my ( $id, $params, $action, $Data, $db, $memberID, $fields ) = @_;

    $memberID ||= 0;
    $id ||= $memberID;
    return ( 0, undef ) if !$db;

    my $assocID = $Data->{'clientValues'}{'assocID'} || 0;
    $Data->{'cache'}->delete( 'swm', "MemberObj-$id-$assocID" ) if $Data->{'cache'};

    my %types        = ();
    my $assocSeasons = Seasons::getDefaultAssocSeasons($Data);
    $types{'intPlayerStatus'} = $params->{'d_intPlayer'} if exists( $params->{'d_intPlayer'} );
    $types{'intCoachStatus'}  = $params->{'d_intCoach'}  if exists( $params->{'d_intCoach'} );
    $types{'intUmpireStatus'} = $params->{'d_intUmpire'} if exists( $params->{'d_intUmpire'} );
    $types{'intMiscStatus'}  = $params->{'d_intMisc'}  if exists( $params->{'d_intMisc'} );
    $types{'intVolunteerStatus'}  = $params->{'d_intVolunteer'}  if exists( $params->{'d_intVolunteer'} );

    #$types{'intOfficialStatus'} = $params->{'d_intOfficial'} if exists ($params->{'d_intOfficial'});
    if ( !$types{'intPlayerStatus'} and !$types{'intCoachStatus'} and !$types{'intUmpireStatus'} and !$types{'intMiscStatus'} and !$types{'intVolunteerStatus'} and !$types{'intOther1Status'} and !$types{'intOther2Status'} ) {
        $types{'intPlayerStatus'} = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_PLAYER );
        $types{'intCoachStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_COACH );
        $types{'intUmpireStatus'} = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_UMPIRE );
        $types{'intMiscStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_MISC );
        $types{'intVolunteerStatus'}  = 1 if ( $assocSeasons->{'defaultMemberType'} == $Defs::MEMBER_TYPE_VOLUNTEER );

    }

    my $genAgeGroup ||= new GenAgeGroup( $Data->{'db'}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $Data->{'clientValues'}{'assocID'} );
    my $st = qq[
		SELECT DATE_FORMAT(dtDOB, "%Y%m%d"), intGender
		FROM tblMember
		WHERE intMemberID = ?
	];
    my $qry = $db->prepare($st);
    $qry->execute($id);
    my ( $DOBAgeGroup, $Gender ) = $qry->fetchrow_array();
    $DOBAgeGroup ||= '';
    $Gender      ||= 0;
    my $ageGroupID = $genAgeGroup->getAgeGroup( $Gender, $DOBAgeGroup ) || 0;

    updateMemberNotes( $db, $Data->{'clientValues'}{'assocID'}, $id, $params );

    if ( $action eq 'add' ) {
        $types{'intMSRecStatus'} = 1;
        if ($id) {
            # create default records for new member in MemberRecords
            if($Data->{'SystemConfig'}{'EnableMemberRecords'}) {
                my $cgi = new CGI();
                my @record_types = $cgi->param('d_MemberRecordTypeList');
                create_member_records($Data, $id, \@record_types);
            }

            if ( $Data->{'clientValues'}{'assocID'} and $Data->{'clientValues'}{'assocID'} != $Defs::INVALID_ID ) {

                my @cfieldnames = (
                    map("strCustomStr$_", (1..20)),
                    map("dblCustomDbl$_", (1..20)),
                    map("dtCustomDt$_", (1..15)),
                    map("intCustomLU$_", (1..25)),
                    map("intCustomBool$_", (1..7)),
                    qw(
                    intFinancialActive
                    intMemberPackageID
                    dtFirstRegistered
                    dtLastRegistered
                    curMemberFinBal
                    strLoyaltyNumber
                    intLifeMember
                    intMailingList
                    )
                );
                my @cfieldvals = ();
                $params->{'d_intMailingList'}     ||= 0;
                $params->{'d_intFinancialActive'} ||= 0;
                $params->{'d_intLifeMember'}      ||= 0;
                for my $f (@cfieldnames) {
                    push @cfieldvals, $params->{ 'd_' . $f };
                }
                deQuote( $db, \@cfieldvals );
                my $cfield_nam = join( ',', @cfieldnames ) || '';
                my $cfield_val = join( ',', @cfieldvals )  || '';

                my $st = qq[
                INSERT INTO tblMember_Associations (intMemberID,intAssocID, intRecStatus, $cfield_nam)
                VALUES ($id,$Data->{'clientValues'}{'assocID'}, $Defs::RECSTATUS_ACTIVE, $cfield_val)
                ];
                $db->do($st);

                #### if ($Data->??{'addDefaultRego'})
                ### my $st = qq[
                Transactions::insertDefaultRegoTXN( $db, $Defs::LEVEL_MEMBER, $id, $Data->{'clientValues'}{'assocID'} );

            }
            my $clubInserted = 0;
            if ( $Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID ) {
                $clubInserted = 1;
                my $st = qq[
                INSERT INTO tblMember_Clubs (intMemberID,intClubID, intStatus)
                VALUES ($id,$Data->{'clientValues'}{'clubID'}, $Defs::RECSTATUS_ACTIVE)
                ];
                $db->do($st);
                Seasons::insertMemberSeasonRecord( $Data, $id, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, $Data->{'clientValues'}{'clubID'}, $ageGroupID, \%types );
            }
            if ( $Data->{'clientValues'}{'teamID'} and $Data->{'clientValues'}{'teamID'} != $Defs::INVALID_ID ) {
                my $st = qq[
                SELECT DISTINCT CT.intCompID, AC.intNewSeasonID
                FROM tblComp_Teams as CT
                INNER JOIN tblAssoc_Comp as AC ON (AC.intCompID = CT.intCompID)
                WHERE CT.intTeamID=$Data->{'clientValues'}{'teamID'}
                AND CT.intRecStatus = $Defs::RECSTATUS_ACTIVE
                AND AC.intRecStatus = $Defs::RECSTATUS_ACTIVE
                ];
                $st .= qq[ AND CT.intCompID = $Data->{'clientValues'}{'compID'}] if ( $Data->{'clientValues'}{'compID'} and $Data->{'clientValues'}{'compID'} != $Defs::INVALID_ID );    ## IF AT A COMP
                my $qry_comps = $db->prepare($st);
                $qry_comps->execute or query_error($st);

                my $statement = qq[
                INSERT INTO tblMember_Teams (intMemberID, intTeamID, intStatus, intCompID) VALUES ($id, $Data->{'clientValues'}{'teamID'}, $Defs::RECSTATUS_ACTIVE, ?)
                ];
                my $query = $db->prepare($statement);

                my $comp_counts       = 0;
                my @Seasons           = ();
                my $doneNewRegoSeason = 0;
                while ( my ( $DB_intCompID, $DB_intSeasonID ) = $qry_comps->fetchrow_array() ) {
                    $comp_counts++;
                    $query->execute($DB_intCompID);
                    push @Seasons, $DB_intSeasonID;
                    $doneNewRegoSeason = 1 if $DB_intSeasonID == $assocSeasons->{'newRegoSeasonID'};
                    Seasons::insertMemberSeasonRecord( $Data, $id, $DB_intSeasonID, $Data->{'clientValues'}{'assocID'}, 0, $ageGroupID, \%types );
                }
                Seasons::insertMemberSeasonRecord( $Data, $id, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, 0, $ageGroupID, \%types ) if ( !$doneNewRegoSeason );
                $query->execute(0) if !$comp_counts;

                if ( !$clubInserted ) {
                    $st = qq[
                    SELECT intClubID
                    FROM tblTeam
                    WHERE intTeamID = $Data->{'clientValues'}{'teamID'}
                    ];
                    my $qry_teamclub = $db->prepare($st);
                    $qry_teamclub->execute or query_error($st);
                    my $clubID = $qry_teamclub->fetchrow_array() || 0;

                    if ($clubID) {
                        my $st = qq[
                        INSERT INTO tblMember_Clubs (intMemberID,intClubID, intStatus)
                        VALUES ($id,$clubID, $Defs::RECSTATUS_ACTIVE)
                        ];
                        $db->do($st);
                        #### LOOP SEASONS HERE !!!!!!!
                        my $doneNewRegoSeason = 0;
                        for my $season (@Seasons) {
                            Seasons::insertMemberSeasonRecord( $Data, $id, $season, $Data->{'clientValues'}{'assocID'}, $clubID, $ageGroupID, \%types );
                            $doneNewRegoSeason = 1 if $season == $assocSeasons->{'newRegoSeasonID'};

                        }
                        Seasons::insertMemberSeasonRecord( $Data, $id, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, $clubID, $ageGroupID, \%types )
                        if ( !$doneNewRegoSeason );
                    }
                }
            }
        }
        getAutoMemberNum( $Data, undef, $id, $Data->{'clientValues'}{'assocID'} );
        setupMemberTypes( $Data, $id, $params, $Data->{'clientValues'}{'assocID'} );
        Seasons::insertMemberSeasonRecord( $Data, $id, $assocSeasons->{'newRegoSeasonID'}, $Data->{'clientValues'}{'assocID'}, 0, $ageGroupID, \%types ) if ($id);
        if ( $params->{'isDuplicate'} ) {
            my $st = qq[
                UPDATE tblMember SET intStatus=$Defs::MEMBERSTATUS_POSSIBLE_DUPLICATE 
                WHERE intMemberID=$id
            ];
            $db->do($st);
            return ( 0, DuplicateExplanation($Data) );
        }
        else {
            my $cl = setClient( $Data->{'clientValues'} ) || '';
            my %cv = getClient($cl);
            $cv{'memberID'}     = $id;
            $cv{'currentLevel'} = $Defs::LEVEL_MEMBER;
            my $clm = setClient( \%cv );

            return (
                0, qq[
                <div class="OKmsg"> $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} Added Successfully</div><br>
                <a href="$Data->{'target'}?client=$clm&amp;a=M_HOME">Display Details for $params->{'d_strFirstname'} $params->{'d_strSurname'}</a><br><br>
                <b>or</b><br><br>
                <a href="$Data->{'target'}?client=$cl&amp;a=M_A&amp;l=$Defs::LEVEL_MEMBER">Add another $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}</a>
                ]
            );

            #</RE>
        }
    }
    else {
        my $status = $params->{'d_intRecStatus'} || $params->{'intRecStatus'} || 0;
        if ( $status == 1 ) {
            my $st = qq[UPDATE tblMember SET intStatus = 1 WHERE intMemberID = $id AND intStatus = 0 LIMIT 1];
            $db->do($st);
        }
        Transactions::insertDefaultRegoTXN( $db, $Defs::LEVEL_MEMBER, $id, $Data->{'clientValues'}{'assocID'} );

        ## CHECK IF FIRSTNAME, SURNAME OR DOB HAVE CHANGED
        my $firstname_p = $params->{'d_strFirstname'} || $params->{'strFirstname'} || '';
        my $lastname_p  = $params->{'d_strSurname'}   || $params->{'strSurname'}   || '';
        my $dob_p       = $params->{'d_dtDOB'}        || $params->{'dtDOB'}        || '';
        my $email_p     = $params->{'d_strEmail'}     || $params->{'strEmail'}     || '';

        my $firstname_f = $fields->{'strFirstname'} || '';
        my $lastname_f  = $fields->{'strSurname'}   || '';
        my $dob_f       = $fields->{'dtDOB'}        || '';
        my $email_f     = $fields->{'strEmail'}     || '';

        my ( $d, $m, $y ) = split /\//, $dob_f;
        $dob_f = qq[$y-$m-$d];
        my ( $dob_p_y, $dob_p_m, $dob_p_d ) = split /-/, $dob_p if ($dob_p);
        $dob_p = sprintf( "%02d-%02d-%02d", $dob_p_y, $dob_p_m, $dob_p_d ) if ($dob_p);

        my $dupl_check = 0;
        $dupl_check = 1 if ( $firstname_p and $firstname_p ne $firstname_f );
        $dupl_check = 1 if ( $lastname_p  and $lastname_p ne $lastname_f );
        $dupl_check = 1 if ( $dob_p       and $dob_p ne $dob_f );

        if ( $dupl_check == 1 ) {
            my $st = qq[UPDATE tblMember SET intStatus = 2 WHERE intMemberID = $id LIMIT 1];
            $db->do($st);
        }

    }

    return ( 1, '' );
}

sub preMemberAdd {
    my ( $params, $action, $Data, $db, $typeofDuplCheck ) = @_;

    if ($Data->{'SystemConfig'}{'checkPrimaryClub'} or $Data->{'SystemConfig'}{'DuplicatePrevention'}) {

        my %newMember = (
            firstname => $params->{'d_strFirstname'},
            surname   => $params->{'d_strSurname'},
            dob       => $params->{'d_dtDOB'},
        );
        
        my $resultHTML = '';

        #At some stage PrimaryClub and DuplicatePrevention may/should become intertwined.
        #Currently, PrimaryClub workings haven't been finalised; nor has primary club been set for each member.

        if ($Data->{'SystemConfig'}{'checkPrimaryClub'}) {
            my $format = 1; #This should be set to 2 when the TransferLink part is working...mick

            $resultHTML = checkPrimaryClub($Data, \%newMember, $format); 
        }

        if (!$resultHTML) {
            if ($Data->{'SystemConfig'}{'DuplicatePrevention'}) {
                my $prefix = (exists $params->{'formID'} and $params->{'formID'}) ? 'yn' : 'd_int';
 
                my @memberTypes = ($prefix.'Player', $prefix.'Coach', $prefix.'MatchOfficial', $prefix.'Official', $prefix.' Misc', $prefix.' Volunteer');

                my @registeringAs = ();

                foreach my $memberType (@memberTypes) {
                    push @registeringAs, $memberType if (exists $params->{$memberType} and $params->{$memberType});
                }

                $resultHTML = duplicate_prevention($Data, \%newMember, \@registeringAs);
            }
        }

        return (0, $resultHTML) if $resultHTML;
    }

    #This Function checks for duplicates
    my $realmID = $Data->{'Realm'} || 0;

    $typeofDuplCheck ||= '';

    my $duplcheck = $typeofDuplCheck || Duplicates::isCheckDupl($Data) || '';

    if ($duplcheck) {

        #Check for Duplicates
        my @FieldsToCheck = Duplicates::getDuplFields($Data);
        return ( 1, '' ) if !@FieldsToCheck;

        my $st        = q{};
        my $wherestr  = q{};
        my $joinCheck = q{};

        my ( @st_fields, @where_fields, @joinCheck_fields );

        if ( $params->{'ID'} ) {
            $wherestr .= 'AND tblMember.intMemberID <> ?';
            push @where_fields, $params->{'ID'};
        }

        for my $i (@FieldsToCheck) {
            if ( $i =~ /^dt/ and $Data->{'RegoFormID'} ) {

                $wherestr .= qq[ AND $i=COALESCE(STR_TO_DATE(?,'%d/%m/%Y'), STR_TO_DATE(?, '%Y-%m-%d'))];

                my $date = $params->{ 'd_' . $i };
                push @where_fields, $date, $date;
            }
            else {
                $wherestr .= " AND  $i = ?";
                push @where_fields, $params->{ 'd_' . $i };
            }
        }

        if ( $params->{'ID_IN'} ) {
            $wherestr     = 'AND tblMember.intMemberID = ?';
            @where_fields = ( $params->{'ID_IN'} );
        }

        if ( $Data->{'RegoFormID'} and $params->{'clubID_check'} and $params->{'clubID_check'} > 0 ) {
            $joinCheck = qq[
                INNER JOIN tblMember_Clubs as MC ON (
                    MC.intMemberID = tblMember.intMemberID
                    AND MC.intClubID = ?
                    AND MC.intStatus=1
                    AND MC.intPermit=0
                )
            ];
            push @joinCheck_fields, $params->{'clubID'};

        }
        if ( $Data->{'RegoFormID'} and $params->{'teamID_check'} and $params->{'teamID_check'} > 0 ) {
            $joinCheck .= qq[
                INNER JOIN tblMember_Teams as MT ON (
                    MT.intMemberID = tblMember.intMemberID
                    AND MT.intTeamID = ?
                    AND MC.intStatus=1
                )
            ];
            push @joinCheck_fields, $params->{'teamID'};
        }
        if ( $duplcheck eq 'realm' ) {

            if ( $Data->{'RegoFormID'} and $params->{'assocID_check'} and $params->{'assocID_check'} > 0 ) {
                $joinCheck .= qq[
                    INNER JOIN tblMember_Associations as MA ON (
                        MA.intMemberID = tblMember.intMemberID
                        AND MA.intAssocID = ?
                        AND MA.intRecStatus=1
                    )
                ];
                push @joinCheck_fields, $params->{'assocID'};
            }

            #Check Entire realm
            $st = qq[
				SELECT tblMember.intMemberID
				FROM tblMember
                    $joinCheck
                WHERE  tblMember.intRealmID = ? AND tblMember.intStatus <> ?
					$wherestr
                ORDER BY tblMember.intStatus
				LIMIT 1
			];

            @st_fields = (@joinCheck_fields, $realmID, $Defs::MEMBERSTATUS_DELETED, @where_fields,);
        }
        else {

            #Just check Assoc
            $st = qq[
				SELECT tblMember.intMemberID
				FROM tblMember INNER JOIN tblMember_Associations
                $joinCheck
                WHERE  tblMember.intRealmID = ?
                    AND tblMember_Associations.intAssocID = ?
                    AND tblMember.intStatus <> ?
					$wherestr
                ORDER BY tblMember.intStatus
				LIMIT 1
			];

            @st_fields = (@joinCheck_fields, $realmID, $Data->{'clientValues'}{'assocID'}, $Defs::MEMBERSTATUS_DELETED, @where_fields,);

        }
        my $q = $db->prepare($st);
        $q->execute(@st_fields);
        my $dupl = $q->fetchrow_array;
        $q->finish();
        $dupl ||= 0;
        $params->{'isDuplicate'} = $dupl;

    }
    return ( 1, '' );
}

sub DuplicateExplanation {
    my ($Data) = @_;

    my $msg = '<div class="warningmsg">Member is Possible Duplicate</div>';
    my $currentLevel = $Data->{'clientValues'}{'currentLevel'} || $Defs::LEVEL_NONE;

    my $client = setClient( $Data->{'clientValues'} ) || '';
    my $link = "$Data->{'target'}?client=$client&amp;a=DUPL_L";

    if ( $currentLevel == $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} you have added possibly duplicates another record that already exists in this system.</p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} <b>has</b> been temporarily added but their details will not be available.</p>
			<p>You should resolve this and any other duplicates as soon as possible by proceeding to the <b>Duplicate Resolution</b> section.</p>
			<p><a href="$link">Resolve Duplicates</a></p>
		];
    }
    elsif ( $currentLevel < $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} you have added possibly duplicates another record that already exists in this system.  </p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} <b>has</b> been temporarily added but their details will not be available. They will remain this way until your $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} has resolved this issue.</p>
		];
    }
    elsif ( $currentLevel > $Defs::LEVEL_ASSOC ) {
        $msg .= qq[
			<p>The $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} you have added possibly duplicates another record that already exists in this system.  </p>
			<p>This $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} <b>has</b> been temporarily added but their details will not be available. </p>
			<p>You need to proceed to the $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} and choose the <b>Duplicate Resolution</b> option to resolve this issue.</p>
		];
    }
    return $msg;
}

sub getAutoMemberNum {
    my ( $Data, $genCode, $memberID, $assocID ) = @_;

    if ( $Data->{'SystemConfig'}{'GenMemberNo'} ) {
        my $num_field = $Data->{'SystemConfig'}{'GenNumField'} || 'strNationalNum';
        my $CreateCodes = 0;
        if ( exists $Data->{'SystemConfig'}{'GenNumAssocIn'} ) {
            my @assocs = split /\|/, $Data->{'SystemConfig'}{'GenNumAssocIn'};
            for my $i (@assocs) { $CreateCodes = 1 if $i == $assocID; }
        }
        else { $CreateCodes = 1; }
        if ($CreateCodes) {
            $genCode ||= new GenCode( $Data->{'db'}, $Data->{'Realm'} );
            my $num = $genCode->getNumber( '', '', $num_field ) || '';
            if ($num) {
                my $st = qq[
						UPDATE tblMember SET $num_field = ?
						WHERE intMemberID = ?
				];
                $Data->{'db'}->do( $st, undef, $num, $memberID );
                return $num;
            }
        }
    }
    return undef;
}

sub showClubTeams {
    my ( $Data, $memberID ) = @_;

    my $aID = $Data->{'clientValues'}{'assocID'} || 0;    #Current Association
                                                          #Check and Display what other assocs this person may be in
    my $st = qq[
		SELECT DISTINCT 
            tblClub.intClubID, 
            tblClub.strName, 
            MC.intGradeID, 
            MC.strContractYear, 
            MC.strContractNo, 
            MC.intPrimaryClub, 
            G.strGradeName, 
            MC.intStatus, 
            MC.intPermit, 
            tblClub.intRecStatus
		FROM tblClub 
			INNER JOIN tblMember_Clubs AS MC ON (tblClub.intClubID=MC.intClubID)
			INNER JOIN tblAssoc_Clubs AS AC ON (tblClub.intClubID=AC.intClubID)
			LEFT JOIN tblClubGrades AS G ON (G.intGradeID=MC.intGradeID)
		WHERE MC.intMemberID=$memberID
			AND AC.intAssocID = $aID
			AND AC.intRecStatus <> $Defs::RECSTATUS_DELETED
			AND MC.intStatus <> $Defs::RECSTATUS_DELETED
		ORDER BY strName, intStatus DESC, intPermit ASC
	];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute;

    my $body       = '';
    my $clubs      = '';
    my $clubStatus = '';
    my $cnt        = 0;
    my %hasClub    = ();
    while ( my $dref = $query->fetchrow_hashref() ) {
        ## GET THE NAME OF THE GRADE FOR THE MEMBER IF ALLOW CLUB GRADES IS ENABLED IN SYS CONFIG
        my $gradeName = '&nbsp;';
        next if exists $hasClub{ $dref->{intClubID} };
        $hasClub{ $dref->{intClubID} } = 1;
        if ( $Data->{'SystemConfig'}{'AllowClubGrades'} ) {
            $gradeName = qq[($dref->{'strGradeDesc'})] if $dref->{'strGradeDesc'};
        }
        my $status = ( $dref->{intStatus} == $Defs::RECSTATUS_INACTIVE ) ? qq[<i>(Inactive)</i>] : '&nbsp;';
        my $permit = ( $dref->{intPermit} == 1 ) ? qq[<i>On Permit</i>] : '&nbsp;';

        my $primaryClub = ( $dref->{'intPrimaryClub'} )   ? qq{[Primary Club]} : '&nbsp;';
        my $class       = $cnt % 2 == 0                   ? 'rowshade'         : '';
        my $deleted     = ( $dref->{intRecStatus} == -1 ) ? qq[ (Deleted)]     : '';
        $clubs .= qq[
			<tr>
				<td class="$class">$dref->{'strName'}$deleted</td>
				<td class="$class">$gradeName</td>
				<td class="$class">$primaryClub</td>
				<td class="$class">$status&nbsp;$permit</td>
			</tr>
		];
        if ( $Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID and $Data->{'clientValues'}{'clubID'} == $dref->{intClubID} ) {
            $clubStatus = $dref->{intStatus};
        }
        $cnt++;
    }
    my $teams           = listMemberTeams( $Data, $memberID ) || '';
    my $editclubsbutton = '';
    my $client          = setClient( $Data->{'clientValues'} ) || '';
    if ( $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_ASSOC and !$Data->{'SystemConfig'}{'NoClubs'} and allowedAction( $Data, 'mc_e' ) ) {
        $editclubsbutton = qq[
			<form action="$Data->{'target'}" method="POST" >
				<input type="hidden" name="a" value="M_CLB_">
				<input type="hidden" name="client" value="$client">
				<input type="submit" class="button proceed-button" value="Edit $Data->{'LevelNames'}{$Defs::LEVEL_CLUB."_P"}">
			</form>
		];
    }
    $editclubsbutton = '' if $Data->{'SystemConfig'}{'LockClub'};
    if ( !$Data->{'SystemConfig'}{'NoClubs'} ) {
        $clubs ||= '';
        $clubs = qq[
			<table class="listTable" style="width:100%;">$clubs</table>
				<br>
				$editclubsbutton
		];
    }

    return ( $clubStatus, $clubs, $teams );
}

sub checkOtherAssocs {
    my ( $Data, $memberID ) = @_;

    my $aID = $Data->{'clientValues'}{'assocID'} || 0;    #Current Association
                                                          #Check and Display what other assocs this person may be in

    my $st = qq[
		SELECT strName, MA.intRecStatus
		FROM tblAssoc INNER JOIN tblMember_Associations AS MA ON (tblAssoc.intAssocID=MA.intAssocID)
		WHERE intMemberID = ?
			AND tblAssoc.intAssocID <> ?
			AND MA.intRecStatus <> $Defs::RECSTATUS_DELETED
		ORDER BY strName
	];
    my $query = $Data->{'db'}->prepare($st);
    $query->execute(
                     $memberID,
                     $aID,
    );
    my $body = '';
    while ( my $dref = $query->fetchrow_hashref() ) {
        my $act = $dref->{'intRecStatus'} == $Defs::RECSTATUS_ACTIVE ? 'Active' : 'Inactive';

        $body .= qq[$dref->{'strName'} <i>($act)</i><br>\n];
    }
    if ($body) {
        $body = qq[
			<div class="sectionheader">Other $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC.'_P'}</div>
				$body
		];
    }

    return $body;
}

sub delete_member {
    my ( $Data, $memberID ) = @_;

    my $aID = $Data->{'clientValues'}{'assocID'} || 0;    #Current Association
    return '' if ( !( allowedAction( $Data, 'm_d' ) and $Data->{'SystemConfig'}{'AllowMemberDelete'} ) );
######## NEEDS THINK ABOUT WR WARREN warren wsc

    my $st = qq[UPDATE tblMember_Associations SET intRecStatus=$Defs::RECSTATUS_DELETED WHERE intMemberID=$memberID AND intAssocID=$aID];
    $Data->{'db'}->do($st);
    $Data->{'clientValues'}{'memberID'} = $Defs::INVALID_ID;
    {
        if ( $Data->{'clientValues'}{'teamID'} and $Data->{'clientValues'}{'teamID'} != $Defs::INVALID_ID ) {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_TEAM;
        }
        elsif ( $Data->{'clientValues'}{'clubID'} and $Data->{'clientValues'}{'clubID'} != $Defs::INVALID_ID ) {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_CLUB;
        }
        else {
            $Data->{'clientValues'}{'currentLevel'} = $Defs::LEVEL_ASSOC;
        }
        $Data->{'clientValues'}{'currentLevel'} = $Defs::INVALID_ID if $Data->{'clientValues'}{'authLevel'} < $Data->{'clientValues'}{'currentLevel'};
    }

    return ( qq[<div class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} deleted successfully</div>], "Delete $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}" );

}

sub setupMemberTypes {
    my ( $Data, $id, $params, $assocID ) = @_;
    my $st = qq[
        INSERT INTO tblMember_Types 
		    (intMemberID, intTypeID,intActive, intAssocID, intRecStatus)
        VALUES 
            (?, ?, 1, ?, $Defs::RECSTATUS_ACTIVE)
	];
    my $q = $Data->{'db'}->prepare($st);
    my %vals = (
        d_intPlayer    => $Defs::MEMBER_TYPE_PLAYER,
        d_intCoach     => $Defs::MEMBER_TYPE_COACH,
        d_intUmpire    => $Defs::MEMBER_TYPE_UMPIRE,
        d_intMisc      => $Defs::MEMBER_TYPE_MISC,
        d_intVolunteer => $Defs::MEMBER_TYPE_VOLUNTEER,
    );
    for my $type ( keys %vals ) {
        $q->execute( $id, $vals{$type}, $assocID ) if $params->{$type};
    }
}

sub MemberDupl {
    my ( $action, $Data, $memberID ) = @_;

    $memberID ||= 0;
    return '' if !$memberID;
    return '' if !Duplicates::isCheckDupl($Data);

    if ( $action eq 'M_DUP_S' ) {
        my $st = qq[
			UPDATE tblMember
			SET intStatus = $Defs::MEMBERSTATUS_POSSIBLE_DUPLICATE
			WHERE intMemberID = $memberID
			LIMIT 1
		];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute;
        my $msg = qq[
			<p class="OKmsg">$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} has been marked as a duplicate</p>
		];
        if ( $Data->{'clientValues'}{'authLevel'} == $Defs::LEVEL_ASSOC ) {
            my $client = setClient( $Data->{'clientValues'} ) || '';
            my $dupllink = "$Data->{'target'}?client=$client&amp;a=DUPL_L";
            $msg .= qq[<p>To resolve this duplicate click <a href="$dupllink">Resolve Duplicates</a>.</p>];
        }
        auditLog( $memberID, $Data, 'Mark as Duplicates', 'Duplicates' );
        return ( $msg, "$Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} marked as a duplicate" );
    }
    else {
        my $client = setClient( $Data->{'clientValues'} ) || '';
        my $st = qq[SELECT * FROM tblMember WHERE intMemberID = $memberID];
        my $query = $Data->{'db'}->prepare($st);
        $query->execute;
        my $dref = $query->fetchrow_hashref();

        my $msg = qq[
			<form action="$Data->{'target'}" method="POST" style="float:left;" onsubmit="document.getElementById('btnsubmit').disabled=true;return true;">
				<p>If you believe the $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} named below is a possible duplicate, click the <b>'Mark as Duplicate'</b> button.  </p>

		<p>This will mark this $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} as a duplicate for your $Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} to verify and resolve.</p>
			<p> <b>$dref->{strFirstname} $dref->{strSurname}</b></p>
			<p>
				<span class="warningmsg">NOTE: Only mark the duplicate $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER}, not the $Data->{'LevelNames'}{$Defs::LEVEL_MEMBER} you believe may be the original</span>.</p><br><br>
				<input type="hidden" name="a" value="M_DUP_S">
				<input type="hidden" name="client" value="$client">
				<input type="submit" value="Mark as Duplicate" id="btnsubmit" name="btnsubmit"  class="button proceed-button">
			</form>
		];
        return ( $msg, 'Mark as Duplicate' );
    }
}

sub loadMemberExpiry {
    my ( $db, $memberID ) = @_;
    my $st = qq[
        SELECT A.strName, MA.dtExpiry
        FROM tblMember_Associations MA
            INNER JOIN tblAssoc AS A ON MA.intAssocID=A.intAssocID
        WHERE MA.intMemberID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($memberID);
    my $html = '';
    while ( my ( $strName, $dtExpiry ) = $q->fetchrow_array() ) {
        if ($dtExpiry) {
            my ( $year, $month, $day ) = split /-/, $dtExpiry;
            $html = qq[<b>Contract Expiry Date:</b> $day/$month/$year ($strName)];
        }
    }
    return $html;
}


sub check_valid_date {
    my ($date) = @_;
    my ( $d, $m, $y ) = split /\//, $date;
    use Date::Calc qw(check_date);
    return check_date( $y, $m, $d );
}

sub _fix_date {
    my ($date) = @_;
    return '' if !$date;
    my ( $dd, $mm, $yyyy ) = $date =~ m:(\d+)/(\d+)/(\d+):;
    if ( !$dd or !$mm or !$yyyy ) { return ''; }
    if ( $yyyy < 100 ) { $yyyy += 2000; }
    return "$yyyy-$mm-$dd";
}

sub defaulter_check {
    my ( $memberID, $type, $Data ) = @_;
    my $db = $Data->{'db'};
    my $st = qq[SELECT intDefaulter FROM tblMember WHERE intMemberID = ?  AND intRealmID = ?];
    my $q = $db->prepare($st);
    $q->execute( $memberID, $Data->{'Realm'} );
    my $dref = $q->fetchrow_hashref();
    $type = uc($type);

    if ( $dref->{intDefaulter} == 1 ) {
        return qq[<div style="font-size:14px;color:red;"><b>WARNING:</b> $type</div>];
    }
    else {
        return 0;
    }
}


sub showSeasonSummary {

    my ( $Data, $memberID ) = @_;

    my $body = '';
    my ( $memseason_vals, $memseasons ) = listMemberSeasons( $Data, $memberID );
    my $season_Name = $Data->{'SystemConfig'}{'txtSeason'} || 'Season';
    if ($memseasons) {
        my %Title = ();
        $Title{1} = "$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC} Summary";
        $Title{2} = "$Data->{'LevelNames'}{$Defs::LEVEL_CLUB} Summary";
        $Title{3} = "Full $season_Name Summary";
        my $count = 1;
        for my $section ( @{$memseason_vals} ) {
            my $title = $Title{$count};
            $count++;
            $body .= qq[<div class="sectionheader">$title</div>$section];
        }
    }
    return ( $body, 'Season Summary' );
}

sub memberPreferences{
    my ( $action, $Data, $memberID ) = @_;
    return "Invalid action for member records: $action" if (not $action =~ /^M_PREFS/);
    my ($resultHTML, $title) = handle_member_prefs($action, $Data, $memberID);
    return ( $resultHTML, $title );
}

1;
