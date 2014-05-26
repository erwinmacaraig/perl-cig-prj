#
# $Header: svn://svn/SWM/trunk/web/NodeStructure.pm 10049 2013-12-01 22:34:56Z tcourt $
#

package NodeStructure;

require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(createTempNodeStructure);
@EXPORT_OK = qw(createTempNodeStructure);

use strict;

use lib '.', '..';
use Defs;
use Utils;

use DeQuote;
 

sub createTempNodeStructure	{

	my ($Data, $realmID) = @_;
	my $db = $Data->{'db'};

	$realmID ||= 0;

	my $del_st = qq[
		DELETE FROM 
			tblTempNodeStructure
		WHERE 
			intRealmID = ?
	];

	my $del_qry= $db->prepare($del_st);


	my $levels_st = qq[
		SELECT 
			A.intAssocID,
			NZone.intNodeID as int10_ID,
			NRegion.intParentNodeID as int20_ID,
			NState.intParentNodeID as int30_ID,
			NNational.intParentNodeID as int100_ID
		FROM 
			tblAssoc as A
			INNER JOIN tblAssoc_Node as NZone ON (
				A.intAssocID = NZone.intAssocID
				AND NZone.intPrimary = 1
			)
			INNER JOIN tblNodeLinks as NRegion ON (
				NRegion.intChildNodeID = NZone.intNodeID
				AND NRegion.intPrimary = 1
			)
			INNER JOIN tblNodeLinks as NState ON (
				NState.intChildNodeID = NRegion.intParentNodeID
				AND NState.intPrimary = 1
			)
			INNER JOIN tblNodeLinks as NNational ON (
				NNational.intChildNodeID = NState.intParentNodeID
				AND NNational.intPrimary = 1
			)
		WHERE 
			A.intRealmID = ?
	];
        my $levels_qry = $db->prepare($levels_st);
	

	my $ins_st = qq[
		INSERT IGNORE INTO tblTempNodeStructure
		(intRealmID, int100_ID, int30_ID, int20_ID, int10_ID, intAssocID)
		VALUES (?,?,?,?,?,?)
	];
	my $ins_qry= $db->prepare($ins_st);

	my $st = qq[
		SELECT 
			intRealmID
		FROM 
			tblRealms
	];

	$st .= qq[ WHERE intRealmID = $realmID] if $realmID;

        my $qry = $db->prepare($st);
	$qry->execute;
        while (my($intRealmID) = $qry->fetchrow_array) {
		$intRealmID || next;
		$del_qry->execute($intRealmID);
		$levels_qry->execute($intRealmID);
        	while (my $lref = $levels_qry->fetchrow_hashref()) {
			$ins_qry->execute($intRealmID, $lref->{int100_ID}, $lref->{int30_ID}, $lref->{int20_ID}, $lref->{int10_ID}, $lref->{intAssocID});
		}
	}
	
}


