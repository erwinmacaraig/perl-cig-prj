#
# $Header: svn://svn/SWM/trunk/web/ProcessLog.pm 11256 2014-04-08 23:59:18Z dhanslow $
#

package ProcessLog;

use strict;
use lib '.', '..';
use Process;
use Time::Local;
use Date::Calc qw(Delta_DHMS);
use Defs;

sub new {
  my ($class,%args) = @_;
  my $self = 
  bless {
    'dbh' => $args{DB},
    'poolID' => $args{poolID} || 0,
  }, ref($class) || $class;
  return $self;
}

sub write {
  my $self = shift;
  my ($type,$assocID,$compID,$date,$data,$scheduleID) = @_;
  $compID = 0 if !$compID;
  $scheduleID = 0 if !$scheduleID;
  if ($date !~/ADDDATE/) {
    $date = $date ? "'" . $date . "'" : 'NULL';
  }
  my $dbh = $self->{'dbh'};
	my $poolID = $self->{'poolID'} || 0;
	if ($type == 99)	{
		my $query = qq[
      INSERT IGNORE INTO tblCompProcessLog (
        dtAdded,
        intAssocID,
        intCompID,
        intTypeID,
        intPoolID,
        intStatus,
        strProcessName, 
        dtScheduled,
        strData1,
        strData2,
        strData3,
        strData4,
        strData5,
        intID
      )
      VALUES(
        NOW(),
        $assocID,
        $compID,
        $type,
				$poolID,
        $Defs::PROCESSLOG_WAITING, 
        '$Defs::processLogTypes{$type}',
        $date,
        '$data->[0]',
        '$data->[1]',
        '$data->[2]',
        '$data->[3]',
        '$data->[4]',
        $scheduleID
      )
      ON DUPLICATE KEY UPDATE tTimeStamp = NOW()
		];
    $dbh->do($query);
	}
	else	{
    my $query = qq[
      INSERT IGNORE INTO tblCompProcessLog (
        dtAdded,
        intAssocID,
        intCompID,
        intTypeID,
        intPoolID,
        intStatus,
        strProcessName, 
        dtScheduled,
        strData1,
        strData2,
        strData3,
        strData4,
        strData5,
        intID
      )
      VALUES(
        NOW(),
        $assocID,
        $compID,
        $type,
				$poolID,
        $Defs::PROCESSLOG_WAITING, 
        '$Defs::processLogTypes{$type}',
        $date,
        '$data->[0]',
        '$data->[1]',
        '$data->[2]',
        '$data->[3]',
        '$data->[4]',
        $scheduleID
      )
    ];
    #ON DUPLICATE KEY UPDATE tTimeStamp = NOW()
    $dbh->do($query);
	}
  return "$Defs::processLogTypes{$type} scheduled.";
}

sub copy_out {
  my $self = shift;
  my $process  = shift;
  my $dbh = $self->{'dbh'};
  my $compID = $process->compID();
  my $typeID = $process->typeID();
  my $poolID = $process->poolID() || 0;
  my $assocID = $process->assocID();
  # Delete entry from tblCompProcessLog
  my $delete_query = qq[
    DELETE FROM 
      tblCompProcessLog 
    WHERE 
      intAssocID = $assocID 
      AND intCompID = $compID 
      AND intTypeID = $typeID
      AND intPoolID = $poolID
      AND intStatus  = $Defs::PROCESSLOG_COMPLETED
  ];
  $dbh->do($delete_query);
  # Copy to tblCompProcessLogRun;
  my $processName = $process->name();
  my $start = $process->startTime();
  my $end = $process->endTime();
  my $added = $process->added();  
  my $insert_query = qq[
    INSERT INTO tblCompProcessLogRun (
      intAssocID,
      intCompID,
      intTypeID,
      strProcessName,
      dtStarted,
      dtEnded, 
      dtAdded
    )
    VALUES (
      $assocID,
      $compID,
      $typeID,
      '$processName',
      '$start',
      '$end',
      '$added'
    )
  ];
  $dbh->do($insert_query);
  return;
}

