package SelfUserSession;
require Exporter;

use strict;
use CGI;

use lib "user","../user";
use Data::Random qw(:all);
use SelfUserObj;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my %params = @_;
  my $self = {};
  $self->{'cache'}=$params{'cache'};
  $self->{'db'}=$params{'db'};
  $self->{'key'}=$params{'key'};
  $self->{'UserID'}=$params{'ID'};
  $self->{'Info'}={};
  return undef if !$self->{'db'};
  bless $self, $class;
  if($self->{'key'})  {
    $self->load($self->{'key'});
  }
  elsif($self->{'UserID'})  {
    $self->create();
  }

  return $self;
}

 
sub _newKey {
  my $self = shift;
  my  @validChars = (qw(1 2 3 4 5 6 7 8 9 0 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z));
  my @random_chars = rand_chars( set => \@validChars, size => 30);
  my $num=join('',@random_chars);
  $self->{'key'} = $num;
}

sub key  {
  my $self = shift;
  return $self->{'key'};
}

sub id {
  my $self = shift;
  return $self->{'UserID'} || 0;
}

sub create  {
  my $self = shift;

  $self->{'key'} = _newKey();
  $self->reload();
  
  return $self->{'key'};
}

sub reload {
  my $self = shift;

  if(!$self->{'key'})   {
    return $self->create();
  }
  if($self->{'UserID'}) {
    my $user = new SelfUserObj(db => $self->{'db'}, id => $self->{'UserID'});
    if($user->ID()) {
      my %cdata = (
        UserID => $user->ID(),
        Status => $user->Status(),       
        FirstName => $user->FirstName(),       
        FamilyName => $user->FamilyName(),
        Email => $user->Email(),       
      );
      $self->{'Info'} = \%cdata;

      if($self->{'cache'})  {
        $self->{'cache'}->set('swm',"SRSESSION-".$self->{'key'}, \%cdata,'',8*60*60);
      }
    }
  }
  return 1;
}


sub load {
  my $self = shift;
  my ($sessionK) = @_;

  my $output = new CGI;
  my $sessionkey = $sessionK || $output->cookie($Defs::COOKIE_SRLOGIN) || '';
  return undef if !$sessionkey;
  my $info = '';
  my $userID = 0;
  $self->{'key'} = $sessionkey;
  if($self->{'cache'})  {
    $info = $self->{'cache'}->get('swm',"SRSESSION-$sessionkey");
  }
  if($info) {
    $userID = $info->{'UserID'} || 0;
    $self->{'Info'} = $info || {};
  }       

  $self->{'UserID'}=$userID || 0;
  return $userID || 0;
}

sub status {
    my $self = shift;
    return $self->{'Info'}{'Status'} || 0;
}

sub name {
    my $self = shift;
    return $self->{'Info'}{'FirstName'} || '';
}

sub familyname {
    my $self = shift;
    return $self->{'Info'}{'FamilyName'} || '';
}

sub fullname {
    my $self = shift;
    return join( ' ', $self->{'Info'}{'FirstName'}, $self->{'Info'}{'FamilyName'} );
}

sub email {
    my $self = shift;
    return $self->{'Info'}{'Email'} || '';
}

1;
