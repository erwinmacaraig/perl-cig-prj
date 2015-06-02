package FieldMessages;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getFieldMessages);
@EXPORT_OK = qw(getFieldMessages);

use lib '..', '.';

use strict;
use Defs;

sub getFieldMessages {
    my (
        $Data,
        $type, 
        $locale,
    )   = @_;

    return undef if !$Data;
    return undef if !$type;
    return undef if !$locale;

    my $sql = qq[
        SELECT 
            strFieldname,
            strType,
            strMessage
        FROM 
            tblFieldMessages
        WHERE 
            strFieldType = ?
            AND strLocale = ?
      ];
      my $q = $Data->{'db'}->prepare($sql);

      $q->execute($type, $locale);

      my %messages = ();
      while (my ($fieldname, $type, $message) = $q->fetchrow_array) {
        $messages{$fieldname} = {
            type => $type,
            msg => $message,    
        };
      }

      return \%messages;
}

1;
