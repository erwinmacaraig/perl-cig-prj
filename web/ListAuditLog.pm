package ListAuditLog;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    listPersonAuditLog
    listEntityAuditLog
);

use strict;
use lib '.', '..', 'Clearances';
use Defs;

use Reg_common;
use Utils;
use HTMLForm;
use FieldLabels;
use ConfigOptions qw(ProcessPermissions);
use GenCode;
use AuditLog;
use DeQuote;
use CGI qw(cookie unescape);
use ConfigOptions;
use GridDisplay;
use InstanceOf;
use Log;
use Data::Dumper;
use TTTemplate;


sub listPersonAuditLog    {
	my ($Data, $personID) = @_;

	my $query = qq[ 
        SELECT
            AL.strUsername,
            AL.strType,
            AL.strSection,
            AL.strLocalName,
            AL.dtUpdated
        FROM
            tblAuditLog as AL
            LEFT JOIN tblPersonRegistration_$Data->{'Realm'} as PR ON (
                PR.intPersonRegistrationID=AL.intID 
                AND AL.strSection="Person Registration"
            )
            LEFT JOIN tblWFTask as WFT ON (
                WFT.intWFTaskID = AL.intID 
                AND AL.strSection="WFTask"
            )
            LEFT JOIN tblPerson as P ON (
                P.intPersonID= AL.intID 
                AND AL.strSection IN ("Player Passport", "PERSON", "Person")
            )
        WHERE
            (
                AL.intID=? 
                OR PR.intPersonID=? 
                OR WFT.intPersonID=? 
                OR P.intPersonID=?
            )
            AND AL.strSection NOT IN ('Person Entity')
            AND (
                AL.strSection IN ("Player Passport", "PERSON", "Person", "Person Registration")
                OR (AL.strSection = "WFTask" AND WFT.intPersonID=?)
            )
        ORDER BY 
            AL.dtUpdated DESC
    
	];
    $query = qq[
        (
        SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
        WHERE
            AL.intEntityID=18
            AND AL.strSection IN ("Person Registration")
            AND AL.strType  LIKE 'Update Person Registration%'
            AND AL.intEntityTypeID=-1
    )
UNION ALL
    (
        SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
        WHERE
            AL.intEntityID=?
            AND AL.strSection IN ("Person Registration")
            AND AL.strType  LIKE 'Update Person Registration%'
            AND AL.intEntityTypeID>=0
    )
UNION ALL
     (
        SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
            INNER JOIN tblPersonRegistration_1 as PR ON (
                PR.intPersonRegistrationID=AL.intID
                AND AL.strSection="Person Registration"
            )
        WHERE
            PR.intPersonID=?
            AND AL.strSection NOT IN ('Person Entity')
            AND AL.strSection IN ("Player Passport", "PERSON", "Person", "Person Registration")
            AND AL.strType NOT LIKE 'Update Person Registration%'
    )
UNION ALL
    (
     SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
            LEFT JOIN tblWFTask as WFT ON (
                WFT.intWFTaskID = AL.intID
                AND AL.strSection="WFTask"
            )
        WHERE
            WFT.intPersonID=?
            AND AL.strSection NOT IN ('Person Entity')
            AND (AL.strSection = "WFTask" AND WFT.intPersonID=?)
    )
UNION ALL
    (
     SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
            INNER JOIN tblPerson as P ON (
                P.intPersonID= AL.intID
                AND AL.strSection IN ("Player Passport", "PERSON", "Person")
            )
        WHERE
            (
                AL.intID=?
                OR P.intPersonID=?
            )
            AND AL.strSection NOT IN ('Person Entity')
            AND (
                AL.strSection IN ("Player Passport", "PERSON", "Person")
            )
    )
    ORDER BY
            dtUpdated DESC
    ];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID,
        $personID,
        $personID,
        $personID,
        $personID,
        $personID,
    );
	my @rowdata = ();
	while(my $ref= $sth->fetchrow_hashref()){
        my $dt = $Data->{'l10n'}{'date'}->TZformat($ref->{'dtUpdated'},'MEDIUM','SHORT');
		push @rowdata,{
			Username=> $ref->{'strUsername'},
			UserEntity=> $ref->{'strLocalName'},
			Type => $ref->{'strType'},
			Section=> $ref->{'strSection'},
			DateUpdated=> $dt,
		};
	}
	$sth->finish();
	my $PageContent = {
		Lang => $Data->{'lang'},
		AuditLog=> \@rowdata,
	};
	 my $title = '';
	 my $resultHTML = runTemplate($Data, $PageContent, 'person/auditlog.templ') || '';
	 $title = $Data->{'lang'}->txt('Audit Trail');
	 return ($resultHTML, $title);
}
sub listEntityAuditLog {
	my ($Data, $entityID) = @_;

	my $query = qq[ 
        SELECT
            AL.strUsername,
            AL.strType,
            AL.strSection,
            AL.strLocalName,
            AL.dtUpdated
        FROM
            tblAuditLog as AL
            LEFT JOIN tblWFTask as WFT ON (
                WFT.intWFTaskID = AL.intID 
                AND AL.strSection="WFTask"
                AND WFT.intPersonID=0
                AND WFT.strWFRuleFor = "ENTITY"
            )
            LEFT JOIN tblEntity as E ON (
                E.intEntityID= AL.intID 
                AND AL.strSection IN ("Imported", "Club", "Entity", "Venue")
            )
        WHERE
            (
                AL.intID=? 
                OR WFT.intEntityID=? 
                OR E.intEntityID=?
            )
            AND (
                AL.strSection IN ("Imported", "Club", "Entity", "Venue")
                OR (AL.strSection = "WFTask" AND WFT.intEntityID=?)
            )
        ORDER BY 
            AL.dtUpdated DESC
    
	];
    $query = qq[
(SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
            INNER JOIN tblEntity as E ON (
                E.intEntityID= AL.intID
                AND AL.strSection IN ("Imported", "Club", "Entity", "Venue")
            )
        WHERE
            AL.intID=?
            AND AL.strSection IN ("Imported", "Club", "Entity", "Venue")
)
UNION ALL
( SELECT DISTINCT AL.strUsername, AL.strType, AL.strSection, AL.strLocalName, AL.dtUpdated
        FROM
            tblAuditLog as AL
            INNER JOIN tblWFTask as WFT ON (
                WFT.intWFTaskID = AL.intID
                AND AL.strSection="WFTask"
                AND WFT.intPersonID=0
                AND WFT.strWFRuleFor = "ENTITY"
            )
        WHERE
            WFT.intEntityID=?
            AND AL.strSection = "WFTask" AND WFT.intEntityID=?
)
        ORDER BY
            dtUpdated DESC
    ];

	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $entityID,
        $entityID,
        $entityID,
    );
	my @rowdata = ();
	while(my $ref= $sth->fetchrow_hashref()){
        my $dt = $Data->{'l10n'}{'date'}->TZformat($ref->{'dtUpdated'},'MEDIUM','SHORT');
		push @rowdata,{
			Username=> $ref->{'strUsername'},
			UserEntity=> $ref->{'strLocalName'},
			Type => $ref->{'strType'},
			Section=> $ref->{'strSection'},
			DateUpdated=> $dt,
		};
	}
	$sth->finish();
	my $PageContent = {
		Lang => $Data->{'lang'},
		AuditLog=> \@rowdata,
	};
	 my $title = '';
	 my $resultHTML = runTemplate($Data, $PageContent, 'entity/auditlog.templ') || '';
	 $title = 'Audit Trail';
	 return ($resultHTML, $title);
}
1;

