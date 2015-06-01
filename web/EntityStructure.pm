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

  my ($Data, $realmID_IN, $eid) = @_;
  my $realmID=1;
  ## if $eid passed then only work on that 1 ID
  $eid ||= 0;
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
    if ($eid)    {
        $del_st .= qq[
            AND (intParentID = $eid or intChildID = $eid)
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
        WHERE
            intParentEntityID IN ($entity_list)
      ];
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
            if ($eid)    {
                next if (
                    $parent != $eid 
                    and $child != $eid
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
            $eid,
          $entityID,
          \%entities,
          \%entityLinks,
          $ins_qry, 
          $realmID,
      );
    }

    createTreeStructure($db, $realmID, $eid, \%entities, \%entityLinks, \%entityLinksCtoP);
  #}
}

sub insertRelationships {
    my  (
            $eid,
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
            $eid,
            $childID,
            $entities,
            $entityLinks,
            $qry,
            $realmID,
          );
          push @children, @{$ret} if $ret;
      }
      foreach my $child (@children) {
             if ($eid)   {
                next if (
                    $entityID != $eid
                    and $child->{'id'} != $eid
                );
            }
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
        $eid,
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
            tTimeStamp,
            intRealmID, 
            int100_ID,
            int30_ID,
            int20_ID,
            int10_ID,
            int3_ID
        )
        VALUES (
            NOW(),
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
    if ($eid)    {
        $del_st .= qq[
            AND (int3_ID = $eid or int10_ID = $eid or int20_ID = $eid or int30_ID = $eid or int100_ID = $eid)
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

        if ($eid)    {
            next if (
                $row{'t100'} != $eid
                and $row{'t30'} != $eid
                and $row{'t20'} != $eid
                and $row{'t10'} != $eid
                and $row{'t3'} != $eid
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
