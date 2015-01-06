package ImporterConfig;
require Exporter;
@ISA =  qw(Exporter);
%DB_CONFIG = (
		"DB_DSN" => "DBI:mysql:fifasponline",
		"DB_USER" => "root",
		"DB_PASSWD" => ""
);

$DefaultISOCountry = "SG";
1;
