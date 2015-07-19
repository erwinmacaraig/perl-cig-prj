package PersonObj;

use strict;
use BaseObject;
our @ISA =qw(BaseObject);
use SphinxUpdate;


sub setCachePrefix    {
    my $self = shift;
    $self->{'cachePrefix'} = 'PersonObj';
}

sub load {
  my $self = shift;

	my $st=qq[
    SELECT
        tblPerson.*,
        DATE_FORMAT(dtDOB,'%d/%m/%Y') AS dtDOB_Format,
        DATE_FORMAT(tblPerson.tTimeStamp,'%d/%m/%Y') AS tTimeStamp,
        MN.strNotes
    FROM
        tblPerson
        LEFT JOIN tblPersonNotes as MN ON (
          MN.intPersonID = tblPerson.intPersonID
        )
      WHERE
    tblPerson.intPersonID = ?
	];
	my $q = $self->{'db'}->prepare($st);
	$q->execute(
		$self->{'ID'},
	);
	if($DBI::err)	{
		$self->LogError($DBI::err);
	}
	else	{
		$self->{'DBData'}=$q->fetchrow_hashref();	
	}
}

sub name {
    my $self = shift;

    my $surname   = $self->getValue('strLocalSurname');
    my $firstname = $self->getValue('strLocalFirstname');

    return "$firstname $surname";
}
sub firstname {
    my $self = shift;
    my $firstname = $self->getValue('strLocalFirstname');
    return $firstname;
}
sub surname {
    my $self = shift;
    my $surname = $self->getValue('strLocalSurname');
    return $surname;
}

# Across realm check to see there is an existing member with this firstname/surname/dob and with primary club set.
# Static method.
sub already_exists {
    my $class = shift;

    my ($Data, $new_member, $sub_realm_id) = @_;

    my $realm_id = $Data->{'Realm'};

    $sub_realm_id ||= $Data->{'RealmSubType'};

    my $st = qq[
        SELECT
            M.intPersonID,
            M.strLocalFirstname,
            M.strLocalSurname,
            M.strEmail,
            M.dtDOB,
            M.strNationalNum
        FROM tblPerson as M 
        WHERE
            M.intRealmID=?
            AND M.strLocalFirstname=?
            AND M.strLocalSurname=?
            AND M.dtDOB=?
            AND M.intStatus=1
     ];

    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $realm_id,
        $sub_realm_id,
        $new_member->{'firstname'},
        $new_member->{'surname'},
        $new_member->{'dob'},
    );

    my @matched_members = ();
    while (my $dref = $q->fetchrow_hashref()) {
        push @matched_members, $dref;
 }
    return \@matched_members;
}

sub _get_sql_details{

    my $field_details = {
        'fields_to_ignore' => ['tTimeStamp','strNotes','dtDOB_Format'],
        'table_name' => 'tblPerson',
        'key_field' => 'intPersonID',
    };

    return $field_details;
}

sub searchServerUpdate {
    my $self = shift;
    my ($actionType, $db, $cache) = @_;
    updateSphinx($db, $cache, 'Person', $actionType, $self);
    return 1;
}


1;
