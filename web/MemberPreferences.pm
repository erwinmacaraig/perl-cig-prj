#
# $Header: svn://svn/SWM/trunk/web/Optin.pm 8251 2013-04-08 09:00:53Z rlee $
#
package MemberPreferences;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handle_member_prefs);
@EXPORT_OK = qw(handle_member_prefs);

use strict;

use lib "..";
use Reg_common;
use CGI qw(param unescape escape);
use Defs;
use Utils;
use HTMLForm;
use GridDisplay;
use InstanceOf;

sub handle_member_prefs{
    my ( $action, $Data, $memberID ) = @_;
    if ( $action eq 'M_PREFS' ) {
        return ( MemberPrefList( $Data, $memberID), "Member Preferences");

    }
    elsif ( $action eq 'M_PREFS_EOPM' ) {
        return ( EditPrefOptinMember($action,$Data, $memberID), "Edit Optin Preferences");
    }
    elsif ( $action eq 'M_PREFS_ENOP' ) {
        return ( EditPrefNewsletterOptin($action,$Data, $memberID), "Edit Newsletter Preferences");
    }
    elsif ( $action eq 'M_PREFS_UOPM' ) {
        return ( UpdatePrefOptinMember($action,$Data, $memberID), "");
    }
    elsif ( $action eq 'M_PREFS_UNOP' ) {
        return ( UpdatePrefNewsletterOptin($action,$Data, $memberID), "");
    }
    else {
        return ( "<b>Unknown action $action</b>", "Error");
    }
}

sub MemberPrefList{
    my ( $Data, $memberID ) = @_;
    my $db = $Data->{'db'};
    my $body = '';
    my $entity_obj;
    my $member_obj;
    my $level;
    my $levelID;
    my $levelName;
    
    my $client = setClient( $Data->{'clientValues'} ) || '';
    #Optins
    my $st = qq[
	    SELECT
            OPM.intOptinMemberID,
            OPM.intOptinID,
            OPM.intEntityTypeID,
            OPM.intEntityID,
            OPM.intFormID,
            OPM.intAction,
            OPM.intActionedByID,
            OPM.tTimestamp,
            OP.strOptinText
	    FROM
		    tblOptinMember OPM
		    JOIN tblOptin OP ON (OPM.intOptinID = OP.intOptinID)
	    WHERE
            OPM.intMemberID = ? AND OP.intRealmID = ?
        ];
    my $q = $db->prepare($st);
    $q->execute( $memberID, $Data->{'Realm'} );
    
    my @headers = (
        {
		    type => 'Selector',
		    field => 'SelectLink',
            hide=>1,
	    },
		{
            name  => 'Entity',
            field => 'intEntityID',
        },
		{
            name  => 'Entity Type',
            field => 'intEntityTypeID',
        },
		{
            name  => 'Description',
            field => 'strOptinText',
        },
		{
            name  => 'Action',
            field => 'intAction',
        },
		{
            name  => 'By',
            field => 'intActionedByID',
        },
		{
            name  => 'FormID',
            field => 'intFormID',
        },
		{
            name  => 'Date',
            field => 'tTimestamp',
        },
    );
    my @rowdata = ();
    while (my $dref = $q->fetchrow_hashref()) {
        $level = $dref->{'intEntityTypeID'};
        $levelID =$dref->{'intEntityID'} ;
        if ($level == $Defs::LEVEL_ASSOC){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC};
            $entity_obj= getInstanceOf( $Data, 'assoc', $levelID);
        }
        elsif($level == $Defs::LEVEL_CLUB){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_CLUB};
            $entity_obj= getInstanceOf( $Data, 'club', $levelID);
        }
        elsif($level == $Defs::LEVEL_TEAM){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_TEAM};
            $entity_obj= getInstanceOf( $Data, 'team', $levelID);
        }
        elsif($level == $Defs::LEVEL_NATIONAL){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_NATIONAL};
            $entity_obj= getInstanceOf( $Data, 'node', $levelID);
        }elsif($level == $Defs::LEVEL_STATE){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_STATE};
            $entity_obj= getInstanceOf( $Data, 'node', $levelID);
        }
        elsif($level == $Defs::LEVEL_REGION){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_REGION};
            $entity_obj= getInstanceOf( $Data, 'node', $levelID);
        }
        elsif($level == $Defs::LEVEL_ZONE){
            $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_ZONE};
            $entity_obj= getInstanceOf( $Data, 'node', $levelID);
        }
        else{
	        next;
            $levelName = "Unknown";
	        $entity_obj = undef;
        }
            
        $member_obj =getInstanceOf( $Data, 'member', $dref->{'intActionedByID'});
        push @rowdata, {
            SelectLink => "$Data->{'target'}?client=$client&amp;a=M_PREFS_EOPM&amp;oID=$dref->{intOptinID}",
            id => $dref->{'intOptinMemberID'} || 0,
            intFormID => $dref->{'intFormID'},
            intEntityID =>$entity_obj->getValue('strName'),
            intEntityTypeID => $levelName,
            intActionedByID =>$member_obj->getValue('strFirstname')." ".$member_obj->getValue('strSurname'),
            strOptinText => $dref->{'strOptinText'},
            tTimestamp => $dref->{'tTimestamp'},
            intAction => ($dref->{'intAction'})? "accepted" : "removed",
        };
    }
    $body = qq[<p>Opt-Ins</p>];
    $body .= showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        simple  => 1,
    );
    
    # T&C
    
    $st = qq[
	    SELECT
		    intMemberID,
		    intLevel,
		    intFormID,
		    tTimestamp
	    FROM
		    tblTermsMember 
	    WHERE
		    intMemberID = ?
	];
    $q = $db->prepare($st);
    $q->execute( $memberID);
    @headers = (
		{
            name  => 'Level',
            field => 'intLevel',
        },
		{
            name  => 'FormID',
            field => 'intFormID',
        },
		{
            name  => 'Date',
            field => 'tTimestamp',
        },
    );
    @rowdata = ();
    while (my $dref = $q->fetchrow_hashref()) {
        $level =$dref->{'intLevel'};
        $levelName ='';
        if ($level == $Defs::LEVEL_ASSOC) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_ASSOC};
	    }
	    elsif($level == $Defs::LEVEL_CLUB) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_CLUB};
	    }
	    elsif($level == $Defs::LEVEL_NATIONAL) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_NATIONAL};
        }
	    elsif($level == $Defs::LEVEL_STATE) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_STATE};
        }
        elsif($level == $Defs::LEVEL_REGION) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_REGION};
        }
        elsif($level == $Defs::LEVEL_ZONE) {
	        $levelName =$Data->{'LevelNames'}{$Defs::LEVEL_ZONE};
        }
        else{
            $levelName = "Unknown";
        }
	
	    push @rowdata, {
		    intFormID => $dref->{'intFormID'},
		    intLevel => $levelName,
		    tTimestamp => $dref->{'tTimestamp'},
	    };
    }
    $body .= qq[<p>Terms and Conditions</p>];
    $body .= showGrid(
        Data    => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid  => 'grid',
        width   => '99%',
        simple  => 1,
    );
    
    # Newsletter Optin

    return $body;
}

