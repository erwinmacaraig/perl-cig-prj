package EntityObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);
use SphinxUpdate;

sub setCachePrefix    {
    my $self = shift;
    $self->{'cachePrefix'} = 'EntityObj';
}

sub load {
  my $self = shift;

  my $st=qq[
    SELECT * 
    FROM tblEntity
    WHERE intEntityID = ?
  ];

  my $q = $self->{'db'}->prepare($st);
  $q->execute($self->{'ID'});
  if($DBI::err)  {
    $self->LogError($DBI::err);
  }
  else  {
    $self->{'DBData'}=$q->fetchrow_hashref();  
  }
}

sub name {
  my $self = shift;
    my($db) = @_;
    return $self->{'DBData'}{'strLocalName'} 
        || $self->{'DBData'}{'strLatinName'} 
        || '';
}

sub delete {
  my $self = shift;

  if ($self->canDelete()) {
    my @errors = ();
    my $db = $self->{'db'};
    my $st = qq[
      UPDATE tblEntity
      SET strStatus = 'DELETED'
      WHERE 
          intEntityID = ?
      LIMIT 1
    ];
    my $q = $db->prepare($st);
    $q->execute($self->ID());
    $q->finish();
    if ($db->err()) {
        push @errors, $db->errstr();
    }
    if (scalar @errors) {
        return "ERROR:";
    }
    else {
        return 1;
    }
  }
  else {
      return 0;
  }
}

sub canDelete {
  my $self = shift;

  my $st = qq[
    SELECT COUNT(*)
    FROM 
        tblEntityLinks AS EL
        INNER JOIN tblEntity AS E 
            ON EL.intChildEntityID = E.intEntityID
    WHERE
        EL.intParentEntityID = ?
        AND E.strStatus <> 'DELETED'
  ];
  my $q = $self->{'db'}->prepare($st);
  $q->execute($self->{'ID'});
  my ($cnt) = $q->fetchrow_array();
  $q->finish();
  return !$cnt;
}

sub _get_sql_details{

    my $field_details = {
        'fields_to_ignore' => ['tTimeStamp'],
        'table_name' => 'tblEntity',
        'key_field' => 'intEntityID',
    };

    return $field_details;
}

sub searchServerUpdate {
    my $self = shift;
    my ($actionType, $db, $cache) = @_;
    updateSphinx($db, $cache, 'Entity', $actionType, $self);
    return 1;
}


1;
