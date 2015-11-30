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
  my $target='selfrego_admin.cgi';
  my $returnstr='';
  my $action=param('a') || '';
  my $entityType =param('t') || '';
  my $selfUserId = param('su') || 0;
  my $personID= param('pID') || 0;
  my $db=connectDB();

  if($action eq "sr")  {
     $returnstr=search_results($db, $target);
  }
  elsif($action eq "dl")  {
     $returnstr=selfrego_display_linkages($db, $target, $selfUserId);
  }
  elsif($action eq "linkdel")  {
     $returnstr.=disconnectLinkage($db, $target, $selfUserId, $personID);
  }
  else  {
    $returnstr= searchpage($db, $target);
  }
  $returnstr .= qq[<p><a href = "selfrego_admin.cgi">Return to Self Rego Admin</a></p>];
  print_adminpageGen($returnstr, "", "");
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
    <h1>Self Rego Accounts - Admin</h1>
  <br>
    <form action="$target" method="POST">
      <input type="hidden" name="a" value="sr">
       Realm: $realms<br>
       Email: <input type="text" name="email" size="20"><br>
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
            <th>ID</th>
            <th>Email</th>
            <th>Firstname</th>
            <th>Surname</th>
            <th>Status</th>
          </tr>
  ]; 
  my $wherestr = '';
  my $email= param('email') || '';
  if($email)   {
    $email=~s/'/''/g;
    $wherestr .= " AND strEmail LIKE '%$email%' ";
  }
  my $statement="
    SELECT
        *
    FROM
        tblSelfUser
    WHERE
        1=1
        $wherestr
    ORDER BY 
        strEmail
    LIMIT 100
  ";
  my $query = $db->prepare($statement);
  $query->execute();
    my %Status = (
        0=>'Invalid',
        1=>'NOT confirmed',
        2=>'CONFIRMED',
        3=>'DELETED',
        5=>'Suspended',
        6=>'Email Suspended',
    );
  while(my $dref =$query->fetchrow_hashref())  {
    my $status = '';
    $returnstring.=  qq[
                <tr>
                  <td>$dref->{'intSelfUserID'}</td>
                  <td>$dref->{'strEmail'}</td>
                  <td>$dref->{'strFirstName'}</td>
                  <td>$dref->{'strFamilyName'}</td>
                  <td>$Status{$dref->{'strStatus'}}</td>
                  <td><a href="$target?a=dl&amp;su=$dref->{'intSelfUserID'}">View Linkages</a>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}


sub selfrego_display_linkages {
  my ($db, $target, $selfUserID ) = @_;
    return 'ERROR' if ! $selfUserID;
    my $st = qq[
        SELECT strEmail FROM tblSelfUser WHERE intSelfUserID = ? LIMIT 1
    ];
  my $query = $db->prepare($st);
  $query->execute($selfUserID);
    my $email = $query->fetchrow_array() || '';

  my $returnstring=  qq[
    <h1>Users for $email</h1>
        <table class = "list">
          <tr>
            <th>National Number</th>
            <th>Local Name</th>
            <th>International Name</th>
            <th>Person Status</th>
            <th>Disconnect Person</th>
          </tr>
  ]; 
  my $statement=qq[
        SELECT 
            SU.*, 
            P.strNationalNum, 
            P.strLocalFirstname, 
            P.strLocalSurname, 
            P.strLatinFirstname,
            P.strLatinSurname,
            P.strStatus 
        FROM 
            tblSelfUserAuth as SU 
            INNER JOIN tblPerson as P ON (P.intPersonID = SU.intEntityID and SU.intEntityTypeID=1) 
        WHERE 
            intSelfUserID = ?
  ];
  $query = $db->prepare($statement);
  $query->execute($selfUserID);
  while(my $dref = $query->fetchrow_hashref())  {
    $returnstring.=  qq[
                <tr>
                  <td>$dref->{'strNationalNum'}</td>
                  <td>$dref->{'strLocalFirstname'} $dref->{'strLocalSurname'}</td>
                  <td>$dref->{'strLatinFirstname'} $dref->{'strLatinSurname'}</td>
                  <td>$dref->{'strStatus'}</td>
                  <td><a onclick = "return confirm('Are you sure?');" href = "$target?a=linkdel&amp;su=$selfUserID&amp;pID=$dref->{'intEntityID'}">Disconnect</a></td>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}


sub disconnectLinkage {
  my ($db, $target, $selfUserID, $personID) = @_;

    my $st = qq[
        DELETE FROM tblSelfUserAuth WHERE intSelfUserID = ? and intEntityTypeID=1 AND intEntityID = ? LIMIT 1
    ];
    my $q = $db->prepare($st);
    $q->execute(
        $selfUserID,
        $personID
    );
    my $returnstring = 'DISCONNECTED';
    return $returnstring;
}
