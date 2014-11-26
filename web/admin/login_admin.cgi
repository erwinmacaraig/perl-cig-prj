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
  my $target='login_admin.cgi';
  my $returnstr='';
  my $action=param('a') || '';
  my $id=param('id') || '';
  my $entityType =param('t') || '';
  my $realmID = param('realmID') || 0;
  my $userId = param('u') || 0;
  my $db=connectDB();

  if($action eq "sr")  {
     $returnstr=search_results($db, $target, $realmID);
  }
  elsif($action eq "u")  {
     $returnstr=user_edit($db, $target, $realmID, $id, $entityType, $userId);
  }
  elsif($action eq "uu")  {
     $returnstr.=user_update($db, $target, $realmID, $id, $entityType, $userId);
     $returnstr.=entity_details($db, $target, $realmID, $id, $entityType);
  }
  elsif($action eq "ud")  {
     $returnstr.=user_disable($db, $target, $realmID, $id, $entityType, $userId);
     $returnstr.=entity_details($db, $target, $realmID, $id, $entityType);
  }
  elsif($action eq "ed")  {
     $returnstr=entity_details($db, $target, $realmID, $id, $entityType);
  }
  else  {
    $returnstr= searchpage($db, $target);
  }
  $returnstr .= qq[<p><a href = "login_admin.cgi">Return to User Admin</a></p>];
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
    <h1>Login - Admin</h1>
  <br>
    <form action="$target" method="POST">
      <input type="hidden" name="a" value="sr">
       Realm: $realms<br>
       Level : <select name = "level" size = "1">
                <option value = ""></option>
                <option value = "$Defs::LEVEL_NATIONAL">MA</option>
                <option value = "$Defs::LEVEL_REGION">Region</option>
                <option value = "$Defs::LEVEL_CLUB">Club</option>
            </select><br>
       Name: <input type="text" name="name" size="20"> OR ID: <input type="text" name="id" size="10"><br>

    
       <input type="submit" name="submit" value="S E A R C H">
    </form>
    ];
  return $body;
}

