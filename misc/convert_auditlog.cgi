#! /usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/misc/convert_auditlog.cgi 9480 2013-09-10 04:41:52Z tcourt $
#

use strict;

use lib ".", '../', '../web/';

use Defs;
use Utils;

# TABLE - FIELD - LEVEL - ENTITY_ID_LOCATION

# tblAgeGroups
_get_log_records(
  'tblAgeGroups',
  'intAgeGroupID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblArrivalsDeparts
_get_log_records(
  'tblArrivalsDeparts',
  'intMemberID',
  $Defs::LEVEL_MEMBER,
  'relatedID'
);

# tblAssoc
_get_log_records(
  'tblAssoc',
  'intAssocID',
  $Defs::LEVEL_ASSOC,
  'intID'
);

# tblBankAccount
_get_log_records(
  'tblBankAccount',
  'intEntityID',
  0,
  'entityDetails'
);

# tblClearancePath
_get_log_records(
  'tblClearancePath',
  'intClearancePathID',
  0,
  'clearance'
);

# tblClearances
_get_log_records(
  'tblClearances',
  '',
  $Defs::LEVEL_MEMBER,
  'relatedID'
);

# tblClub
_get_log_records(
  'tblClub',
  '',
  $Defs::LEVEL_CLUB,
  'intID'
);

# tblClubChampionship
_get_log_records(
  'tblClubChampionship',
  'intClubChampionshipID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblComp
_get_log_records(
  'tblComp',
  '',
  $Defs::LEVEL_COMP,
  'intID'
);

# tblCompAwards
_get_log_records(
  'tblCompAwards',
  'intAwardID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblCompExceptionDates
_get_log_records(
  'tblCompExceptionDates',
  'intDateID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblCompFixtureTemplate
_get_log_records(
  'tblCompFixtureTemplate',
  'intTemplateID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblCompMatches
_get_log_records(
  'tblCompMatches',
  'intMatchID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblCompRounds
_get_log_records(
  'tblCompRounds',
  'intRoundID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblCompUmpires

# tblDefVenue
_get_log_records(
  'tblDefVenue',
  'intDefVenueID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblFitnessTest
_get_log_records(
  'tblFitnessTest',
  'intFitnessTestID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblFitnessTests
_get_log_records(
  'tblFitnessTests',
  'intFitnessTestID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblLadderAdjustments 
_get_log_records(
  'tblLadderAdjustments',
  'intLadderAdjustmentID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblMediaOutlets
_get_log_records(
  'tblMediaOutlets',
  'intMediaOutletID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblMediaReportScheduledTimes
_get_log_records(
  'tblMediaReportScheduledTimes',
  'intScheduledTimeID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblMember
_get_log_records(
  'tblMember',
  'intMemberID',
  $Defs::LEVEL_MEMBER,
  'intID'
);

# tblMember_FitnessTests
_get_log_records(
  'tblMember_FitnessTests',
  'intMemberFitnessTestID',
  $Defs::LEVEL_MEMBER,
  'search'
);

# tblMember_Types
_get_log_records(
  'tblMember_Types',
  'intMemberTypeID',
  $Defs::LEVEL_MEMBER,
  'search'
);

# tblNode
_get_log_records(
  'tblNode',
  'intNodeID',
  $Defs::LEVEL_NATIONAL,
  'node'
);

# tblPlayerSeasonStats
_get_log_records(
  'tblPlayerSeasonStats',
  'intPlayerSeasonStatID',
  $Defs::LEVEL_MEMBER,
  'search'
);

# tblProdTransactions
_get_log_records(
  'tblProdTransactions',
  'intTransactionID',
  $Defs::LEVEL_MEMBER,
  'prodtransactions'
);

# tblSeasons
_get_log_records(
  'tblSeasons',
  'intSeasonID',
  $Defs::LEVEL_ASSOC,
  'search'
);

# tblTeam
_get_log_records(
  'tblTeam',
  'intTeamID',
  $Defs::LEVEL_TEAM,
  'search'
);

# tblTransactions
_get_log_records(
  'tblTransactions',
  'intTransactionID',
  $Defs::LEVEL_MEMBER,
  'transactions'
);

# tblTribunal
_get_log_records(
  'tblTribunal',
  'intTribunalID',
  $Defs::LEVEL_MEMBER,
  'search'
);

sub _get_log_records {
  my ($table, $field, $level, $entityID_location) = @_;
  my $db = connectDB();
  $table = ($table eq 'tblFitnessTest') ? 'tblFitnessTests' : $table;
  my $st = qq[
    SELECT
      *
    FROM
      tblAuditLog
    WHERE
      strTable = ?
  ];
  my $q = $db->prepare($st);
  $q->execute($table);
  my @log = ();
  my $i = 0;
  while (my $href = $q->fetchrow_hashref()) {
    my $insert_level = $level;
    $href->{'strSection'} = _get_section_name($href->{'strTable'});
    $href->{'strType'}  = _get_type_name($href->{'strAction'});
    my ($id, $type) = _get_login_details($href->{'strUsername'}, $db);
    $href->{'intLoginEntityID'} = $id;
    $href->{'intLoginEntityTypeID'} = $type;
    my $entityID = 0;
    if ($entityID_location eq 'search') {
      my $realmID = 0;
      ($entityID, $realmID) = _get_entity_id($table,$field,$href->{'intID'},$db,$level);
      unless ($entityID) {
        $entityID = _get_node_id($realmID, $db);
        $insert_level = $Defs::LEVEL_NATIONAL;
      } 
    }
    elsif ($entityID_location eq 'relatedID') {
      $entityID = $href->{'intRelatedID'};
    }
    elsif ($entityID_location eq 'intID') {
      $entityID = $href->{'intID'};
    }
    elsif ($entityID_location eq 'entityDetails') {
      my $entityTypeID = '';
      ($entityID, $entityTypeID) = _get_entity_details($table,$field,$href->{'intID'},$db);
      $insert_level = $entityTypeID;
    }
    elsif ($entityID_location eq 'node') {
      ($entityID, $insert_level) = _get_node_and_level($href->{'intID'}, $db);
    }
    elsif ($entityID_location eq 'clearance') {
      ($entityID, $insert_level) = _get_clearance_entity_and_level($href->{'intID'}, $db);
    }
    elsif ($entityID_location eq 'transactions') {
      ($entityID, $insert_level) = _get_transaction_entity_and_level($href->{'intID'}, $db);
    }
    elsif ($entityID_location eq 'prodtransactions') {
      ($entityID, $insert_level) = _get_prod_transaction_entity_and_level($href->{'intID'}, $db);
    }
    $href->{'intEntityID'} = $entityID;
    $href->{'intEntityTypeID'} = $insert_level;
    insert_record($db,$href);
    $i++;
  }
  print qq[$table: $i records inserted \n];
}

sub _get_section_name {
  my ($table) = @_;
  my %sections = (
    'tblAgeGroups' => 'Age Groups',
    'tblArrivalsDeparts' => 'Events',
    'tblAssoc' => 'Assoc',
    'tblBankAccount' => 'Bank Account',
    'tblClearancePath' => 'Clearance',
    'tblClearances' => 'Clearance',
    'tblClub' => 'Club',
    'tblClubChampionship' => 'Club Championship',
    'tblComp' => 'Competition',
    'tblCompAwards' => 'Awards',
    'tblCompExceptionDates' => 'Exception Dates',
    'tblCompFixtureTemplate' => 'Fixture Template',
    'tblCompMatches' => 'Match Display',
    'tblCompRounds' => 'Round',
    'tblCompUmpires' => 'Umpires',
    'tblDefVenue' => 'Venue',
    'tblFitnessTest' => 'Fitness Test',
    'tblFitnessTests' => 'Fitness Test',
    'tblLadderAdjustments' => 'Ladder Adjustment',
    'tblMediaOutlets' => 'Media Outlet',
    'tblMediaReportScheduledTimes' => 'Media Report',
    'tblMember' => 'Member',
    'tblMember_FitnessTests' => 'Fitness Test',
    'tblMember_Types' => 'Member Types',
    'tblNode' => 'Node',
    'tblPlayerSeasonStats' => 'Seasons',
    'tblProdTransactions' => 'Transactions',
    'tblSeasons' => 'Seasons',
    'tblTeam' => 'Team',
    'tblTransactions' => 'Transactions',
    'tblTribunal' => 'Tribunal'
  );
  return $sections{$table};
}

sub _get_type_name {
  my ($action) = @_;
  my %types = (
    'add' => 'Add',
    'edit' => 'Update',
    'display' => 'Display',
  );
  return $types{$action};
}

sub _get_login_details {
  my ($username, $db) = @_;
  my $st = qq[
    SELECT
      *
    FROM
      tblAuth
    WHERE
      strUsername = ?
  ]; 
  my $q = $db->prepare($st);
  $q->execute($username);
  my $href = $q->fetchrow_hashref();
  return ($href->{'intID'} || 0, $href->{'intLevel'} || 0);
}

sub _get_entity_id {
  my ($table, $field, $id, $db, $level) = @_;
  my ($assocID, $realmID, $memberID) = (0,0,0);
  if ($level == $Defs::LEVEL_MEMBER) {
    my $st = qq[
      SELECT
        $table.intMemberID,
        A.intRealmID,
        A.intAssocID
      FROM
        $table
        LEFT JOIN tblAssoc AS A ON A.intAssocID = $table.intAssocID
      WHERE
        $field = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    ($memberID, $realmID, $assocID) = $q->fetchrow_array();
  }
  else {
    my $st = qq[
      SELECT
        $table.intAssocID, 
        A.intRealmID
      FROM
        $table
        LEFT JOIN tblAssoc AS A ON A.intAssocID = $table.intAssocID
      WHERE
        $field = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    ($assocID, $realmID) = $q->fetchrow_array();
  }
  unless ($realmID or !$assocID) { 
    my $st = qq[
      SELECT
        $table.intRealmID
      FROM
        $table
      WHERE
        $field = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    ($realmID) = $q->fetchrow_array();
  }
  $assocID ||= 0;
  $realmID ||= 0;
  $memberID ||= 0;
  my $entityID = ($memberID) ? $memberID : $assocID;
  return ($entityID, $realmID);
}

sub _get_entity_details {
  my ($table, $field, $id, $db) = @_;
  my $entityID = '';
  my $entityTypeID = '';
  if ($field eq 'intTypeID') {
    $entityID = 'intID';
    $entityTypeID = 'intTypeID';
  }
  else {
    $entityID = 'intEntityID';
    $entityTypeID = 'intEntityTypeID';
  }
  my $st = qq[
    SELECT
      $entityID,
      $entityTypeID
    FROM
      $table
    WHERE
      $entityID = ?
  ];
  my $q = $db->prepare($st);
  $q->execute($id);
  ($entityID, $entityTypeID) = $q->fetchrow_array();
  $entityID ||= 0;
  $entityTypeID ||= 0;
  return ($entityID, $entityTypeID);
}

sub _get_node_id {
  my ($realmID, $db) = @_;
  my $st = qq[
    SELECT
      intNodeID
    FROM
      tblNode
    WHERE
      intRealmID = ?
      AND intTypeID = 100
  ];
  my $q = $db->prepare($st);
  $q->execute($realmID);
  return $q->fetchrow_array() || 0;
}

sub _get_node_and_level {
    my ($id, $db) = @_;
    my $st = qq[
      SELECT
        intNodeID,
        intTypeID
      FROM
        tblNode
      WHERE
        intNodeID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    my ($nodeID, $typeID) = $q->fetchrow_array();
    return ($nodeID, $typeID);
}

sub _get_clearance_entity_and_level {
    my ($id, $db) = @_;
    my $st = qq[
      SELECT
        intID,
        intTypeID
      FROM
        tblClearancePath
      WHERE
        intClearancePathID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    my ($entityID, $typeID) = $q->fetchrow_array();
    return ($entityID, $typeID);
}

sub _get_transaction_entity_and_level {
    my ($id, $db) = @_;
    my $st = qq[
      SELECT
        intID,
        intTableType
      FROM
        tblTransactions
      WHERE
        intTransactionID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    my ($entityID, $typeID) = $q->fetchrow_array();
    return ($entityID, $typeID);
}

sub _get_prod_transaction_entity_and_level {
    my ($id, $db) = @_;
    my $st = qq[
      SELECT
        intMemberID,
        $Defs::LEVEL_MEMBER
      FROM
        tblProdTransactions
      WHERE
        intTransactionID = ?
    ];
    my $q = $db->prepare($st);
    $q->execute($id);
    my ($entityID, $typeID) = $q->fetchrow_array();
    return ($entityID, $typeID);
}

sub insert_record {
  my ($db, $href) = @_;
  my $st = qq[
    INSERT INTO
      tblAuditLog2 
    VALUES (
      0,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?,
      ?
    )
  ];
  my $q = $db->prepare($st);
  $q->execute(
      $href->{'intID'},
      $href->{'strUsername'},
      $href->{'strType'},
      $href->{'strSection'},
      $href->{'intEntityTypeID'},
      $href->{'intEntityID'},
      $href->{'intLoginEntityTypeID'},
      $href->{'intLoginEntityID'},
      $href->{'dtUpdated'}
  );
}
