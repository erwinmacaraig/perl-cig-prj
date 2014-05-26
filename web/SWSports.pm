#
# $Header: svn://svn/SWM/trunk/web/SWSports.pm 8251 2013-04-08 09:00:53Z rlee $
#

package SWSports;
require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(getSWSports);
@EXPORT_OK = qw(getSWSports);

sub getSWSports	{
	my %sports=	(
		1=>'Australian Football',
		2=>'Baseball',
		3=>'Lawn Bowls',
		4=>'Softball',
		5=>'Netball',
		6=>'Basketball',
		7=>'Cricket',
		8=>'Rugby League',
		9=>'Rugby',
		10=>'Soccer',
		11=>'Volleyball',
		12=>'Touch Football',
		13=>'Table Tennis',
		14=>'Canoeing',
		15=>'Tennis',
		16=>'Badminton',
		17=>'Squash',
		18=>'Hockey',
		19=>'Water Polo',
		20=>'Lacrosse',
		21=>'Beach Volleyball',
	);
	return \%sports;
}

