#!/usr/bin/perl 

use strict;
use warnings;
use CGI qw(param escape);
use lib "..",".";
use Defs;
use Reg_common;
use Utils;
use Lang;
use SystemConfig;
use ConfigOptions;
use PageMain;
use MCache;
use TTTemplate;
use InstanceOf;
use Countries;
use Localisation;
use PersonCard;

main();	

sub main	{
	# GET INFO FROM URL
  my $client=param('client') || '';

  my %Data=();
  my $target='printcard.cgi';
  $Data{'target'}=$target;
  my %clientValues = getClient($client);
  $Data{'clientValues'} = \%clientValues;
  $Data{'cache'}  = new MCache();

  $Data{'AddToPage'} = new AddToPage();

  my $db=allowedTo(\%Data);
  ($Data{'Realm'},$Data{'RealmSubType'})=getRealm(\%Data);

  getDBConfig(\%Data);
  $Data{'SystemConfig'}=getSystemConfig(\%Data);
  my $batchID = getExistingBatchID(\%Data);
  my $batchInfo = $batchID 
    ? getBatchInfo(\%Data, $batchID)    
    : {};
  my $locale = $batchInfo->{'strLocale'} || '';
  my $lang   = Lang->get_handle($locale, $Data{'SystemConfig'}) || die "Can't get a language handle!";
  $Data{'lang'}=$lang;
  $Data{'LocalConfig'}=getLocalConfig(\%Data);

  my $DataAccess_ref=getDataAccess(\%Data);
  $Data{'Permissions'}=GetPermissions(
    \%Data,
    $clientValues{'authLevel'},
    getID(\%clientValues, $clientValues{'authLevel'}),
    $Data{'Realm'},
    $Data{'RealmSubType'},
    $clientValues{'authLevel'},
    0,
  );


  $Data{'DataAccess'}=$DataAccess_ref;

  initLocalisation(\%Data);
  updateSystemConfigTranslation(\%Data);

  my $resultHTML = '';
  my %TemplateData = ();
  if($batchID)   {
    my $cardInfo = getCardInfo(\%Data, $batchInfo->{'intCardID'});
    my $cardData = generateCardData(\%Data, $batchID, $cardInfo);
    my $ma = getInstanceOf(\%Data, 'national');

    my $locale = $Data{'lang'}->getLocale();
    $resultHTML = runTemplate(
      \%Data,
      {
        cardData => $cardData,
        cardInfo => $cardInfo,
        maName => $ma->name(),
      },
      'cardprint/cards/'.$cardInfo->{'strTemplateFilename'} || '',
    );
  }

  if($resultHTML)   {
    print "Content-type: text/html\n\n";
    print $resultHTML;
  }
  else  {
    $resultHTML = $Data{'lang'}->txt('No cards available to be printed');
    printBasePage($resultHTML, 'FIFA Connect');
  }
  disconnectDB($db);

}

sub generateCardData {
    my ($Data, $batchID, $cardInfo) = @_;

    return undef if !$cardInfo;
    my $cardtypes = join("','",@{$cardInfo->{'types'}});

    my $isocountries  = getISOCountriesHash();
    my $realmID = $Data->{'Realm'} || 1;
    my $st = qq[
      SELECT DISTINCT
        PR.*,
        E.strLocalName AS EntityLocalName,
        E.strLocalShortName AS EntityLocalShortName,
        E.strLatinName AS EntityLatinName,
        E.strLatinShortName AS EntityLatinShortName,
        E.strMAID AS EntityMAID,
        IF(PR.dtTo = '0000-00-00' or PR.dtTo IS NULL or PR.dtTo = '', NP.dtTo, PR.dtTo) as dtTo
      FROM
        tblPersonCardPrint AS PCP  
        INNER JOIN tblPersonRegistration_$realmID AS PR ON (
            PCP.intPersonID = PR.intPersonID
            AND PR.strStatus = 'ACTIVE'
            AND PR.strPersonType IN ('$cardtypes')
        )
        INNER JOIN tblEntity AS E
            ON PR.intEntityID = E.intEntityID
        LEFT JOIN tblNationalPeriod AS NP
            ON PR.intNationalPeriodID = NP.intNationalPeriodID
      WHERE
        PCP.intBatchID = ?
    ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute($batchID);
    my %regodata = ();
    while(my $dref = $q->fetchrow_hashref())   {
        my $pID = $dref->{'intPersonID'} || 0;

        $dref->{'Status'} = $Defs::personRegoStatus{$dref->{'strStatus'}} || '';
        $dref->{'RegoType'} = $Defs::registrationNature{$dref->{'strRegistrationNature'}} || '';
        $dref->{'Sport'} = $Defs::sportType{$dref->{'strSport'}} || '';
        $dref->{'Level'} = $Defs::personLevel{$dref->{'strPersonLevel'}} || '';
        $dref->{'AgeLevel'} = $Defs::ageLevel{$dref->{'strAgeLevel'}} || '';
        $dref->{'PersonType'} = $Defs::personType{$dref->{'strPersonType'}} || '';

        push @{$regodata{$pID}}, $dref;
    }
    $q->finish();

    $st = qq[
      SELECT DISTINCT
        P.*,
        L.strFilename

      FROM
        tblPersonCardPrint AS PCP  
        INNER JOIN tblPerson AS P ON 
            PCP.intPersonID = P.intPersonID
        LEFT JOIN tblLogo AS L
            ON (
                L.intEntityID = P.intPersonID
                AND L.intEntityTypeID = $Defs::LEVEL_PERSON
            )
      WHERE
        PCP.intBatchID = ?
      ORDER BY
            P.strLocalSurname,
            P.strLocalFirstname
    ];

    $q = $Data->{'db'}->prepare($st);
    $q->execute($batchID);
    my @carddata = ();
    while(my $dref = $q->fetchrow_hashref())   {
        my $pID = $dref->{'intPersonID'} || 0;
        $dref->{'nationality'} = $isocountries->{$dref->{'strISONationality'}};
        $dref->{'gender'} = $Defs::genderInfo->{$dref->{'intGender'}};
        $dref->{'registrations'} = $regodata{$pID} || [];
        if($dref->{'strFilename'})  {
            my %tmp_clientValues = %{$Data->{'clientValues'}};
            $tmp_clientValues{'currentLevel'} = $Defs::LEVEL_PERSON;
            setClientValue(\%tmp_clientValues,$Defs::LEVEL_PERSON, $pID);
            my $newclient = setClient(\%tmp_clientValues);
            $dref->{'photo'} = "$Defs::base_url/photologo.cgi?client=$newclient";
        }

        push @carddata, $dref;
    }
    $q->finish();
    return \@carddata || undef;
}

