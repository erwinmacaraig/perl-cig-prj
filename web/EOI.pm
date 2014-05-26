#
# $Header: svn://svn/SWM/trunk/web/EOI.pm 8251 2013-04-08 09:00:53Z rlee $
#

package EOI;
use lib 'comp';

use BaseObject;
our @ISA =qw(BaseObject);

use strict;

sub load	{
  my ($self,$data) = @_;  
  if (defined($data)) {
    $self->{'DBData'} = $data;
  }
  else {
    my $st=qq[
		  SELECT * 
		  FROM tblCompExceptionDates
		  WHERE intDateID = ?
	  ];   
    my $q = $self->{'db'}->prepare($st);
    $q->execute($self->{'ID'});
    if ($DBI::err) {
      $self->LogError($DBI::err);
    }
    else {
      $self->{'DBData'}=$q->fetchrow_hashref();	
    }
  }
}


sub add {
  my $class = shift;
  my $dbh = shift;
  my $query;  
  $dbh->do($query);
  return $dbh->{mysql_insertid};
}


# Static return a list of Exception Date objects.
sub get_eoi { 
  my $class = shift;
  my ($dbh, $assocID,$compID) = @_;
  my $query;
  my $sth = $dbh->prepare($query);
  $sth->execute();
}

1;
