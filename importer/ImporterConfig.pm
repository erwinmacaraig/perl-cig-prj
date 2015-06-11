package ImporterConfig;
require Exporter;
@ISA =  qw(Exporter);
%DB_CONFIG = (
		"DB_DSN" => "DBI:mysql:fifaconnectHongKong_import", #fifasponline
		"DB_USER" => "root",
		"DB_PASSWD" => "root"
);

$DefaultISOCountry = "HK";

@PREDEFINED = (
    "NOW()"
);

#%MADefaultstrImportEntityCodeID = 1;

$AGE_BREAKPOINT_PLAYER_PROFESSIONAL = "AGE_BREAKPOINT_PLAYER_PROFESSIONAL";
$AGE_BREAKPOINT_PLAYER_AMATEUR_U_C = 16;

%ADULT_AGE = (
    "FROM" => 21,
    "TO" => 100,
);

$AGE_LEVEL_ADULT = "ADULT";
$AGE_LEVEL_MINOR = "MINOR";

1;
