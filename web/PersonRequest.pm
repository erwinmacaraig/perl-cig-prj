package PersonRequest;
require Exporter;
@ISA = qw(Exporter);

@EXPORT = @EXPORT_OK = qw(
    handlePersonRequest
    listPersonRecord
);

use lib ".", "..";
use strict;
use TTTemplate;
use GridDisplay;
use Reg_common;
use Utils;
use AuditLog;
use CGI qw(unescape param);
use Log;
use Data::Dumper;
use SystemConfig;
use Switch;


sub handlePersonRequest {
    my ($action, $Data) = @_;

    my $title = undef;
    my $body = undef;

    my %TemplateData = (
        Lang => $Data->{'lang'},
        client => $Data->{'client'},
        target => $Data->{'target'},
    );

    switch($action) {
        case 'PRA_T' {
            $title = "Request a Transfer";
            $TemplateData{'action'} = 'PRA_search';
            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_R' {
            $title = "Request Access to Person Details";
            $TemplateData{'action'} = 'PRA_search';
            $body = runTemplate(
                $Data,
                \%TemplateData,
                'personrequest/generic/search_form.templ',
            );
        }
        case 'PRA_search' {
            ($body, $title) = listPersonRecord($Data);
        }
        else {
        }
    }

	return ($body, $title);
}

sub listPersonRecord {
    my ($Data) = @_;

	my $p = new CGI;
	my %params = $p->Vars();

    my $client = setClient( $Data->{'clientValues'} ) || '';

    my $MID = safe_param('mid','number') || '';
    my $firstname = safe_param('firstname','word') || '';
    my $lastname = safe_param('lastname','word') || '';
    #TODO: might need to validate dob or use jquery datepicker
    my $dob = $params{'dob'} || '';

    my $title = $Data->{'lang'}->txt('Search Result');
    warn "PERSONREQUEST $MID";
    warn "PERSONFNAME $firstname";
    warn "PERSONLNAME $lastname";
    warn "PERSONDOB $dob";
    my %result;

    #TODO: might use priority column in the query, then limit the result to 1 grouped by club
    # FOOTBALL  | 1
    # FUTSAL    | 2
    # ACTIVE    | 1
    # PASSIVE   | 2
    # PENDING   | 3
    my $st = qq[
        SELECT
            E.intEntityID,
            E.strLocalName as currentClub,
            P.intPersonID,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.strStatus as personStatus,
            P.dtDOB,
            PR.intPersonRegistrationID,
            PR.strStatus as personRegistrationStatus,
            PR.strPersonType,
            PR.strSport,
            PR.strPersonLevel
        FROM
            tblPerson P
        INNER JOIN tblPersonRegistration_$Data->{'Realm'} PR
            ON (PR.intPersonID = P.intPersonID and PR.intRealmID = P.intRealmID and PR.strStatus in ('ACTIVE', 'PASSIVE','PENDING'))
        LEFT JOIN tblEntity E 
            ON (E.intEntityID = PR.intEntityID and E.intRealmID = PR.intRealmID)
        WHERE
            P.intRealmID = ?
            AND P.strStatus IN ('REGISTERED', 'PASSIVE','PENDING')
            AND
                (P.strLocalFirstname LIKE CONCAT('%',?,'%') OR P.strLocalSurname LIKE CONCAT('%',?,'%'))
            AND P.dtDOB = ?
    ];

    my $db = $Data->{'db'};
    my $q = $db->prepare($st) or query_error($st);
    $q->execute(
        $MID,
        $firstname,
        $lastname,
        $dob,
    ) or query_error($st);

    my $found = 0;
    my @rowdata = ();

    while(my $tdref = $q->fetchrow_hashref()) {
        $found = 1;
        print STDERR Dumper $tdref;

        my $actionLink = qq[ <span class="button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=PRA_initTransfer&amp;pid=$tdref->{'intPersonID'}&amp;prid=$tdref->{'intPersonRegistrationID'}">]. $Data->{'lang'}->txt('Transfer') . q[</a></span>];    
        push @rowdata, {
	        id => $tdref->{'intPersonRegistrationID'} || 0,
            currentClub => $tdref->{'currentClub'} || '',
            personStatus => $tdref->{'personStatus'} || '',
            personRegoStatus => $tdref->{'personRegistrationStatus'} || '',
            sport => $tdref->{'strSport'} || '',
            localFirstname => $tdref->{'strLocalFirstname'} || '',
            localSurname => $tdref->{'strLocalSurname'} || '',
            personType => $tdref->{'strPersonType'} || '',
            personLevel => $tdref->{'strPersonLevel'} || '',
            DOB => $tdref->{'dtDOB'} || '',
            actionLink => $actionLink,
            SelectLink => ''
        }
    }

    return ("$found record found.", $title) if !$found;

    my @headers = (
        { 
            type => 'Selector',
            field => 'SelectLink',
        }, 
        {
            name => $Data->{'lang'}->txt('Registered To'),
            field => 'currentClub',
        }, 
        {
            name => $Data->{'lang'}->txt('First Name'),
            field => 'localFirstname',
        },
        {
            name => $Data->{'lang'}->txt('Last Name'),
            field => 'localSurname',
        },
        {
            name => $Data->{'lang'}->txt('Date of birth'),
            field => 'DOB',
        },
        {
            name => $Data->{'lang'}->txt('Person Status'),
            field => 'personStatus',
        },
        {
            name => $Data->{'lang'}->txt('Sport'),
            field => 'sport',
        }, 
        {
            name => $Data->{'lang'}->txt('Type'),
            field => 'personType',
        }, 
        {
            name => $Data->{'lang'}->txt('Person Level'),
            field => 'personLevel',
        }, 
        {
            name => $Data->{'lang'}->txt('Registration Status'),
            field => 'personRegoStatus',
        },
        {
            name => $Data->{'lang'}->txt('Action'),
            field => 'actionLink',
            type => 'HTML', 
        },

    ); 

    my $rectype_options = '';
    my $grid = showGrid(
        Data => $Data,
        columns => \@headers,
        rowdata => \@rowdata,
        gridid => 'grid',
        width => '99%',
    ); 

    my $resultHTML = qq[
        <div class="grid-filter-wrap">
            <div style="width:99%;">$rectype_options</div>
            $grid
        </div>
    ];

    return ($resultHTML, $title);
}

1;
