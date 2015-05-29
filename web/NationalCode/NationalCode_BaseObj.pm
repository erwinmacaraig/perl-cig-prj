package NationalCode_BaseObj;

use strict;
use CGI qw(:cgi escape);

use lib "..","../..";
use strict;

sub new {

  my $this   = shift;
  my $class  = ref($this) || $this;
  my %params = @_;
  my $self   = {};
  ##bless selfhash to class
  bless $self, $class;

    #Set Defaults
    $self->{'SystemConfig'}           = $params{'SystemConfig'};
    $self->{'value'}          = $params{'value'} || '';
    $self->{'params'}         = $params{'params'} || {};
 
    return $self;
}

# --- Placeholder functions - may be overridden

sub validate {
    my $self = shift;

    return 1;
}


1;
