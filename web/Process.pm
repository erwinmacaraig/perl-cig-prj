#
# $Header: svn://svn/SWM/trunk/web/Process.pm 10192 2013-12-09 00:28:57Z sregmi $
#

package Process;
use strict;

use vars '$AUTOLOAD';
use lib '.', '..';
use Defs;

sub new {
  my ($class,%args) = @_;
  my $self = bless
  {
    'assocID'    => $args{intAssocID},
    'compID'     => $args{intCompID},
    'poolID'     => $args{intPoolID},
    'typeID'     => $args{intTypeID},
    'realmID'    => $args{intRealmID},
    'pLogNumber' => $args{intProcessLogNumber},
    'added'      => $args{dtAdded},
    'name'       => $args{strProcessName},
    'status'     => $args{intStatus},
    'data1'      => $args{strData1},
    'data2'      => $args{strData2},
    'data3'      => $args{strData3},
    'data4'      => $args{strData4},
    'data5'      => $args{strData5},
    'timestamp'  => $args{tTimeStamp},
    'started'    => $args{dtStarted},
    'ended'      => $args{dtEnded},
    'scheduled'  => $args{dtScheduled},
    'id'         => $args{intID}, 
  }, $class;
  return $self;
}

sub AUTOLOAD {
  my ($self) = shift;
  my $attr = $AUTOLOAD;
  $attr =~ s/.*:://;
  if (!exists($self->{$attr})){
        die "No such method:$AUTOLOAD\n";
  }
  else {
    return $self->{$attr};
  }
}

sub compID {
  my $self = shift;
  return $self->{compID} || 0;
}

sub getID {
  my $self = shift;
  return $self->{id} || 0;
}

sub startTime {
  my $self = shift;
  my $time = shift;  
  $self->{startTime} = $time if $time;
  return $self->{startTime};
}

sub endTime {
  my $self = shift;
  my $time = shift;  
  $self->{endTime} = $time if $time;
  return $self->{endTime};
}

sub status {
  my $self = shift;
  my $status = shift;  
  $self->{status} = $status if $status;
  return $self->{status};
}

sub data1 {
  my $self = shift;
  return $self->{data1} || 0;
}

sub data2 {
  my $self = shift;
  return $self->{data2} || 0;
}

sub data3 {
  my $self = shift;
  return $self->{data3} || 0;
}

sub set_status {
  my $self = shift;
  my ($dbh, $status) = @_;
  my $assocID = $self->assocID();
  my $compID = $self->compID();
  my $typeID = $self->typeID();
  my $poolID = $self->poolID() || 0;
  my $statusTime = '';
  if ($status eq $Defs::PROCESSLOG_RUNNING) {
    $statusTime = ', dtStarted = NOW() ';
  }
  elsif ($status eq  $Defs::PROCESSLOG_COMPLETED) {
    $statusTime = ', dtCompleted = NOW() ';
  }
  my $query = qq[
    UPDATE IGNORE 
      tblCompProcessLog 
    SET 
      intStatus = $status
      $statusTime
    WHERE 
      intAssocID = $assocID
      AND intCompID = $compID
      AND intTypeID = $typeID
      AND intPoolID = $poolID
  ];
  $dbh->do($query);
  $self->status($status);
  return;
}

sub DESTROY {

}

1;
