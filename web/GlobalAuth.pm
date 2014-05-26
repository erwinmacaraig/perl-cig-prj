#
# $Header: svn://svn/SWM/trunk/web/GlobalAuth.pm 8251 2013-04-08 09:00:53Z rlee $
#

package GlobalAuth;

require Exporter;
@ISA =  qw(Exporter);

@EXPORT = qw(
	validateGlobalAuth
);

@EXPORT_OK = qw(
	validateGlobalAuth
);

use lib "..","../comp";
use Defs;
use strict;

sub validateGlobalAuth {
	my (
		$Data,
		$passportID,
		$entityTypeID,
		$entityID,
	) = @_;

	my $admin = 0;
	my $cache = $Data->{'cache'} || undef;
	$admin = $cache->get('swm',"GLOBALADMIN_$passportID") if $cache;

	if(!$admin)	{
		my $st =qq[
			SELECT intPassportID 
			FROM tblGlobalAuth
			WHERE intPassportID = ?
		];
		my $q = $Data->{'db'}->prepare($st);
		$q->execute($passportID);
		($admin) = $q->fetchrow_array();
		$q->finish();
		return (0,0) if !$admin;
		$cache->set('swm',"GLOBALADMIN_$passportID",1,'',60*8) if $cache;
	}

	if($entityTypeID > $Defs::LEVEL_ASSOC)	{
		return(1,0);
	}
	elsif($entityTypeID == $Defs::LEVEL_ASSOC)	{
		return(1,$entityID);
	}
	elsif(
		$entityTypeID == $Defs::LEVEL_CLUB
		or $entityTypeID == $Defs::LEVEL_TEAM
	)	{
		my $assocID = 0;
		if($entityTypeID == $Defs::LEVEL_CLUB)	{
			#my $obj = getInstanceOf($Data,'club',$entityID);
			#$assocID = $obj->assocID();
			my $st = qq[SELECT intAssocID FROM tblAssoc_Clubs WHERE intClubID = ?];
			my $q = $Data->{'db'}->prepare($st);
			$q->execute($entityID);
			($assocID) = $q->fetchrow_array();
			$q->finish();
		}
		elsif($entityTypeID == $Defs::LEVEL_TEAM)	{
			my $st = qq[SELECT intAssocID FROM tblTeam WHERE intTeamID = ?];
			my $q = $Data->{'db'}->prepare($st);
			$q->execute($entityID);
			($assocID) = $q->fetchrow_array();
			$q->finish();
			#my $obj = getInstanceOf($Data,'team',$entityID);
			#$assocID = $obj->assocID();
		}
		return(1,$assocID || 0);
	}
	return (1,0);
}


1;
