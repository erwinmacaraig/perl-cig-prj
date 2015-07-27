package PersonCertifications;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  getPersonCertifications
  getPersonCertificationTypes
  addPersonCertification
  deletePersonCertification
  cleanPersonCertifications         
);

use strict;
use lib '.', '..';
use Defs;
use HTMLForm;
use Reg_common;
use AuditLog;
use Data::Dumper;
use GridDisplay;
use CGI qw(param unescape escape cookie);
 
sub cleanPersonCertifications   {
    
	my ($Data, $personID) = @_; 

    my $st = qq[
        SELECT 
            MAX(CT.intActiveOrder) as maxOrder, 
            CT.strGroupSport,
            CT.strCertificationType
        FROM 
            tblPersonCertifications as PC 
            INNER JOIN tblCertificationTypes as CT ON (PC.intCertificationTypeID = CT.intCertificationTypeID)
        WHERE
            PC.intPersonID = ?
            AND PC.intRealmID = ?
            AND PC.strStatus = 'ACTIVE'
        GROUP BY        
            CT.strCertificationType,
            CT.strGroupSport
    ];
    my $qry = $Data->{'db'}->prepare($st); 
    $qry->execute(
        $personID,
        $Data->{'Realm'}
    );

    my $upd = qq[
        UPDATE 
            tblPersonCertifications as PC
            INNER JOIN tblCertificationTypes as CT ON (PC.intCertificationTypeID = CT.intCertificationTypeID)
        SET 
            PC.strPreviousStatus = IF(PC.strPreviousStatus<>'', PC.strPreviousStatus, PC.strStatus),
            PC.strStatus = 'INACTIVE'
        WHERE
            CT.strCertificationType = ?
            AND CT.strGroupSport= ?
            AND PC.intPersonID = ?
            AND CT.intActiveOrder < ?
            AND CT.intActiveOrder > 0
            AND PC.intRealmID = ?
            AND PC.strStatus = 'ACTIVE'
    ];
    my $qryUpd = $Data->{'db'}->prepare($upd); 
    while(my $dref = $qry->fetchrow_hashref()){
        $qryUpd->execute(
            $dref->{'strCertificationType'},
            $dref->{'strGroupSport'},
            $personID,
            $dref->{'maxOrder'},
            $Data->{'Realm'}
        );
    }
}

