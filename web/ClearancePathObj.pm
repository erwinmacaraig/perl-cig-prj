#
# $Header: svn://svn/SWM/trunk/web/ClearancePathObj.pm 8251 2013-04-08 09:00:53Z rlee $
#

package ClearancePathObj;

#TO DO:
###~/source/sww/trunk/web/media/Media.pm 
## SHould tblClearancePath be another object, where do I store an ordered array of ClearancPathObjects ?  What about the 1->many ?
## Need a ClearancePermitObj;

##my $club_obj = getInstanceOf($Data, 'club', $dref->{'clubID'});
##$club_name  = $club_obj->{'strName'};

use lib ".", "..", "comp/";
use AuditLog;

use BaseObject;
our @ISA =qw(BaseObject);
use strict;
use ClearanceNodeObj;

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my %params=@_;
  my $self ={};
  ##bless selfhash to class
  bless $self, $class;

print "NEW NN CALLED\n";
  #Set Defaults
  $self->{'db'}=$params{'db'};
  $self->{'ID'}=$params{'ID'};
  $self->{'clearanceID'}=$params{'clearanceID'};
	print "KKKKKKK: $self->{'clearanceID'}\n";
  return undef if !$self->{'db'};
  return $self;
}


sub load	{

	my ($self, %args) = @_;

	print "CPLOAD\n";
	my $where = '';
	$where = qq[ AND intClearancePathID= $args{'clearancePathID'} ] if ($args{'clearancePathID'});

  my $st = qq[
  	SELECT 
			intClearancePathID
    FROM 
			tblClearancePath
    WHERE 
			intClearanceID=?
		ORDER BY 
			intClearancePathID
  ];

  my $qry = $self->{'db'}->prepare($st);
  my @clearancePaths = ();

  $qry->execute($self->{'clearanceID'});
	my $count=0;
	print $st . " FOR " . $self->{'clearanceID'} . "\n";
  while (my $dref = $qry->fetchrow_hashref()) {
	print "CP FROM DB: $dref->{'intClearancePathID'} FOR " . $self->{'clearanceID'} . "\n";
		my $node_obj= new ClearanceNodeObj('clearancePathID'=>$dref->{'intClearancePathID'}, 'clearanceID'=>$self->{'clearanceID'}, 'db'=>$self->{'db'});
		$node_obj->load();
		print "$count...." . $node_obj->getValue('intClearancePathID') . "\n";
  	push @clearancePaths, $node_obj;
		$count++;
  }
  $qry->finish();
  $self->{'Paths'}=\@clearancePaths;

  return \@clearancePaths;
}

1;