sub check_for_running_process {
  my $self = shift;
  my ($type, $assoc, $comp, $id, $poolID) = @_;
	$poolID ||= 0;
  my $dbh = $self->{'dbh'};
  my $query = qq[
    SELECT 
      COUNT(*) 
    FROM 
      tblCompProcessLog 
    WHERE 
      intStatus = $Defs::PROCESSLOG_RUNNING
      AND intTypeID = $type
      AND intAssocID = $assoc
      AND intCompID = $comp
      AND intPoolID = $poolID
      AND intID = $id
  ];
  my ( $count ) = $dbh->selectrow_array($query);
  return $count;
}

# Call this, to remove any running entries from the process log, that may be
# orphaned due to a previous running processes not completing.
sub tidy_up {
  my $self = shift;
	my ($mins, $type, $plNumber, $assoc_id, $realms_ref, $ignore_assocs) = @_;
	$plNumber ||= 0;
	$assoc_id ||= 0;
	my $plNumberWHERE = '';
	$plNumberWHERE .= qq[ AND A.intProcessLogNumber = $plNumber ] if $plNumber;
	my $assocWHERE = '';
	$assocWHERE .= qq[ AND A.intAssocID = $assoc_id ] if $assoc_id>0;
  my $extraWhere = '';
	$type||= 0;
  if ($mins =~/^\d+$/ && $mins > 0) {
    $extraWhere = qq[ AND dtStarted < DATE_SUB(NOW(), INTERVAL $mins MINUTE)];
  }
  if ($type)	{
	  $extraWhere .= qq[ AND L.intTypeID = $type];
	}
  my $realmsWHERE ='';
  foreach my $r (@$realms_ref)	{
	  $realmsWHERE .= qq[,] if $realmsWHERE;
	  $realmsWHERE .= qq[$r];
  }
	$realmsWHERE = qq[ AND A.intRealmID IN ($realmsWHERE)] if ($realmsWHERE);
  my $ignoreassocsWHERE ='';
  foreach my $r (@$ignore_assocs)	{
	  $ignoreassocsWHERE .= qq[,] if $ignoreassocsWHERE;
	  $ignoreassocsWHERE .= qq[$r];
  }
	$ignoreassocsWHERE = qq[ AND A.intAssocID NOT IN ($ignoreassocsWHERE)] if ($ignoreassocsWHERE);
  my $dbh = $self->{'dbh'};
  my $query = qq[
    DELETE 
      L.* 
    FROM 
      tblCompProcessLog as L 
      LEFT JOIN tblAssoc as A ON (A.intAssocID=L.intAssocID) 
    WHERE 
      L.intStatus = $Defs::PROCESSLOG_RUNNING 
      $extraWhere 
      $realmsWHERE 
      $ignoreassocsWHERE 
      $plNumberWHERE 
      $assocWHERE 
      and (
        L.intRestarted=1 
        or L.intTypeID IN (1, 3, 50, 99)
      )
  ];
  my $upd_query = qq[
    UPDATE IGNORE 
      tblCompProcessLog as L 
      LEFT JOIN tblAssoc as A ON (A.intAssocID=L.intAssocID) 
    SET 
      L.intRestarted=1, 
      L.intStatus=1 
    WHERE 
      L.intStatus = $Defs::PROCESSLOG_RUNNING 
      $extraWhere 
      $realmsWHERE 
      $plNumberWHERE 
      and L.intRestarted=0  
      and L.intTypeID IN (2)
  ];
  my $upd_query_dup = qq[
    UPDATE IGNORE 
      tblCompProcessLog as L 
      LEFT JOIN tblAssoc as A ON (A.intAssocID=L.intAssocID) 
    SET 
      L.intRestarted=1 
    WHERE 
      L.intStatus = $Defs::PROCESSLOG_RUNNING 
      $extraWhere 
      $realmsWHERE 
      $plNumberWHERE 
      and L.intRestarted=0  
      and L.intTypeID IN (2)
  ];
  $dbh->do($upd_query);
  $dbh->do($upd_query_dup);
  $dbh->do($query);
  return;
}