sub handleCertificates {
	my ($action, $Data, $personID) = @_; 
	my $client = setClient($Data->{'clientValues'});
	my $resultHTML='' ;
	#Get Certification of Person Based on Certificate ID
	my $intCertificationID = param('certID') || 0;
    
	my $cert_fields = loadCertificationDetails($Data,$intCertificationID);
	my $option;
	if($action =~ /P_CERT_A/){
		$option = 'add';		
 	}
	elsif($action =~ /P_CERT_ED/){
		$option = 'edit';
	}
	elsif($action =~ /P_CERT_VW/){
		$option = 'display';
	}
	else {
		#Display Grid	
			
		my $rawrowdata = getPersonCertifications($Data,$personID,'',1);	
		my @rowdata = ();
		my $link;
        my $lang = $Data->{'lang'};
		foreach my $rowdataref ( @{$rawrowdata} ){

			$link = "$Data->{'target'}?client=$client&amp;a=P_CERT_ED&amp;certID=$rowdataref->{'intCertificationID'}";
			push @rowdata,{
				id => $rowdataref->{'intCertificationID'},
				SelectLink => $link,
				strCertificationType => $lang->txt($Defs::personType{$rowdataref->{'strCertificationType'}}),
				strCertificationName => $lang->txt($rowdataref->{'strCertificationName'}),
				dtValidFrom          => $Data->{'l10n'}{'date'}->format($rowdataref->{'dtValidFrom'},'MEDIUM'),
				dtValidFrom_RAW      => $rowdataref->{'dtValidFrom'},
				dtValidUntil         => $Data->{'l10n'}{'date'}->format($rowdataref->{'dtValidUntil'},'MEDIUM'),
				dtValidUntil_RAW     => $rowdataref->{'dtValidUntil'},
				strStatus            => $lang->txt($Defs::person_certification_status{$rowdataref->{'strStatus'}}),
				strDescription       => $rowdataref->{'strDescription'},				
			};
		}
		my @headers = (
            {
                name =>   $lang->txt('Certification Type'),
                field =>  'strCertificationType',
                defaultShow => 1,
            },
            {
                name =>   $lang->txt('Certification Name'),
                field =>  'strCertificationName',
                defaultShow => 1,
           },
           {
               name =>   $lang->txt('Valid From'),
               field =>  'dtValidFrom',
               sortdata =>  'dtValidFrom_RAW',
          },
          {
              name =>   $lang->txt('Valid Until'),
              field =>  'dtValidUntil',
              sortdata =>  'dtValidUntil_RAW',
         },
         {
              name =>   $lang->txt('Status'),
              field =>  'strStatus',
         },   
        {
            type => 'Selector',
            field => 'SelectLink',
        },
  );
         #{
         #	name => 'Description',
         #	field => 'strDescription',
         #},
   my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '100%',
    height => 700,
  );

    my $addlink=qq[<a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A" class = "btn-main">].$Data->{'lang'}->txt('Add Certification').qq[</a>] if(!$Data->{'ReadOnlyLogin'});
	my $modoptions=qq[<div class="button-row pull-right">$addlink</div>];
	$resultHTML = qq[ 
		$grid
        $modoptions
	];
	my $title=$Data->{'lang'}->txt('Certifications');

 	return ($resultHTML,$title);			
	}
	#end else
	############################################ FORM SECTION #############################
 
    my $query = qq[SELECT intCertificationTypeID, CONCAT(strCertificationType, ' - ', strCertificationName) AS Certificates FROM tblCertificationTypes WHERE intRealmID = ? AND intActive = 1 ORDER BY strCertificationType, intDisplayOrder, strCertificationName  ];
    my $st = $Data->{'db'}->prepare($query); 
    $st->execute($Data->{'Realm'});
    my %certificateTypes = (); 
    my @certificationTypesOrder=();
    while(my $dref = $st->fetchrow_hashref()){
    	$certificateTypes{$dref->{'intCertificationTypeID'}} = $dref->{'Certificates'}; 
        push @certificationTypesOrder, $dref->{'intCertificationTypeID'};
    }    
	my %FieldDefinitions=(
   	    fields=>  {
            intCertificationTypeID => {
                label       => 'Certifcation Type',
                value       =>  $cert_fields->{'intCertificationTypeID'},
                type        => 'lookup',
                options     => \%certificateTypes,
                order       => \@certificationTypesOrder,
                firstoption => [ '', $Data->{'lang'}->txt('Select Certification') ],
                translateLookupValues => 1,
                    compulsory => 1,
            },
            dtValidFrom => {
                label       => 'Date Valid From',
                value       => $cert_fields->{'dtValidFrom'},
                type        => 'date',
                datetype    => 'dropdown',
                format      => 'dd/mm/yyyy',
                 validate    => 'DATE',                    
              },
              dtValidUntil => {
                   label       => 'Date Valid Until',
                   value       => $cert_fields->{'dtValidUntil'},
                   type        => 'date',
                   datetype    => 'dropdown',
                   format      => 'dd/mm/yyyy',
                  validate    => 'DATE',                
              }, 
               strStatus => {
                   label       => 'Status',
                   value       => $cert_fields->{'strStatus'},
                   type        => 'lookup',
                   options     => \%Defs::person_certification_status,
                   firstoption => [ '', $Data->{'lang'}->txt('Status') ],           
                   translateLookupValues => 1,
                    compulsory => 1,
              },
              strDescription => {
      	           label => 'Description',
                   value => $cert_fields->{'strDescription'},
                   type => 'textarea',
                   rows => '10',
                   cols => '40',       
              },
   		    },
      sections => [
                [ 'main', 'Certifications' ],
      ],
               order => [qw(intCertificationID intCertificationTypeID strStatus dtValidFrom dtValidUntil strDescription)],            
               options => {
                   labelsuffix => ':',
                   hideblank => 1,
                   target => $Data->{'target'},
                   formname => 'n_form',
                   submitlabel => $Data->{'lang'}->txt('Update'),
                   introtext => '',
                   NoHTML => 1,
                   updateSQL => qq[
                         UPDATE tblPersonCertifications
                         SET --VAL--
                         WHERE intCertificationID = $intCertificationID
                    ],
                    addSQL => qq[
        INSERT INTO tblPersonCertifications (
        	intPersonID,
            intRealmID,
            --FIELDS--
         )
          VALUES (
            $personID, 
            $Data->{'Realm'},
            --VAL-- )
        ],
      auditFunction=> \&auditLog,
      auditAddParams => [
        $Data,
        'Add',
        'Person Certificate'
      ],
      auditEditParams => [
        $personID,
        $Data,
        'Update',
        'PersonCertification'
      ],
      afteraddFunction => \&postCertificateAdd,
      afteraddParams => [$Data, $personID],
      afterupdateFunction => \&postCertificateUpdate,
      afterupdateParams => [$Data, $client, $intCertificationID, $personID],
      LocaleMakeText => $Data->{'lang'},
               	
               },
      carryfields =>  {
      client => $client,
      a=> $action,
      certID => $intCertificationID, 
    },
          );
		
		 
	
   ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, 1, $Data->{'db'});	
  
 
   my $title = $Data->{'lang'}->txt('Person Certifications');
   
   return $resultHTML,$title;
#######################################################################################
	
	
	
} # end handleCertificates


sub postCertificateUpdate {
	my($id,$params,$Data,$client,$intCertificationID, $personID) = @_; 	
	#my $client = setClient($Data->{'clientValues'});	 
    my $lang = $Data->{'lang'};
    cleanPersonCertifications($Data, $personID);
	return (0,qq[
        <div class="OKmsg"> ].$lang->txt('Certificate Updated Successfully').qq[</div><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_VW&amp;certID=$intCertificationID">].$lang->txt('To View Certificate Details').qq[</a><br><br>
        <b>].$lang->txt('or').qq[</b><br><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A">].$lang->txt('Add Another Certificate').qq[</a>
      ]);
}

