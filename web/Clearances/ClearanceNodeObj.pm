#
# $Header: svn://svn/SWM/trunk/web/ClearanceNodeObj.pm 8251 2013-04-08 09:00:53Z rlee $
#

package ClearanceNodeObj;

#TO DO:
###~/source/sww/trunk/web/media/Media.pm 
## SHould tblClearancePath be another object, where do I store an ordered array of ClearancPathObjects ?  What about the 1->many ?
## Need a ClearancePermitObj;

##my $club_obj = getInstanceOf($Data, 'club', $dref->{'clubID'});
##$club_name  = $club_obj->{'strName'};

#Is the base objct Clearance or Clearances ?
#Make it the singular !
#ISA BaseObject

use lib ".", "..", "comp/";
use AuditLog;

use BaseObject;
our @ISA =qw(BaseObject);
use strict;


sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my %params=@_;
  my $self ={};
  ##bless selfhash to class
  bless $self, $class;

print "NEW NP CALLED\n";
  #Set Defaults
  $self->{'db'}=$params{'db'};
  $self->{'ID'}=$params{'ID'};
  $self->{'clearanceID'}=$params{'clearanceID'};
  $self->{'clearancePathID'}=$params{'clearancePathID'};
  return undef if !$self->{'db'};
  return $self;
}

sub load	{

	my $self = shift;
	my $st = qq[
  	SELECT
			intClearancePathID,
			intClearanceID,
			intID
    FROM
      tblClearancePath
    WHERE
      intClearancePathID = ?
			AND intClearanceID = ?
   ];

  my $q = $self->{'db'}->prepare($st);
  $q->execute($self->{'clearancePathID'}, $self->{'clearanceID'});
	print "$st | $self->{'clearancePathID'}, $self->{'clearanceID'}\n";
  if($DBI::err) {
    $self->LogError($DBI::err);
  }
  else  {
    $self->{'DBData'}=$q->fetchrow_hashref();
		$self->{'ID'} = $self->{'DBData'}{'intClearancePathID'};
  }
}

sub ID  {
  my $self = shift;
  return $self->{'ID'};
}

sub OLDgetValue  {
  my $self = shift;
	my($field)=@_;
	return $self->{'DBData'}{$field};
}

sub update {
  my $self = shift;
  my($updatedata, $updateWhere)=@_;
  for my $k (keys %{$updatedata})  {
    $self->{'DBData'}{$k}=$updatedata->{$k};
  }
	my $where = '';
	my @WhereBinding = ();
  for my $k (keys %{$updateWhere})  {
		$where .= qq[ AND $k = ? ];
		push @WhereBinding, $updateWhere->{$k};
	}
  $self->write($where, \@WhereBinding);
}

sub write	{

 	my $self = shift;
	my ($where, $whereArgs_ref) = @_;
	my $updateWHERE = shift || '';
 	if($self->ID()) {
    my $st=qq[
      UPDATE tblClearancePath
      SET
				intClearanceStatus = ?
      WHERE 
				intClearancePathID = ?
				AND intClearanceID = ?
				$where
    ];
    my $q = $self->{'db'}->prepare($st);
    $q->execute(
			$self->{'DBData'}{'intClearanceStatus'},
			$self->getValue('intClearancePathID'),
			$self->getValue('intClearanceID'),
			@{$whereArgs_ref}
			
    );
		print STDERR "$st | " . $self->{'DBData'}{'intClearanceStatus'} . "WHERE". $self->getValue('intClearancePathID') . "|" . $self->getValue('intClearanceID');
  }
	else	{
		my $st = qq[
			INSERT INTO tblClearancePath (intClearanceStatus)
			VALUES (?)
		];
		my $q = $self->{'db'}->prepare($st);
    $q->execute(
      $self->{'DBData'}{'intClearanceStatus'},
		);
		$self->{'ID'}=$q->{'mysql_insertid'};
    $self->{'DBData'}{'intClearancePathID'} = $q->{'mysql_insertid'};
	}
}

1;
