package PersonLanguages;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getPersonLanguages);

use strict;

use lib '.', '..';

use Defs;

sub getPersonLanguages {
	my(
        $Data,
        $localNames, 
        $withLocale,
    )=@_;
    $localNames ||= 0;
    $withLocale ||= 0;

    my $db=$Data->{'db'};
    my $realmID=$Data->{'Realm'} || 0;
    my $subtypeID =$Data->{'RealmSubType'} || 0;
    my @languages = ();
    if($db) {
        my $orderfield = $localNames ? 'strNameLocal' : 'strName';
        my $statement=qq[
            SELECT 
                intLanguageID,
                intSubRealmID,
                strName,
                strNameLocal,
                strLocale,
                intNonLatin
            FROM 
                tblLanguages
            WHERE 
                intRealmID = ?
            ORDER BY
                $orderfield ASC
        ];
        my $query = $db->prepare($statement);
        $query->execute($realmID);
        while (my $dref = $query->fetchrow_hashref) {
            next if($dref->{'intSubRealmID'} and $dref->{'intSubRealmID'} != $subtypeID);
            if($withLocale) {
                next if !$dref->{'strLocale'};
            }
            $dref->{'language'} = $dref->{$orderfield};
            push @languages, $dref;
        }
    }
    return \@languages;
}

