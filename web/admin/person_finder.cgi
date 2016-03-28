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

main();

sub main  {
  my $target='person_finder.cgi';
  my $returnstr='';
  my $action=param('a') || '';
  my $entityType =param('t') || '';
  my $personID= param('pID') || 0;
  my $db=connectDB();

  if($action eq "sr")  {
     $returnstr=search_results($db, $target);
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
    if ($dref->{'strStatus'} eq 'INPROGRESS')  {
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
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}


