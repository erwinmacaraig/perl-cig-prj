package CustomFields;
require Exporter;

@ISA =  qw(Exporter);
@EXPORT = qw(getCustomFieldNames );
@EXPORT = qw(getCustomFieldNames );

use strict;

sub getCustomFieldNames	{
	my($Data, $subtypeID)=@_;
	my $db=$Data->{'db'};
	my $realmID=$Data->{'Realm'} || 0;
    $subtypeID||=$Data->{'RealmSubType'} || 0;
	my %CustomFieldNames=();
	if($db)	{
		my $statement=qq[
			SELECT 
                strDBFName, 
                strName, 
                intLocked, 
                intSubTypeID
			FROM 
                tblCustomFields
			WHERE 
                intRealmID = ?
			ORDER BY 
                intSubTypeID ASC 
        ];
        my $query = $db->prepare($statement);
        $query->execute($realmID);
        while (my($dbf, $name, $locked, $subtype) = $query->fetchrow_array) {
            next if($subtype and $subtype != $subtypeID);
            $CustomFieldNames{$dbf}=[$name, $locked];
        }
	}
	return \%CustomFieldNames;
}


1;
