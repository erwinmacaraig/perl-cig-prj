package TempNodeStructureObj;

use lib;
use BaseObject2;
our @ISA = qw(BaseObject2);

use strict;

use Utils;

sub _getSQL {
    my $sql = getSimpleSQL('*', _getTableName(), _getKeyName(), 1);
    return $sql;
}

sub _getTableName {
    return 'tblTempNodeStructure';
}

sub _getKeyName {
    return 'intAssocID';
}

1;