sub postCertificateAdd {
  my($id,$params,$Data, $personID)=@_;
     cleanPersonCertifications($Data, $personID);
	my $client = setClient($Data->{'clientValues'});	 
    my $lang = $Data->{'lang'};
	return (0,qq[
        <div class="OKmsg"> ].$lang->txt('Certificate Added Successfully').qq[</div><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_">].$lang->txt('To Return To Person Certificates').qq[</a><br><br>
        <b>].$lang->txt('or').qq[</b><br><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A">].$lang->txt('Add Another Certificate').qq[</a>
      ]);
	
}

sub loadCertificationDetails{
	my ($Data,$intCertificationID) = @_; 
	my $query = "SELECT * FROM tblPersonCertifications WHERE intCertificationID = ?"; 
	my $sth = $Data->{'db'}->prepare($query);
	$sth->execute($intCertificationID);
	my $resultref = $sth->fetchrow_hashref();
	$sth->finish();
	return $resultref;	
}
sub getPersonCertifications {

    my (
        $Data, 
        $personID,
        $type,
        $all,
    ) = @_;

    $all ||= 0;
    $type ||= '';
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if($db) {
        my $statusfilter = $all ? '' : " AND strStatus = 'ACTIVE' ";
        my $typefilter = '';
        my @vals = (
            $realmID,
            $personID,
        );
        if($type)   {
            $typefilter = " AND CT.strCertificationType = ? ";
            push @vals, $type;
        }
        my $statement=qq[
            SELECT 
                PC.intCertificationID,
                PC.intPersonID,
                PC.intCertificationTypeID,
                PC.dtValidFrom,
                PC.dtValidUntil,
                DATE_FORMAT(PC.dtValidFrom,'%d %b %Y') AS dtValidFrom_Formatted,
                DATE_FORMAT(PC.dtValidUntil,'%d %b %Y') AS dtValidUntil_Formatted,
                PC.strDescription,
                PC.strStatus,
                CT.strCertificationName,
                CT.strCertificationType
            FROM 
                tblPersonCertifications AS PC
                INNER JOIN tblCertificationTypes AS CT
                    ON PC.intCertificationTypeID = CT.intCertificationTypeID
            WHERE 
                PC.intRealmID = ?
                AND PC.intPersonID = ?
                $statusfilter
                $typefilter

            ORDER BY
                CT.strCertificationType,
                PC.dtValidFrom,
                PC.dtValidUntil
        ];
                #AND UNIX_TIMESTAMP(PC.dtValidFrom) != 0
                #AND UNIX_TIMESTAMP(PC.dtValidUntil) != 0

        my $query = $db->prepare($statement);
        $query->execute(@vals);
        while (my $dref = $query->fetchrow_hashref) {
            $dref->{'Status'} = $Defs::person_certification_status{$dref->{'strStatus'}} || '';
            push @certifications, $dref;
        }
    }
    return \@certifications;
}

sub getPersonCertificationTypes {

    my (
        $Data, 
        $type,
    ) = @_;

    $type ||= '';
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if($db) {
        my $typefilter = '';
        my @vals = (
            $realmID,
        );
        if($type)   {
            $typefilter = " AND CT.strCertificationType = ? ";
            push @vals, $type;
        }
        my $statement=qq[
            SELECT 
                CT.intCertificationTypeID,
                CT.strCertificationType,
                CT.strCertificationName
            FROM 
                tblCertificationTypes AS CT
            WHERE 
                CT.intRealmID = ?
                AND intActive = 1
                $typefilter

            ORDER BY
                CT.strCertificationType,
                CT.intDisplayOrder,
                CT.strCertificationName
        ];
        my $query = $db->prepare($statement);
        $query->execute(@vals);
        while (my $dref = $query->fetchrow_hashref) {
            push @certifications, $dref;
        }
    }
    return \@certifications;
}

sub addPersonCertification {

    my (
        $Data, 
        $personID,
        $type,
        $from,
        $until,
        $description,
        $status,
    ) = @_;

    $status ||= 'ACTIVE';
    $description ||= '';
    $from ||= '';
    $until ||= '';
    

    $type ||= 0;
    my @certifications = ();
    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    
    if(!$personID and $type)    {
        return 0;
    }
    if($db) {
        my $statement=qq[
            INSERT INTO tblPersonCertifications (
                intPersonID,
                intRealmID,
                intCertificationTypeID,
                dtValidFrom,
                dtValidUntil,
                strDescription,
                strStatus
            )
            VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?
            ) 
        ];
        my $query = $db->prepare($statement);
        $query->execute((
            $personID,
            $realmID,
            $type,
            $from,
            $until,
            $description,
            $status,
        ));
        if($DBI::errstr)    {
            warn($DBI::errstr);
            return 0;
        }
        cleanPersonCertifications($Data, $personID);
        
        return 1;
    }
}

1;
