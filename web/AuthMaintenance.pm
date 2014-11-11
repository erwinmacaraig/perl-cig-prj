package AuthMaintenance;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(handleAuthMaintenance);
@EXPORT_OK = qw(handleAuthMaintenance);

use strict;
use Reg_common;
use Utils;
use CGI qw(unescape param popup_menu);
use AuditLog;
use TTTemplate;
use UserObj;
use GridDisplay;

sub handleAuthMaintenance {
	my (
		$action,
		$Data,
		$entityTypeID,
		$entityID
	) = @_;
	my $client = setClient($Data->{'clientValues'});
	my $resultHTML  = q{};
	my $title       = 'User Management';
	my $ret         = q{};

    return '' if $Data->{'clientValues'}{'authLevel'} < $Defs::LEVEL_NATIONAL;
	if(!$entityTypeID or !$entityID)	{
		$entityTypeID = $Data->{'clientValues'}{'currentLevel'};
		$entityID = getID($Data->{'clientValues'}, $entityTypeID);
	}
	my $typename = $Defs::LevelNames{$entityTypeID} || '';
	$title .= ' - ' . $typename;

	if ($action =~/^AM_d/) {
		$resultHTML .= auth_delete(
			$Data,
			$entityTypeID,
			$entityID,
			$client,
		);
	}
	elsif ($action =~/^AM_a/) {
		$resultHTML .= auth_add (
			$Data,
			$entityTypeID,
			$entityID,
			$client,
		);
	  $resultHTML.=$ret;
		$action = 'FC_C_d';
	}
	$resultHTML .= auth_list (
		$Data,
		$entityTypeID,
		$entityID,
		$client,
	);

  return (
		$resultHTML,
		$title
	);
}

sub auth_list {
	my (
		$Data,
		$entityTypeID,
		$entityID,
		$client,
	) = @_;

	my $db = $Data->{'db'};
	my $st = qq[
		SELECT
			u.userId,
			ua.readOnly,
			DATE_FORMAT(lastLogin,'%Y-%m-%d (%H:%i %p)') as dtLastLogin_FMT,
            u.status,
            u.username,
            u.firstName,
            u.familyName,
            ua.readOnly
		FROM
			tblUser as u
                INNER JOIN tblUserAuth as ua ON (ua.userId=u.userId)
		WHERE
			entityTypeID = ?
			AND entityID = ?
        ORDER BY
            familyName,
            firstName

	];
	my $q = $db->prepare($st);
	$q->execute(
		$entityTypeID,
		$entityID,
	);

    my @authlist = ();
	my %authdetails = ();
	my $addaction = 'AM_a';
	my $addaction2 = '';
	my $delaction = 'AM_d';
	my $delaction2 = '';
	if($entityTypeID == $Defs::LEVEL_VENUE)	{
	    $addaction = 'VENUE_USER';
		$addaction2 = 'AM_a';
		$delaction = 'VENUE_USER';
		$delaction2 = 'AM_d&venueID='.$entityID;
	}
    my @outputdata = ();

    while(my $dref=$q->fetchrow_hashref()) {
        my $name = join (' ',($dref->{'firstName'} || ''), ($dref->{'familyName'} || ''));
        next if !$dref->{'username'};
        next if !$dref->{'status'} == 2;
        my $deleteLink = qq[<a href = "$Data->{'target'}?a=$delaction&amp;a2=$delaction2&amp;id=$dref->{'userId'}&amp;client=$client" onclick = "return confirm('Are you sure you want to remove $name?');">Delete</a>];
        $deleteLink = '-' if($dref->{'userId'} ==$Data->{'clientValues'}{'userID'} and $entityTypeID==$Data->{'clientValues'}{'authLevel'} and ($Data->{'ReadOnlyLogin'}));
		push @outputdata, {
		    id => $dref->{'userId'} || next,
			Name => $name,
			Username => $dref->{'username'},
			ReadOnly => $dref->{'readOnly'},
			AccessLevel => $dref->{'readOnly'}? 'Restricted Access' : 'Full',
			LastLogin => $dref->{'dtLastLogin_FMT'} || '',
			DeleteLink => $deleteLink,
        };
    }
	my @headers = (
    {
      name =>   $Data->{'lang'}->txt('Name'),
      field =>  'Name',
    },
    {
      name =>   $Data->{'lang'}->txt('Username'),
      field =>  'Username',
    },
    {
      name =>   $Data->{'lang'}->txt('Access'),
      field =>  'AccessLevel',
    },
    {
      name =>   $Data->{'lang'}->txt('Last Login'),
      field =>  'LastLogin',
	},
    {
      name =>   $Data->{'lang'}->txt(' '),
      field =>  'DeleteLink',
			type => 'HTML',
    },
	);

  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@outputdata,
    gridid => 'grid',
    width => '99%',
  );

	my $body = runTemplate(
		$Data,
		{
			AuthList => \@outputdata,
			Grid => $grid,
			client => $client,
			Target => $Data->{'target'},
			TypeName => $Defs::LevelNames{$entityTypeID} || '',
			AddAction => $addaction,
			AddAction2 => $addaction2,
			ID => $entityID,
		},
		'auth/authlist.templ',
	);

	return $body;
}

