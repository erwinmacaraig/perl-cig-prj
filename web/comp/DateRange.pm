#
# $Header: svn://svn/SWM/trunk/web/comp/DateRange.pm 8251 2013-04-08 09:00:53Z rlee $
#

package DateRange;
require Exporter;
@ISA = qw(Exporter);
@EXPORT=qw(getDateRange);
@EXPORT_OK=qw(getDateRange);

use strict;
use Date::Range;
use Date::Simple ();

sub getDateRange	{
	my ($dtFrom, $dtTo) = @_;

    if (!$dtFrom or !$dtTo) {
        return undef;
    }

	my $start= Date::Simple->new($dtFrom);
	my $end= Date::Simple->new($dtTo);
	my $range = Date::Range->new($start, $end);
    
	my @all_dates = $range->dates;
	my @dates=();
	foreach my $date (@all_dates)	{
		push @dates, $date;
	}

	return \@dates;

}
