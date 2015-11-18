package LangBase;

@EXPORT= (qw/txt lexicon/);
use Locale::Maketext::Gettext;
use Encode;
use base ('Locale::Maketext::Gettext');

sub txt (@) { 
  my $self=shift @_;
  return '' if !$_[0];

  my @temp = @_;
  $temp[0] =~ s/^\n+//m;
  $temp[0] =~ s/\n+$//m;
  return $temp[0] if($temp[0] =~ /[^\0-\x7f]/); #return key if key is non-ascii
  for my $b (@temp) {
    $b = Encode::decode('UTF-8',$b);
  }

  my $s = $self->maketext(@temp); 
  return $s;
  #return qq[<span style='color:red !important;'>$s</span>];
} 

# I decree that this project's first language is English.

no warnings 'once';
#%Lexicon = (
  #'_AUTO' => 1,
  # That means that lookup failures can't happen -- if we get as far
  #  as looking for something in this lexicon, and we don't find it,
  #  then automagically set $Lexicon{$key} = $key, before possibly
  #  compiling it.
  
  # The exception is keys that start with "_" -- they aren't auto-makeable.

#);
# End of lexicon.


# a copy of quant without the print of the num first
# maybe quantNoNum or even integrate with quant
sub quant2 {
    my($handle, $num, @forms) = @_;

    return $num if @forms == 0; # what should this mean?
    return $forms[2] if @forms > 2 and $num == 0; # special zeroth case

    return( $handle->numerate($num, @forms) );
}

sub getNumberOf {
    my $result = 'Number of ' . $_[1];
    return $result;
}


sub getSearchingFrom {
    my $result = 'Searching from ' . $_[1] . ' down';
    return $result;
}

#sub lexicon { eval( '%' . substr(ref(shift),0,8) . '::Lexicon') || () }


    sub DESTROY {
        my $self = shift;
        
        $self->SUPER::DESTROY;
    }

1;  # End of module.
package LangBase::en_us;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::en_bsw;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::fi_fi;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::fr_fr;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::sv_se;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::zh_cn;
use base qw(Locale::Maketext::Gettext);
return 1;

package LangBase::en_ca;
use base qw(Locale::Maketext::Gettext);
return 1;
