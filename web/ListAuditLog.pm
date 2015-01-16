package ListAuditLog;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    listPersonAuditLog
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
        ORDER BY 
            AL.dtUpdated DESC
    
	];
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute(
        $personID,
        $personID,
        $personID,
        $personID,
    );
	my @rowdata = ();
	while(my $ref= $sth->fetchrow_hashref()){
		push @rowdata,{
			Username=> $ref->{'strUsername'},
			UserEntity=> $ref->{'strLocalName'},
			Type => $ref->{'strType'},
			Section=> $ref->{'strSection'},
			DateUpdated=> $ref->{'dtUpdated'},
		};
	}
	$sth->finish();
	my $PageContent = {
		Lang => $Data->{'lang'},
		AuditLog=> \@rowdata,
	};
	 my $title = '';
	 my $resultHTML = runTemplate($Data, $PageContent, 'person/auditlog.templ') || '';
	 $title = 'Audit Trail';
	 return ($resultHTML, $title);
}

1;