sub EditPrefOptinMember {
    my ( $action, $Data, $memberID ) = @_;
    my $optin_id = safe_param('oID','number') || 0;
    my $db = $Data->{'db'};

    my $st = qq[
        SELECT
            O.intOptinID,
            O.strOptinText,
            OM.intAction
        FROM
            tblOptin AS O
            INNER JOIN tblOptinMember AS OM ON O.intOptinID=OM.intOptinID
        WHERE
            OM.intMemberID=?
            AND O.intOptinID=?
    ];
    my $q = $db->prepare($st);
    $q->execute($memberID, $optin_id);
    my $dref = $q->fetchrow_hashref();

    my $client = setClient( $Data->{'clientValues'} ) || '';  
    my $checked = $dref->{'intAction'}? 'checked':'';
    my $resultHTML = qq[
        <form action="$Data->{'target'}" method="post">
        <input type="checkbox" name="optin" value="$optin_id" $checked>$dref->{'strOptinText'}<br>
        <input type="hidden" name="oID" value="$optin_id">
        <input type="hidden" name="a" value="M_PREFS_UOPM">
        <input type="hidden" name="client" value="$client">
        <input type="submit" value="Update" class="HF_submit button proceed-button">
        </form>
    ];

    return $resultHTML;
}

sub UpdatePrefOptinMember {
    my ( $action, $Data, $memberID ) = @_;
    my $optin_id = safe_param('oID','number') || 0;
    my $intAction = ( safe_param('optin', 'number') ne '' )? 1:0;
    my $db = $Data->{'db'};

    my $st = qq[
        UPDATE tblOptinMember
        SET intAction=?
        WHERE intOptinID=? AND intMemberID=?
    ];
    my $q = $db->prepare($st);
    $q->execute( $intAction, $optin_id, $memberID );

    my $resultHTML = qq[Updated<br>];
    my $client = setClient( $Data->{'clientValues'} ) || '';  
    my $text = qq[<p><a href="$Data->{'target'}?client=$client&amp;a=M_PREFS">Click here</a> to return to list of Preferences</p>];
    $resultHTML = qq[<br><br>].$resultHTML.qq[<br><br>$text];

    return $resultHTML;
}

