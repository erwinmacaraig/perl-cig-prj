package PlayerPassport;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(savePlayerPassport);

use strict;
use lib '.', '..', "comp", 'RegoForm', "dashboard", "RegoFormBuilder",'PaymentSplit', "user";
use Reg_common;
use CGI qw(:cgi unescape);
use Person;
use Data::Dumper;
use POSIX qw(strftime);
use Date::Parse;
use AuditLog;

sub savePlayerPassport{ 
	my ($Data, $personID) = @_;
	
    return if (! $personID);
	#DELETE RECORD
## MIGHT NEED TO TAKE THE IMPORTED RECORD INTO ACCOUNT IN WORKING OUT TIME PERIODS
	my $query = "DELETE FROM tblPlayerPassport WHERE intPersonID= ? and strOrigin= 'REGO'";
	my $sth = $Data->{'db'}->prepare($query); 
	$sth->execute($personID);
	
	$query = qq[
        SELECT 
            PR.intPersonRegistrationID, 
            PR.intPersonID, 
            PR.intEntityID, 
            PR.strPersonType, 
            PR.strPersonLevel, 
            PR.dtFrom, 
            IF(PR.dtFrom > DATE_ADD(dtDOB,INTERVAL 12 YEAR), PR.dtFrom, DATE_ADD(dtDOB,INTERVAL 12 YEAR)) as WhenFrom,
            PR.dtTo,
            PR.intNationalPeriodID, 
            strRealmName, 
            PR.strAgeLevel, 
            DATE_ADD(dtDOB,INTERVAL 12 YEAR) as When12,
            E.strLocalName as EntityName,
            IF(PR.dtTo > '1900-01-01', PR.dtTo, NOW()) as PRToCalc
        FROM tblPersonRegistration_$Data->{'Realm'} as PR
        INNER JOIN tblPerson as P ON (P.intPersonID=PR.intPersonID)
        INNER JOIN tblRealms ON (PR.intRealmID = tblRealms.intRealmID) 
        INNER JOIN tblEntity as E ON (E.intEntityID = PR.intEntityID)
        LEFT JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = PR.intNationalPeriodID)
        WHERE 
            PR.intPersonID = ? 
            AND PR.strPersonType = 'PLAYER' 
            AND PR.strSport = 'FOOTBALL' 
            AND PR.strStatus IN ('PASSIVE', 'ACTIVE', 'ROLLED_OVER', 'TRANSFERRED')
        HAVING
            PRToCalc > When12
        ORDER BY PR.dtFrom, NP.dtFrom
    ];	
            #YEAR(IF(PR.dtTo > '1900-01-01', PR.dtTo, NOW())) as yrDtTo,
            #YEAR(PR.dtTo) as yrDtTo,
            #AND PR.dtFrom<>PR.dtTo
	
	$sth = $Data->{'db'}->prepare($query); 
	$sth->execute($personID); 
	
	#get all Possible Registration candidate to be placed in tblPlayerPassport 
	# FROM these records choose the ones in which PersonAge >= 12 

    my $pref = Person::loadPersonDetails($Data->{'db'}, $personID);  #Get DOB
    my $yearBorn = $pref->{'dtDOB_year'};     
    
     
   
    my $stPP= qq[
        INSERT INTO tblPlayerPassport (
            intPersonID,
            strOrigin,
            strPersonLevel,
            intEntityID,
            strEntityName,
            strMAName,
            dtFrom, 
            dtTo
        )  
        VALUES (
            ?, 
            ?, 
            ?, 
            ?, 
            ?, 
            ?, 
            ?, 
            ?
     )];
     my $qPP = $Data->{'db'}->prepare($stPP); 
     
     my $eID = 0;
     my $level = '';
     my $dtFrom = '';
     my $dtTo = '';
     my $rowCount = 0;
     my $currentunixtimevalue = 0;
     my $tempunixtimevalue = 0;
     my %Reg = ();
     my $count = 0;
     my $regs; 
     my $lastRealmName = '';
     my $lastEntityName = '';
     while(my $dref = $sth->fetchrow_hashref()){
     	
     	###
     	#check age 
#     	next if( ($dref->{'yrDtTo'} - $yearBorn) < 12 );
     	if($rowCount == 0){
     		$eID = $dref->{'intEntityID'};
     		$level = $dref->{'strPersonLevel'}; 
     		#$dtFrom = $dref->{'dtFrom'};
     		#$dtFrom = $dref->{'WhenFrom'} if ($Data->{'SystemConfig'}{'PP_UseDOBasFrom'});
     		$dtFrom = $dref->{'WhenFrom'};
     		$dtTo = $dref->{'dtTo'}; 
            $lastRealmName = $dref->{'strRealmName'};
            $lastEntityName= $dref->{'EntityName'};
     		$rowCount++;
     		next;
     	}
     	
        $rowCount++;
        if( $eID != $dref->{'intEntityID'} || $level ne $dref->{'strPersonLevel'} ){
        	#need to get strEntityName, strMAName,  
            $dtTo = $dref->{'dtFrom'} if (!$dtTo or $dtTo eq '0000-00-00'); ## Set End date to start of next period if blank
        	$qPP->execute($personID,'REGO', $level, $eID, $lastEntityName,$lastRealmName, $dtFrom, $dtTo);
        	$eID = $dref->{'intEntityID'};
     		$level = $dref->{'strPersonLevel'}; 
     		#$dtFrom = $dref->{'dtFrom'};
     		#$dtFrom = $dref->{'WhenFrom'} if ($Data->{'SystemConfig'}{'PP_UseDOBasFrom'});
     		$dtFrom = $dref->{'WhenFrom'};
     		$dtTo = $dref->{'dtTo'}; 
            $lastRealmName = $dref->{'strRealmName'};
            $lastEntityName= $dref->{'EntityName'};
        }
        else {
        	 $currentunixtimevalue = str2time($dref->{'dtTo'});
    	     $tempunixtimevalue = str2time($dtTo);
    	     if($currentunixtimevalue > $tempunixtimevalue){
    	     	$dtTo = $dref->{'dtTo'}; 
    	     }
        }
        $lastRealmName = $dref->{'strRealmName'};
     } #end while
     
        if ($eID )  {
      $qPP->execute($personID,'REGO', $level, $eID, $lastEntityName, $lastRealmName, $dtFrom, $dtTo);
        }
        
	    $query = "UPDATE tblPlayerPassport SET dtTo = '0000-00-00' WHERE (dtTo IS NULL or dtTo>NOW()) AND intPersonID= ? and strOrigin= 'REGO'";
	    $sth = $Data->{'db'}->prepare($query); 
	    $sth->execute($personID);

	    #$query = "SELECT * FROM tblPlayerPassport WHERE intPersonID= ? ORDER BY intPlayerPassportID DESC LIMIT 1";
	    #$sth = $Data->{'db'}->prepare($query); 
	    #$sth->execute($personID);
        #my $dref = $sth->fetchrow_hashref();
        #if ($dref and $dref->{'strOrigin'} eq 'REGO')   {
	    #    $query = "UPDATE tblPlayerPassport SET dtTo = '0000-00-00' WHERE intPersonID= ? and intPlayerPassportID=? LIMIT 1";
	    #    $sth = $Data->{'db'}->prepare($query); 
	    #    $sth->execute($personID, $dref->{'intPlayerPassportID'});
        #}
        ###
		auditLog($personID, $Data, 'Add Player Passport', 'Player Passport');
		###
      # need to get the Date because we need to get the age
    
}
#####################################################################
1;

