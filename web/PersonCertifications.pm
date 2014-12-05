package PersonCertifications;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
  getPersonCertifications
  getPersonCertificationTypes
  addPersonCertification
  deletePersonCertification
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
		foreach my $rowdataref ( @{$rawrowdata} ){
			#print FH "RowDataRef Data FROM PersonCertifications.pm\n" . Dumper($rowdataref) . "\n=================\n"; 
			$link = "$Data->{'target'}?client=$client&amp;a=P_CERT_ED&amp;certID=$rowdataref->{'intCertificationID'}";
			push @rowdata,{
				id => $rowdataref->{'intCertificationID'},
				SelectLink => $link,
				strCertificationType => $rowdataref->{'strCertificationType'},
				strCertificationName => $rowdataref->{'strCertificationName'},
				dtValidFrom          => $rowdataref->{'dtValidFrom'},
				dtValidUntil         => $rowdataref->{'dtValidUntil'},
				strStatus            => $rowdataref->{'strStatus'},
				strDescription       => $rowdataref->{'strDescription'},				
			};
		}
		my @headers = (
            {
                type => 'Selector',
                field => 'SelectLink',
            },
            {
                name =>   'Certification Type',
                field =>  'strCertificationType',
            },
            {
                name =>   'Certification Name',
                field =>  'strCertificationName',
           },
           {
               name =>   'Valid From',
               field =>  'dtValidFrom',
          },
          {
              name =>   'Valid Until',
              field =>  'dtValidUntil',
         },
         {
              name =>   'Status',
              field =>  'strStatus',
         },   
         {
         	name => 'Description',
         	field => 'strDescription',
         },
  );
   my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '99%',
    height => 700,
  );

	$resultHTML = qq[ 
		$grid
	];
	my $title='List Of Certifications';
	my $addlink='';
    {
      $addlink=qq[<a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A" class = "btn-main">].$Data->{'lang'}->txt('Add Certification').qq[</a>] if(!$Data->{'ReadOnlyLogin'});

    }
	my $modoptions=qq[<div class="changeoptions">$addlink</div>];
    $title=$modoptions.$title;
 	return ($resultHTML,$title);			
	}
	#end else
	############################################ FORM SECTION #############################
 
    my $query = qq[SELECT intCertificationTypeID, CONCAT(strCertificationType, ' - ', strCertificationName) AS Certificates FROM tblCertificationTypes WHERE intRealmID = ? AND intActive = 1];
    my $st = $Data->{'db'}->prepare($query); 
    $st->execute($Data->{'Realm'});
    my %certificateTypes = (); 
    while(my $dref = $st->fetchrow_hashref()){
    	$certificateTypes{$dref->{'intCertificationTypeID'}} = $dref->{'Certificates'}; 
    }    
	my %FieldDefinitions=(
   	    fields=>  {
            intCertificationTypeID => {
                label       => 'Certifcation Type',
                value       =>  $cert_fields->{'intCertificationTypeID'},
                type        => 'lookup',
                options     => \%certificateTypes,
                firstoption => [ '', 'Select Certification' ],
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
                   firstoption => [ '', 'Status' ],           
              },
              strDescription => {
      	           label => 'Description',
                   value => $cert_fields->{'strDescription'},
                   type => 'textarea',
                   rows => '10',
                   cols => '40',       
              },
   		    },
               order => [qw(intCertificationID intCertificationTypeID strStatus dtValidFrom dtValidUntil strDescription)],            
               options => {
                   labelsuffix => ':',
                   hideblank => 1,
                   target => $Data->{'target'},
                   formname => 'n_form',
                   submitlabel => $Data->{'lang'}->txt('Update'),
                   introtext => $Data->{'lang'}->txt('HTMLFORM_INTROTEXT'),
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
      afteraddParams => [$Data, $client],
      afterupdateFunction => \&postCertificateUpdate,
      afterupdateParams => [$Data, $client, $intCertificationID],
      LocaleMakeText => $Data->{'lang'},
               	
               },
      carryfields =>  {
      client => $client,
      a=> $action,
      certID => $intCertificationID, 
    },
          );
		
		 
	
   ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, 1, $Data->{'db'});	
  
   
 
  my $title = 'Person Certifications';
  
   
   return $resultHTML,$title;
#######################################################################################
	
	
	
} # end handleCertificates


sub postCertificateUpdate {
	my($id,$params,$Data,$client,$intCertificationID) = @_; 	
	#my $client = setClient($Data->{'clientValues'});	 
	return (0,qq[
        <div class="OKmsg"> Certificate Updated Successfully</div><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_VW&amp;certID=$intCertificationID">To View Certificate Details </a><br><br>
        <b>or</b><br><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A">Add Another Certificate</a>
      ]);
}

sub postCertificateAdd {
  my($id,$params,$Data)=@_;
	my $client = setClient($Data->{'clientValues'});	 
	return (0,qq[
        <div class="OKmsg"> Certificate Added Successfully</div><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_">To Return To Person Certificates</a><br><br>
        <b>or</b><br><br>
        <a href="$Data->{'target'}?client=$client&amp;a=P_CERT_A">Add Another Certificate</a>
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
        print FH "Query is: $statement \n\n";
        my $query = $db->prepare($statement);
        $query->execute(@vals);
        while (my $dref = $query->fetchrow_hashref) {
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
        return 1;
    }
}

1;