sub get_processes {
  my $self = shift;
  my ($status, $type, $assocID, $realms_ref, $plNumber, $assoc_id, $ignore_assocs) = @_;   
	$plNumber ||= 0;
	$assoc_id ||= 0;
  my $dbh = $self->{'dbh'};
  my $query = qq[
    SELECT 
      L.*, 
      A.intRealmID, 
      A.intProcessLogNumber 
    FROM 
      tblCompProcessLog as L 
      LEFT JOIN tblAssoc as A ON (A.intAssocID=L.intAssocID) 
    WHERE 
      (dtScheduled IS NULL OR dtScheduled < NOW())
  ];      
  if($status && exists($Defs::processLogStatuses{$status})) {
    $query .= " AND L.intStatus = $status";
  }
  if($type && exists($Defs::processLogTypes{$type})) {
    $query .= " AND L.intTypeID = $type";
  }
  if ($assocID) {
    $query .= " AND L.intAssocID = $assocID";
  }
  my $realmsWHERE ='';
  foreach my $r (@$realms_ref)	{
	  $realmsWHERE .= qq[,] if $realmsWHERE;
	  $realmsWHERE .= qq[$r];
  }
  my $ignoreassocsWHERE ='';
  foreach my $r (@$ignore_assocs)	{
	  $ignoreassocsWHERE .= qq[,] if $ignoreassocsWHERE;
	  $ignoreassocsWHERE .= qq[$r];
  }
	$query .= qq[ AND A.intRealmID IN ($realmsWHERE)] if ($realmsWHERE);
	$query .= qq[ AND A.intAssocID NOT IN ($ignoreassocsWHERE)] if ($ignoreassocsWHERE);
	$query .= qq[ AND A.intProcessLogNumber = $plNumber ] if ($plNumber);  
	$query .= qq[ AND A.intAssocID = $assoc_id ] if ($assoc_id>0);  
	$query .= " ORDER BY dtAdded, intTypeID ";
  my $sth = $dbh->prepare($query);
  $sth->execute();  
  my @Procs = ();
  while (my $dref = $sth->fetchrow_hashref()) {
    my %args = ();
    foreach my $key (keys %{$dref}) {
      $args{$key} = $dref->{$key};
    }
    my $proc = new Process(%args);
    push @Procs, $proc;
  }
  return \@Procs;
}

sub get_processes_run {
  my $self = shift;
  my ($assocID) = @_;
  my $dbh = $self->{'dbh'};
  my $query = qq[SELECT * FROM tblCompProcessLogRun WHERE intAssocID = $assocID ORDER BY dtAdded DESC LIMIT 50];
  my $sth = $dbh->prepare($query);
  $sth->execute();
  my @RunProcesses;
  while (my $dref = $sth->fetchrow_hashref()) {
    my %args = ();
    foreach my $key (keys %{$dref}) {
      $args{$key} = $dref->{$key};
    }
    my $process = new Process(%args);
    push @RunProcesses, $process;    
  }
  return \@RunProcesses; 
}

sub getDateAndTime {
  my $class = shift;
  my ($day_time,$elasped_time) = @_;
  my @Weekday = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
  # Format of date from = Tuesday 03:50
  my ($weekday,$time) = split(/ /,$day_time,-1);
  #(0,43,14,23,1,109,1,53,1) This equal 23rd February 2009, 14:43pm.
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  $year = ($year + 1900);
  # Check if scheduled for today.
  if($weekday eq $Weekday[$wday] ) {
    my ($scheduled_hour,$scheduled_mins) = split(/:/,$time,-1);    
    my $current = timelocal(0,$min,$hour,$mday,$mon,$year);
    my $scheduled = timelocal(0,$scheduled_mins,$scheduled_hour,$mday,$mon,$year);
    if ($scheduled > $current){ # Hasn't happen yet.
      return 0;
    }
    my $datecalc_mon =  $mon + 1;
    my ($dday,$dhours,$dminutes,$dseconds) = 
    Delta_DHMS($year,$datecalc_mon,$mday,$scheduled_hour,$scheduled_mins,0,$year,$datecalc_mon,$mday,$hour,$min,0);  
    # If > than $elasped_time should have been run previously.
    if ($dminutes > 0 && $dhours == 0 && $dday == 0 && ($dminutes <= $elasped_time)) {
      return  "$year-$datecalc_mon-$mday $time";
    }
    else {
      return 0;
    }
  }
  else {
    return 0;
  }
}

sub DESTROY {

}

1;