sub auth_delete {
	my (
		$Data,
		$entityTypeID,
		$entityID,
		$client,
	) = @_;

	my $db = $Data->{'db'};

	my $id = param('id') || '';
	return '' if !$id;

	my $st = qq[
		DELETE FROM tblUserAuth
		WHERE
			entityTypeID = ?
			AND entityID = ?
			AND userId= ?
	];
	my $q = $db->prepare($st);
	$q->execute(
		$entityTypeID,
		$entityID,
		$id,
	);
	$q->finish();
    auditLog($id, $Data, 'Delete', 'User Management');
	return qq[<div class = "OKmsg">].$Data->{'lang'}->txt('User access removed') .qq[</div>];
}
sub loadUserDetails {
    my ($Data, $username) = @_;

    my $st = qq[
        SELECT
            *
        FROM
            tblUser
        WHERE
            username=?
    ];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($username);
    my $dref = $q->fetchrow_hashref();
    return $dref;
}

sub auth_add {
	my (
		$Data,
		$entityTypeID,
		$entityID,
		$client,
	) = @_;

	my $db = $Data->{'db'};
	my $lang = $Data->{'lang'};

	my $newusername = param('newusername') || '';
	my $newfname= param('newfname') || '';
	my $newsname= param('newsname') || '';
	my $newpassword= param('newpassword') || '';
	my $newpassword2= param('newpassword2') || '';
	my $readonly = param('readonly') || 0;
    my @missingFields = ();
	return '' if !$entityTypeID;
	return '' if !$entityID;
	push @missingFields, $lang->txt('First name') if !$newfname;
	push @missingFields, $lang->txt('Family name') if !$newsname;
	push @missingFields, $lang->txt('Username') if !$newusername;
	push @missingFields, $lang->txt('Password') if !$newpassword;
	push @missingFields, $lang->txt('Re-enter Password') if !$newpassword2;

    if(scalar(@missingFields))  {
        my $fields = '<li>'.join('<li>',@missingFields);
        return qq[<div class = "warningmsg">].$Data->{'lang'}->txt("Missing Fields:") .qq[<ul>$fields</ul></div>];
    }
    if($newpassword ne $newpassword2)  {
        return qq[<div class = "warningmsg">].$Data->{'lang'}->txt('Passwords do not match') .qq[</div>];
    }
    my $user = new UserObj(db => $db);
    my $found = $user->load(username => $newusername);
    if($found)  {
        return qq[<div class = "warningmsg">].$Data->{'lang'}->txt('Username already exists') .qq[</div>];
    }
    my %userData = (
        username => $newusername,
        firstName=> $newfname,
        familyName=> $newsname,
        status => $Defs::USER_STATUS_CONFIRMED,
    );
    $user->update(\%userData);
    
	if($user->ID()) {
        $user->setPassword($newpassword);
		my $st = qq[
			INSERT INTO tblUserAuth (
                userId,
                entityTypeId,
                entityId,
                readOnly
			)
			VALUES (
				?,
				?,
				?,
				?
			)
		];
		my $q = $db->prepare($st);
		$q->execute(
			$user->ID(),
			$entityTypeID,
			$entityID,
			$readonly,
		);
		$q->finish();

        auditLog($user->ID(), $Data, 'Add', 'User Management');
	}
	else	{
        return qq[<div class = "warningmsg">].$Data->{'lang'}->txt("I'm sorry I can't find that user") .qq[</div>];
	}

	return qq[<div class = "OKmsg">].$Data->{'lang'}->txt('User access granted') .qq[</div>];
}

1;