sub search_results {
  my ($db, $target, $realmID) = @_;
  my $returnstring=  qq[
        <table class = "list">
          <tr>
            <th>ID</th>
            <th>Level</th>
            <th>Status</th>
            <th>Name</th>
          </tr>
  ]; 
  my @values = ($realmID);  
  my $wherestr = '';
  my $name = param('name') || '';
  my $id = param('id') || 0;
  my $level = param('level') || 0;
  if($name)   {
    $name =~s/'/''/g;
    $wherestr .= " AND strLocalName LIKE '%$name%' ";
  }
  if($level)   {
    $wherestr .= ' AND intEntityLevel = ? ';
    push @values, $level;
  }
  if($id)   {
    $wherestr = ' AND intEntityID = ? ';
    push @values, $id;
  }
  my $statement="
    SELECT 
        intEntityID,
        intEntityLevel,
        strStatus,
        strLocalName, 
        strLatinName
    FROM 
        tblEntity
    WHERE
        intRealmID = ?
        $wherestr
    ORDER BY 
        strLocalName, strLatinName
  ";
  my $query = $db->prepare($statement);
  $query->execute(@values);
  while(my($id, $level, $status, $name, $namelatin)=$query->fetchrow_array())  {
    $name = $namelatin if $namelatin;
    $returnstring.=  qq[
                <tr>
                  <td>$id</td>
                  <td>].$Defs::DisplayEntityLevelNames{$level}.qq[</td>
                  <td>$status</td>
                  <td><a href="$target?id=$id&amp;t=$level&amp;a=ed">$name</a>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}


sub entity_details {
  my ($db, $target, $realmID, $id, $level) = @_;
  my $name = entity_name($db, $id);
  my $returnstring=  qq[
    <h1>Users for $name (#$id) ].$Defs::DisplayEntityLevelNames{$level}.qq[</h1>
    <a href = "$target?a=u&amp;u=0&amp;id=$id&amp;t=$level">Add New User</a>
        <table class = "list">
          <tr>
            <th>Username</th>
            <th>Name</th>
            <th>Created</th>
          </tr>
  ]; 
  my @values = ($id, $level);  
  my $statement="
    SELECT 
        U.userId,
        U.username,
        CONCAT(U.firstName, ' ', U.familyName) as name,
        U.created,
        U.status
    FROM 
        tblUserAuth
            INNER JOIN tblUser AS U
                ON  tblUserAuth.userId = U.userId
    WHERE
        entityId = ?
        AND entityTypeID = ?
  ";
  my $query = $db->prepare($statement);
  $query->execute(@values);
  my %status = (
    $Defs::USER_STATUS_INVALID => 'Invalid',
    $Defs::USER_STATUS_NOTCONFIRMED => 'Not Confirmed',
    $Defs::USER_STATUS_CONFIRMED => 'Confirmed',
    $Defs::USER_STATUS_DELETED => 'Deleted',
    $Defs::USER_STATUS_SUSPENDED => 'Suspended',
    $Defs::USER_STATUS_EMAILSUSPENDED => 'Email Suspended',
  );
  while(my($userId, $username, $name, $created, $status)=$query->fetchrow_array())  {
    $returnstring.=  qq[
                <tr>
                  <td>$username</td>
                  <td><a href = "$target?a=u&amp;u=$userId&amp;id=$id&amp;t=$level">$name</a></td>
                  <td>$created</td>
                  <td>$status{$status}</td>
                  <td><a onclick = "return confirm('Are you sure?');" href = "$target?a=ud&amp;u=$userId&amp;id=$id&amp;t=$level">Disable</a></td>
                </tr>
    ];
   }
   $returnstring.=  qq[
                </table>
  ];
  return $returnstring;
}


sub user_edit {
  my ($db, $target, $realmID, $id, $level, $userId) = @_;

  my $user = undef;
  $user = new UserObj(db => $db, id => $userId);

  my $username = $user->getValue('username') || '';
  my $fname = $user->getValue('firstName') || '';
  my $famname = $user->getValue('familyName') || '';
  my $name = entity_name($db, $id);
  my $returnstring=  qq[
    <h1>Add/Edit Users for $name (#$id) ].$Defs::DisplayEntityLevelNames{$level}.qq[</h1>
        <form action = "$target" method = "POST">
            Username : <input type = "text" name = "username" value = "$username"><br>
            First Name: <input type = "text" name = "fname" value = "$fname"><br>
            Family Name: <input type = "text" name = "famname" value = "$famname"><br>
            Set Password: <input type = "text" name = "password" value = ""><br>

            <input type = "hidden" name = "a" value = "uu">
            <input type = "hidden" name = "u" value = "$userId">
            <input type = "hidden" name = "id" value = "$id">
            <input type = "hidden" name = "t" value = "$level">
            <input type = "submit" value = "Add/Update">
        </form>
      <a href = "$target?a=ed&amp;id=$id&amp;t=$level">< Return to Entity</a>
  ];
  return $returnstring;
}

sub user_update {
  my ($db, $target, $realmID, $id, $level, $userId) = @_;

  my $user = undef;
  $user = new UserObj(db => $db, id => $userId);

  my $username = param('username') || '';
  my $fname = param('fname') || '';
  my $famname = param('famname') || '';
  my $password = param('password') || '';
  my $readonly = param('ro') || 0;


  my $uncheck = new UserObj(db => $db, username => $username);
  my $error = '';
  if($uncheck->ID())    {
    if($uncheck->ID() != $userId)   {
        return 'Username in use';
    }
  }

  my %data = (
    'firstName' => $fname,
    'familyName' => $famname,
    'username' => $username,
  );
  $user->update(\%data);
  if(!$userId and $user->ID())  {
    #new user
    $userId = $user->ID();
    my $st = qq[
        INSERT INTO tblUserAuth (
            userId,
            entityTypeId,
            entityId,
            readOnly
        )
        VALUES (
            ?,
            ?,
            ?,
            ?
        )
    ];
    my $q = $db->prepare($st);
    $q->execute(
        $userId,
        $level,
        $id,    
        $readonly || 0,
    );
  }
  if($password) {
    $user->setPassword($password);
  }
  my $returnstring = 'updated';
  return $returnstring;
}

sub entity_name {
  my ($db, $id) = @_;

    my $obj = new EntityObj(
        db => $db,
        ID => $id,
    );
    $obj->load();
    if($obj and $obj->ID())    {
        return $obj->name();
    }
    return '';
}

sub user_disable {
  my ($db, $target, $realmID, $id, $level, $userId) = @_;

  my $user = undef;
  $user = new UserObj(db => $db, id => $userId);

  my %data = (
    'status' => $Defs::USER_STATUS_DELETED,
  );
  $user->update(\%data);
  my $returnstring = '';
  return $returnstring;
}