sub EditPrefNewsletterOptin {
    my ( $action, $Data, $memberID ) = @_;

    my $type = safe_param('type', 'word') || '';
    my $db = $Data->{'db'};

    if ( $type eq 'edit' ) {
        my $newsletter_id = safe_param('nID','number') || 0;
        my $st = qq[
            SELECT
                N.strName,
                NOP.intAction
            FROM
                tblNewsletter AS N
                INNER JOIN tblNewsletterOptin AS NOP ON N.intNewsletterID=NOP.intNewsletterID
            WHERE
                N.intNewsletterID=?
                AND NOP.intMemberID=?
        ];
        my $q = $db->prepare($st);
        $q->execute($newsletter_id, $memberID);
        my $dref = $q->fetchrow_hashref();

        my $client = setClient( $Data->{'clientValues'} ) || '';  
        my $checked = $dref->{'intAction'}? 'checked':'';
        my $resultHTML = qq[
            <form action="$Data->{'target'}" method="post">
            <input type="checkbox" name="newsletter" value="$newsletter_id" $checked>$dref->{'strName'}<br>
            <input type="hidden" name="nID" value=$newsletter_id>
            <input type="hidden" name="a" value="M_PREFS_UNOP">
            <input type="hidden" name="client" value="$client">
            <input type="hidden" name="type" value="$type">
            <input type="submit" value="Update" class="HF_submit button proceed-button">
            </form>
    ];

        return $resultHTML;
    }
    elsif ( $type eq 'add' ) {
        my $st = qq[SELECT strEmail FROM tblMember WHERE intMemberID=?];
        my $q = $db->prepare($st);
        $q->execute($memberID);
        my $email = $q->fetchrow_array() || '';
        if ( $email eq '' ) {
            return "Your don't have any email address. Please edit your profile.";
        }

        $st = qq[
            SELECT DISTINCT
                N.intNewsletterID,
                N.strName
            FROM
                tblNewsletter AS N
                LEFT JOIN tblNewsletterOptin AS NOP ON ( N.intNewsletterID=NOP.intNewsletterID AND NOP.intMemberID=? )
            WHERE
                NOP.intNewsletterOptinID IS NULL
                AND N.intRealmID=?
       ];
        $q = $db->prepare($st);
        $q->execute($memberID, $Data->{'Realm'});
        my $href = $q->fetchall_hashref('intNewsletterID');

        if ( scalar( keys %$href ) == 0 ) {
            return "No available newsletter to subscribe.";
        }

        my $client = setClient( $Data->{'clientValues'} ) || '';  
        my $resultHTML = qq[
            <form action="$Data->{'target'}" method="post">
        ];

        for my $newsletter_id ( keys %$href ) {
            $resultHTML .= qq[
                <input type="checkbox" name="newsletter" value="$newsletter_id">$href->{$newsletter_id}->{'strName'}<br>
            ];
        }
        $resultHTML .= qq[
            <input type="hidden" name="a" value="M_PREFS_UNOP">
            <input type="hidden" name="client" value="$client">
            <input type="hidden" name="type" value="$type">
            <input type="submit" value="Update" class="HF_submit button proceed-button">
            </form>
        ];

        return $resultHTML;
    }
    else {
        return "Invalid action.";
    }
}

sub UpdatePrefNewsletterOptin {
    my ( $action, $Data, $memberID ) = @_;

    my $type = safe_param('type', 'word') || '';
    my $db = $Data->{'db'};

    if ( $type eq 'edit' ) {
        my $newsletter_id = safe_param('nID','number') || 0;
        my $intAction = ( safe_param('newsletter', 'number') ne '' )? 1:0;

        my $dt_field = $intAction?"dtOptIn":"dtOptOut";
        my $st = qq[
            UPDATE tblNewsletterOptin
            SET intAction=?, $dt_field=NOW()
            WHERE intNewsletterID=? AND intMemberID=?
        ];
        my $q = $db->prepare($st);
        $q->execute( $intAction, $newsletter_id, $memberID );
    }
    elsif( $type eq 'add' ) {
        my $st = qq[SELECT strEmail FROM tblMember WHERE intMemberID=?];
        my $q = $db->prepare($st);
        $q->execute($memberID);
        my $email = $q->fetchrow_array() || '';
        my @newsletter_ids = param('newsletter');

        $st = qq[
            INSERT INTO tblNewsletterOptin
            ( intNewsletterID, strEmail, intMemberID, dtOptIn, intAction )
            VALUES ( ?, ?, ?, NOW(), 1 )
        ];
        $q = $db->prepare($st);
        for my $newsletter_id (@newsletter_ids) {
            $q->execute( $newsletter_id, $email, $memberID );
        }
    }
    else {
        return "Invalid action.";
    }

    my $resultHTML = qq[Updated<br>];
    my $client = setClient( $Data->{'clientValues'} ) || '';  
    my $text = qq[<p><a href="$Data->{'target'}?client=$client&amp;a=M_PREFS">Click here</a> to return to list of Preferences</p>];
    $resultHTML = qq[<br><br>].$resultHTML.qq[<br><br>$text];

    return $resultHTML;
}

1;
