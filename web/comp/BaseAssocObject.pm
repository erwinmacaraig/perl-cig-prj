#
# $Header: svn://svn/SWM/trunk/web/comp/BaseAssocObject.pm 10492 2014-01-21 00:32:53Z apurcell $
#

package BaseAssocObject;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);

sub new {

    my $this   = shift;
    my $class  = ref($this) || $this;
    my %params = @_;
    my $self   = {};
    ##bless selfhash to class
    bless $self, $class;

	#Set Defaults
    $self->{'db'} = $params{'db'};
    $self->{'ID'} = $params{'ID'};
    $self->{'assocID'} = $params{'assocID'};
    return undef if !$self->{'db'};
    return undef if !$self->{'assocID'};
    return undef if $self->{'assocID'} !~ /^\d+$/;
    return $self;
}

sub assocID {
  my $self = shift;
  return $self->{'assocID'} || 0;
}

1;
