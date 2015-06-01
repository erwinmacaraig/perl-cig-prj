package EntityStructure;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(createTempEntityStructure);
@EXPORT_OK = qw(createTempEntityStructure);

use strict;

use lib '.', '..';
use Defs;
use Utils;

sub createTempEntityStructure  {

  my ($Data, $realmID_IN, $id) = @_;
  my $realmID=1;
  ## if $id passed then only work on that 1 ID
  $id ||= 0;
  my $db = $Data->{'db'};

  my $ins_st = qq[
    INSERT IGNORE INTO tblTempEntityStructure (
        intRealmID, 
        intParentID,
        intParentLevel,
        intChildID,
        intChildLevel,
        intDirect,
        intDataAccess,
        intPrimary
    )
    VALUES (
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?,
        ?
    )
  ];
  my $ins_qry= $db->prepare($ins_st);

  my $del_st = qq[
    DELETE FROM 
        tblTempEntityStructure
    WHERE 
      intRealmID = ?
  ];
    if ($id)    {
        $del_st .= qq[
            AND (intParentID = $id or intChildID = $id)
        ];
    }

  my $del_qry= $db->prepare($del_st);

  my $st_e = qq[
    SELECT
      intEntityID,
      intEntityLevel,
      intDataAccess
    FROM
      tblEntity
    WHERE
      intRealmID = ?
      AND strStatus <> 'DELETED'
  ];
  my $q_e = $db->prepare($st_e);


  #foreach my $realmID (@realms) {
    $del_qry->execute($realmID);
    $del_qry->finish();

    my %entities = ();
    $q_e->execute($realmID);
    while (my($id, $level, $dataaccess) = $q_e->fetchrow_array()) {
      $entities{$id} = {
          level => $level,
          dataaccess => $dataaccess,
      };
    }

    my $entity_list = join(',',keys %entities);
    my %entityLinks = ();
    my %entityLinksCtoP = ();
    if($entity_list)  {
      my $st_el = qq[
        SELECT
          intParentEntityID,
          intChildEntityID,
          intPrimary
        FROM
          tblEntityLinks
    ];
  #      WHERE
  #          intParentEntityID IN ($entity_list)
  #    ];
      my $q_el = $db->prepare($st_el);
      $q_el->execute();
      while (my($parent, $child, $primary) = $q_el->fetchrow_array()) {
        if(
            $parent 
            and $child 
            and exists($entities{$parent})
            and exists($entities{$child})
        )    {
          push @{$entityLinks{$parent}}, $child; 
          if(!exists $entityLinksCtoP{$child} or $primary)  {
              $entityLinksCtoP{$child} = $parent;
          }
          #Insert the direct relationships
            if ($id)    {
                next if (
                    $parent != $id 
                    and ! $child != $id
                );
            }
          $ins_qry->execute(
              $realmID,
              $parent,
              $entities{$parent}{'level'},
              $child,
              $entities{$child}{'level'},
              1,
              $entities{$child}{'dataaccess'},
              $primary
          );
        }
      }
    }

    #Now to generate and insert the indirect relationships
    foreach my $entityID (keys %entities)    {
      insertRelationships(
          $entityID,
          \%entities,
          \%entityLinks,
          $ins_qry, 
          $realmID,
      );
    }

    createTreeStructure($db, $realmID, $id, \%entities, \%entityLinks, \%entityLinksCtoP);
  #}
}

sub insertRelationships {
    my  (
        $entityID,
        $entities,
        $entityLinks,
        $qry,
        $realmID,
    ) = @_;

    my @children = ();
    my $myDataAccess = $entities->{$entityID}{'dataaccess'};
    if(exists($entityLinks->{$entityID})) {
      foreach my $childID (@{$entityLinks->{$entityID}}) {
          push @children, {
            id => $childID,
            dataaccess => $entities->{$childID}{'dataaccess'},
          };
          my $ret = insertRelationships(
            $childID,
            $entities,
            $entityLinks,
            $qry,
            $realmID,
          );
          push @children, @{$ret} if $ret;
      }
      foreach my $child (@children) {
          $qry->execute(
              $realmID,
              $entityID,
              $entities->{$entityID}{'level'},
              $child->{'id'},
              $entities->{$child->{'id'}}{'level'},
              0,
              $child->{'dataaccess'},
              $child->{'primary'},
          );
          if($myDataAccess < $child->{'dataaccess'})  {
            $child->{'dataaccess'} = $myDataAccess;
          }
      }

    }
    return \@children;
}

sub createTreeStructure {
    my (
        $db, 
        $realmID, 
        $id,
        $entities, 
        $entityLinks,
        $entityLinksCtoP,
    ) = @_;
    
    my %pathToNational = ();


    foreach my $eId (keys %{$entityLinksCtoP})    {
        next if !$entities->{$eId};
        my @path = ();
        my $count = 5;
        my $workingId = $eId;
        my $found = 0;
        for my $i ( 1 .. 5) {
            my $level = $entities->{$workingId}{'level'};
            push @path, [$workingId, $level];
            if($level == 100)   {
                $found = 1;
                last;
            }
            else    {
                $workingId = $entityLinksCtoP->{$workingId};
            }
        }
        if($found)  {
            $pathToNational{$eId} = \@path;
        }
    }
    my $ins_st = qq[
        INSERT INTO tblTempTreeStructure (
            intRealmID, 
            int100_ID,
            int30_ID,
            int20_ID,
            int10_ID,
            int3_ID
        )
        VALUES (
            ?,
            ?,
            ?,
            ?,
            ?,
            ?
        )
    ];
    my $ins_qry= $db->prepare($ins_st);

    my $del_st = qq[
      DELETE FROM 
        tblTempTreeStructure
      WHERE 
        intRealmID = ?
    ];
    if ($id)    {
        $del_st .= qq[
            AND (int3_ID = $id or int10_ID = $id or int20_ID = $id or int30_ID = $id or int100_ID = $id)
        ];
    }

    my $del_qry= $db->prepare($del_st);
    $del_qry->execute($realmID);
    foreach my $eId (keys %pathToNational)  {
        my %row = ();
        for my $r (@{$pathToNational{$eId}})    {
            $row{'t'.$r->[1]} = $r->[0];
        }
        $row{'t100'} ||= 0;
        $row{'t30'} ||= 0;
        $row{'t20'} ||= 0;
        $row{'t10'} ||= 0;
        $row{'t3'} ||= 0;

        if ($id)    {
            next if (
                $row{'t100'} != $id
                and $row{'t30'} != $id
                and $row{'t20'} != $id
                and $row{'t10'} != $id
                and $row{'t3'} != $id
            );
        }
        
        $ins_qry->execute(
          $realmID,
          $row{'t100'} || 0,
          $row{'t30'} || 0,
          $row{'t20'} || 0,
          $row{'t10'} || 0,
          $row{'t3'} || 0,
        );

    }


}
