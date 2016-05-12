#!/usr/bin/perl
use strict;
use warnings;

use CGI qw(param escape unescape);

use lib "../user","../..","..",".";

use Defs;
use DBI;
use Utils;
use AdminPageGen;
use FormHelpers;
use UserObj;
use EntityObj;
use MCache;
use SphinxUpdate;
use InstanceOf;

main();

sub main  {
  my $target='person_finder.cgi';
  my $returnstr='';
  my $action=param('a') || '';
  my $entityType =param('t') || '';
  my $personID= param('pID') || 0;
  my $regoID= param('regoID') || 0;
  my $db=connectDB();

  if($action eq "sr")  {
     $returnstr=search_results($db, $target);
  }
  elsif($action eq "vr")  {
     $returnstr=viewRegos($db, $personID, $target);
  }
  elsif($action eq "srs")  {
     $returnstr=setRegoStatus($db, $personID, $regoID, $target);
  }
  elsif($action eq "links")  {
     $returnstr=linkOldAccounts($db);
  }
  elsif($action eq "sd")  {
     $returnstr=setDeleted($db, $personID);
    $returnstr= searchpage($db, $target);
  }
  else  {
    $returnstr= searchpage($db, $target);
  }
  $returnstr .= qq[<p><a href = "person_finder.cgi">Return to Person Finder</a></p>];
  print_adminpageGen($returnstr, "", "");
}

sub linkOldAccounts{
    my ($db)=@_;

    my $st= qq[ 
        SELECT MAX(intPersonID)
        FROM tblOldSystemAccounts
    ];
    my $query = $db->prepare($st);
    $query->execute();
    my $personId = $query->fetchrow_array() || 0;

    if ($personId)  {
        ## If it has been run before
        $st = qq[
            INSERT IGNORE INTO tblOldSystemAccounts (intPersonID, strUsername, strPassword) 
            SELECT intPersonID, strNationalNum, DATE_FORMAT(dtDOB,"%y%m%d") from tblPerson where intPersonID > ? and strNationalNum <> ''
        ];

        $query = $db->prepare($st);
        $query->execute($personId);
    }
        
    return qq[
        <h1>Account Linkage Updated</h1>
        <br>
    ];
}


sub setDeleted  {

    my ($db, $personID) = @_;
    
    $personID ||= 0;
    return if (! $personID);

    my $st = qq[
        UPDATE 
            tblPerson
        SET
            strStatus='DELETED',
            intSystemStatus = -1
        WHERE
            intPersonID = ?
        LIMIT 1;
    ];
    my $query = $db->prepare($st);
    $query->execute($personID);
    return;
}
    

sub searchpage {
  my ($db, $target)=@_;

  my $st= qq[ 
    SELECT intRealmID, strRealmName 
    FROM tblRealms 
    ORDER BY strRealmName
  ];
  my $realms = getDBdrop_down('realmID',$db,$st,0) || '';
  my $body = qq[
    <h1>Person Finder</h1>
  <br>
    <form action="$target" method="POST">
      <input type="hidden" name="a" value="sr">
       Realm: $realms<br>
       MA_ID: <input type="text" name="maid" size="20"><br>
       Firstname: <input type="text" name="firstname" size="20"><br>
       Surname: <input type="text" name="surname" size="20"><br>
       <input type="submit" name="submit" value="S E A R C H">
    </form>
    <br><br>
    <form action="$target" method="POST">
       <input type="submit" name="submit" value="Update Account Linkages">
      <input type="hidden" name="a" value="links">
    </form>
    ];
  return $body;
}

