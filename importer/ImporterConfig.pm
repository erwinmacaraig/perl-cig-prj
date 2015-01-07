package ImporterConfig;
require Exporter;
@ISA =  qw(Exporter);
%DB_CONFIG = (
		"DB_DSN" => "DBI:mysql:fifasponline_demo", #fifasponline
		"DB_USER" => "root",
		"DB_PASSWD" => "root"
);

$DefaultISOCountry = "SG";

@PREDEFINED = (
    "NOW()"
);
1;
