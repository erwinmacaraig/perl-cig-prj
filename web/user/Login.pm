package Login;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    login
);
@EXPORT_OK = qw(
	login
);

use strict;
use lib '.','..','../..';
use Defs;
use Utils;
use Lang;
use CGI qw(:cgi escape);

use UserObj;
use UserHash;
use UserSession;

use MCache;

sub login	{
	my (
		$Data,
		$username,
		$password,
	) = @_;

	my $l = $Data->{'lang'};
    my @errors = ();
	if(!$username)	{
		push @errors, $l->txt('You must enter an username address');
	}
	if(!$password)	{
		push @errors, $l->txt('You must enter a password');
	}

    if(scalar(@errors)) {

        return ('',\@errors);
    }
	my $st = qq[
		SELECT 
			tblUser.userId,
			tblUserHash.passwordHash
		FROM tblUser
			LEFT JOIN 
				tblUserHash
				ON tblUserHash.userId = tblUser.userId
		WHERE 
			username = ?
	];
	my $q = $Data->{'db'}->prepare($st);
	$q->execute($username);
	my($userID, $passwordHash) = $q->fetchrow_array();
	$q->finish();
	if($userID)	{
		my $sessionKey = verify_login(
			$Data,
			$userID,
			\@errors,
			$password, 
			$passwordHash,
		) || '';
warn("SK $sessionKey");
        return ($sessionKey,\@errors);
	}
	else	{
			push @errors, $l->txt("I'm sorry but we can't find you as a registered user.");
	}
    return ('',\@errors);
}

sub verify_login {
	my (
		$Data,
		$userID,
		$errors,
		$password, 
		$passwordHash,
	) = @_;

	my $l = $Data->{'lang'};
	my $userObj = new UserObj(
		db => $Data->{'db'},
		id => $userID,
	);
	$userObj->load();
    my $msg = '';
	my $status = $userObj->Status();
	#$msg = user_notconfirmed($Data, $userObj) 
		#if $status == $Defs::USER_STATUS_NOTCONFIRMED;
	$msg = user_suspended($Data, $userObj) 
		if $status == $Defs::USER_STATUS_SUSPENDED;
	$msg = user_usernamesuspended($Data, $userObj) 
		if $status == $Defs::USER_STATUS_EMAILSUSPENDED;
	$msg = user_deleted($Data, $userObj) 
		if $status == $Defs::USER_STATUS_DELETED;
    if($msg)    {
        push @{$errors}, $msg;
        return '';
    }

	if($status == $Defs::USER_STATUS_CONFIRMED)	{
		#Check password
		#create hash of the user given to us
		my $valid_pw = checkHash(
			$userID.$password,
			$passwordHash || '',
		) || 0;
		if($valid_pw)	{
            my $session = new UserSession(
                cache => $Data->{'cache'},
                db => $Data->{'db'},
                ID => $userID,
            );
            warn($session->key());
            return $session->key();
		}
		else	{
			push @{$errors}, $l->txt("Invalid Username & Password");
		}
	}
	else	{
		push @{$errors}, $l->txt("I'm sorry but we can't find you as a registered user.");
	}
	return '';
}

sub user_notconfirmed	{
	my(
		$Data,
		$UserObj,

	) = @_;

	my $body = $Data->{'lang'}->txt('Your user account is not yet confirmed');
	return $body;
}

sub user_suspended{
	my(
		$Data,
		$UserObj,

	) = @_;

	my $body = $Data->{'lang'}->txt('Your user account is currently suspended');
	return $body;
}

sub user_usernamesuspended{
	my(
		$Data,
		$UserObj,

	) = @_;

	my $body = $Data->{'lang'}->txt('Your user account is currently suspended because your username address is incorrect.');
	return $body;
}

sub user_deleted	{
	my(
		$Data,
		$UserObj,

	) = @_;

	my $body = $Data->{'lang'}->txt('Your user account has been deleted.');
	return $body;
}	

sub sendReminder	{
	my ( 
		$Data,
	) = @_;


}



1;
