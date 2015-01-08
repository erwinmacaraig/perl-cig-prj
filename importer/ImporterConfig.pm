package ImporterConfig;
require Exporter;
@ISA =  qw(Exporter);
%DB_CONFIG = (
		"DB_DSN" => "DBI:mysql:fifaSingaporeTest", #fifasponline
		"DB_USER" => "root",
		"DB_PASSWD" => "devel3757"
);

$DefaultISOCountry = "SG";

@PREDEFINED = (
    "NOW()"
);
1;