sub search_results {
  my ($db, $target) = @_;
  my $returnstring=  qq[
        <table class = "list">
          <tr>
            <th>Internal PersonId</th>
            <th>MA_ID</th>
            <th>Firstname</th>
            <th>Surname</th>
            <th>Status</th>
            <th>Self User Account</th>
            <th>&nbsp;</th>
          </tr>
  ]; 
  my $wherestr = '';
  my $maid= param('maid') || '';
  my $fname= param('firstname') || '';
  my $sname= param('surname') || '';
  if($maid)   {
    $maid=~s/'/''/g;
    $wherestr .= " AND strNationalNum = '$maid' ";
  }
  if($fname)   {
    $fname=~s/'/''/g;
    $wherestr .= " AND strLocalFirstname= '$fname' ";
  }
  if($sname)   {
    $sname=~s/'/''/g;
    $wherestr .= " AND strLocalSurname = '$sname' ";
  }
  my $statement="
    SELECT
        P.*,    
        SU.strEmail as SUEmail
    FROM
       tblPerson as P
        LEFT JOIN tblSelfUserAuth as SUA ON (P.intPersonID = SUA.intEntityID)
        LEFT JOIN tblSelfUser as SU ON (SU.intSelfUserID = SUA.intSelfUserID)
    WHERE
        1=1
        $wherestr
    LIMIT 100
  ";
  my $query = $db->prepare($statement);
  $query->execute();
  while(my $dref =$query->fetchrow_hashref())  {
    my $status = '';
    my $setStatus = '';
    if ($dref->{'strStatus'} ne 'REGISTERED')  {
        $setStatus = qq[&nbsp;&nbsp;<a onclick="return confirm('Are you sure you want to mark this person as deleted');" href="person_finder.cgi?pID=$dref->{'intPersonID'}&a=sd">Set as Deleted</a>];
    }
    $returnstring.=  qq[
                <tr>
                  <td>$dref->{'intPersonID'}</td>
                  <td>$dref->{'strNationalNum'}</td>
                  <td>$dref->{'strLocalFirstname'}</td>
                  <td>$dref->{'strLocalSurname'}</td>
                  <td>$dref->{'strStatus'}$setStatus</td>
                  <td>$dref->{'SUEmail'}</td>
                    <td><a href="person_finder.cgi?pID=$dref->{'intPersonID'}&a=vr">View Regos</a></td>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}

sub viewRegos   {
  my ($db, $personID, $target) = @_;
  my $returnstring=  qq[
        <table class = "list">
          <tr>
            <th>RegoID</th>
            <th>Entity</th>
            <th>PersonType</th>
            <th>PersonLevel</th>
            <th>Age</th>
            <th>Sport</th>
            <th>National Period</th>
            <th>Status</th>
          </tr>
  ]; 
  my $wherestr = '';
  my $statement="
    SELECT
        PR.*,
        NP.strNationalPeriodName,
        E.strLocalName
    FROM
       tblPersonRegistration_1 as PR
        INNER JOIN tblEntity as E ON (E.intEntityID = PR.intEntityID)
        INNER JOIN tblNationalPeriod as NP ON (NP.intNationalPeriodID = PR.intNationalPeriodID)
    WHERE
        intPersonID = ?
    ORDER BY PR.dtFrom, PR.intPersonRegistrationID
    LIMIT 100
  ";
  my $query = $db->prepare($statement);
  $query->execute($personID);
  while(my $dref =$query->fetchrow_hashref())  {
    my $status = '';
    my $setStatus = '';
    if ($dref->{'strStatus'} ne 'REGISTERED')  {
        $setStatus = qq[&nbsp;&nbsp;<a onclick="return confirm('Are you sure you want to mark this rego as PASSIVE');" href="person_finder.cgi?regoID=$dref->{'intPersonRegistrationID'}&amp;pID=$dref->{'intPersonID'}&a=srs">Set as Passive</a>];
    }
    $returnstring.=  qq[
                <tr>
                  <td>$dref->{'intPersonRegistrationID'}</td>
                  <td>$dref->{'strLocalName'}</td>
                  <td>$dref->{'strPersonType'}</td>
                  <td>$dref->{'strPersonLevel'}</td>
                  <td>$dref->{'strAgeLevel'}</td>
                  <td>$dref->{'strSport'}</td>
                  <td>$dref->{'strNationalPeriodName'}</td>
                  <td>$dref->{'strStatus'}$setStatus&nbsp;</td>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}

sub setRegoStatus {

    my ($db, $personID, $regoID, $target) = @_;
    
    my %Data= ();
    $Data{'cache'}  = new MCache();
    $personID ||= 0;
    $regoID ||= 0;
    return if (! $personID);
    return if (! $regoID);

    my $st = qq[
        UPDATE 
            tblPersonRegistration_1
        SET
            strStatus='PASSIVE'
        WHERE
            intPersonID = ?
            AND intPersonRegistrationID=?
        LIMIT 1;
    ];
    my $query = $db->prepare($st);
    $query->execute($personID, $regoID);
    my $personObject = getInstanceOf(\%Data, 'person',$personID);
    updateSphinx($db,$Data{'cache'}, 'Person','update',$personObject);
    return;
}
   
