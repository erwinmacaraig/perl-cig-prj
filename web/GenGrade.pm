#
# $Header: svn://svn/SWM/trunk/web/GenGrade.pm 8251 2013-04-08 09:00:53Z rlee $
#

package GenGrade;

use Exporter;
@EXPORT=qw(new);

use lib "../web";
use strict;
use Utils;

#This code generates the grade that a member should be in
# NB This code requires that only one instance is running at one time or concurrency issues may occur.

sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my ($db, $realm, $realmSubTypeID, $assocID)=@_;
  my %fields=();
  $fields{db}=$db || '';
  $fields{availablenums}=();
  $fields{'realm'}=$realm || '';
  $fields{'realmSubTypeID'}=$realmSubTypeID || 0;
  $fields{'assocID'}=$assocID || 0;
	
	#Setup Values
	my $statement=qq[
		SELECT intAssocGradeID, DATE_FORMAT(dtDOBStart, "%Y%m%d") as DOBStart, DATE_FORMAT(dtDOBEnd, "%Y%m%d") as DOBEnd, intGradeGender
		FROM tblAssoc_Grade
		WHERE intRealmID = $realm
			AND intAssocID IN (0, $assocID)
			AND intRealmSubTypeID = $realmSubTypeID
			AND intRecStatus=1
		ORDER BY intAssocID, intRealmSubTypeID
	];
print STDERR $statement;
	my $query=$db->prepare($statement) or query_error($statement);
	$query->execute or query_error($statement);
	while (my $dref = $query->fetchrow_hashref())	{
		push @{$fields{'Grades'}}, [$dref->{intAssocGradeID}, $dref->{intGradeGender}, $dref->{DOBStart}, $dref->{DOBEnd}];
	}
	$query->finish();

	my $self={%fields};
  bless $self, $class;
  ##bless selfhash to GenCode;
  ##return the blessed hash
  return $self;
}


sub getGrade	{
	#return a members grade

	my $self = shift;
	my($gender, $dob) = @_;

	$gender ||= 0;
	$dob ||= 0;

	for my $grade (@{$self->{'Grades'}})	{
		print STDERR "IN GENGRADE_GETGRADE|$dob|$gender|$grade->[1]|$grade->[2]|TO:$grade->[3]\n";
		if ((! $gender or ! $grade->[1] or $gender == $grade->[1] or $grade->[1] == $Defs::GENDER_MIXED) and $dob >= $grade->[2] and $dob <= $grade->[3])	{
			return $grade->[0];
		}
	}
	return 0;
	
}
1;
