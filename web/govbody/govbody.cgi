#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/govbody/govbody.cgi 10144 2013-12-03 21:36:47Z tcourt $
#

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib "../..","..",".";

use Defs;
use Utils;

main();

sub main	{
	my $action = param('a') || 'M';

	my $bodyID= param('bID') || 0;
	my $assocID= param('aID') || 0;
	my $target='govbody.cgi';

  my $username=$ENV{'REMOTE_USER'} || '';
	my($country,$sport)=$username=~/^(..)(..)/;
	my($db,$dberr)=connectDB($country,$sport);

	$action='INVALID' if !$db;

	my $body ='';
	if ($action eq 'M') { 
		$body.=menu($db, $bodyID, $target);
	}
	elsif ($action eq 'LU') { 
		$body.=latestUploads($db, $bodyID);
	}
	elsif ($action eq 'AS') { 
		$body.=show_assocs($db, $bodyID, $target);
	}
	elsif ($action eq 'UP') { 
		$body.=listUploads($db, $assocID, $target);
	}
	elsif ($action eq 'ULD') { 
		my $uID=param('uID') || 0;
		$body.=uploadDetail($db, $assocID, $target, $uID);
	}
	if($action ne 'M')	{
		$body=qq[ <p> <a href="$target?a=M&bID=$bodyID">&lt; Return to Menu</a> </p>
			$body
		];
	}
	if ($action eq 'INVALID') { 
		print STDERR "$ENV{REMOTE_ADDR}:  $username attempting access to gov body admin\n";
		$body=qq[
			<p class="actionresponse">You do not have permission to be here!</p>
			<p class="actionresponse">Only authorised people are allowed in this section!<br>You IP Address $ENV{REMOTE_ADDR} and user name $username have been logged. <br>$dberr</p>
		];
	}

	my $page_title = "$Defs::sitename - Governing Body : Management";
  print "Content-type: text/html\n\n";
  print qq[
<html>
  <head>
    <title>$page_title</title>
    <link rel="stylesheet" type="text/css" href="css/style.css">
  </head>
  <body>
    <div id="contentholder">
      <div id="content">$body</div> <!-- End Content -->
    </div> <!-- End Content Holder -->
  </body>
</html>
  ];


	disconnectDB($db);

}

# ************** SUBROUTINES BELOW *****************


sub menu	{
	my($db, $govBodyID, $target)=@_;

	my $body=qq[
	<div class="heading6">Governing Body Management Page</div>

		<ul>
			<li><a href="$target?a=LU&bID=$govBodyID">Last Uploads</a></li>
			<li><a href="$target?a=AS&bID=$govBodyID">Associations</a></li>
		</ul>

	];

	return $body;
}

sub latestUploads	{
	my($db, $govBodyID, $target)=@_;

	my $body=qq[
	<div class="heading6">Last Uploads</div>
	<p>The list below shows the last time a specific association has uploaded.  It is sorted in descending chronological order.
	</p>

		<table class="coloredtop" cellspacing="0" cellpadding="3">
			<tr>
				<th>Association</th>
				<th>Email</th>
				<th>Last Upload Date</th>
				<th>App</th>
				<th>App Version</th>
			</tr>
	];

	my %software=();
	{
		my $statement="
						SELECT intAssocID, strAppName, strAppVer
						FROM tblUpload
						ORDER BY dtUploadDateTime
		";
		my $query = $db->prepare($statement) or query_error($statement);
		$query->execute or query_error($statement);
		while (my($intAssocID_DB, $strAppName_DB, $strAppVer_DB) = $query -> fetchrow_array()) {
						$software{$intAssocID_DB}=[$strAppName_DB, $strAppVer_DB];
		}
	}
	my $statement = qq[
		SELECT tblAssoc.intAssocID, strName, strEmail, DATE_FORMAT(MAX(dtUploadDateTime),'%D %M %Y %H:%i') , MAX(dtUploadDateTime) as LastDate
		FROM tblAssoc, tblUpload
		WHERE tblUpload.intAssocID=tblAssoc.intAssocID
		GROUP BY intAssocID
		ORDER BY LastDate DESC
	];
	my $query = $db->prepare($statement) or query_error($statement);
	$query->execute or query_error($statement);

	my $cnt=0;
	while (my ($intAssocID_DB, $strName_DB, $strEmail_DB, $dtLastUpdated_DB) = $query -> fetchrow_array()) {
		$strName_DB ||= '';
		$strEmail_DB ||= '';
		$dtLastUpdated_DB ||= '&nbsp;';
		my $cl= $cnt%2==0 ? ' class="resultrow" ' :  ' class="resultrowshadedwithborder" ';
		$body .= qq[
		<tr>
			<td $cl>$strName_DB</td>
			<td $cl>$strEmail_DB</td>
			<td $cl>$dtLastUpdated_DB</td>
			<td $cl>].($software{$intAssocID_DB}[0] || '&nbsp;').qq[</td>
			<td $cl>].($software{$intAssocID_DB}[1] || '&nbsp;').qq[</td>
		<tr>
		];
		$cnt++;
	}
	$body .= qq[
			</table>
	];

	return $body;
}


sub show_assocs	{
	my($db, $govBodyID, $target)=@_;

	my $body=qq[
	<div class="heading6">Association List</div>
	<p>The list below shows the associations and their username/passwords.
	</p>

		<table class="coloredtop" cellspacing="0" cellpadding="3">
			<tr>
				<th>Association</th>
				<th>Email</th>
				<th>Username</th>
				<th>Password</th>
				<th>Access</th>
				<th>&nbsp;</th>
			</tr>
	];

	my $statement = qq[
		SELECT tblAssoc.intAssocID, tblAssoc.strName, tblAssoc.strEmail, strUsername, strPassword, tblDataAccess.intDataAccess
		FROM tblAssoc, tblAuth LEFT JOIN tblDataAccess ON (tblDataAccess.intTypeID=$Defs::LEVEL_ASSOC AND tblAssoc.intAssocID=tblDataAccess.intEntityID)
		WHERE intID=tblAssoc.intAssocID
            AND intLevel = $Defs::LEVEL_ASSOC
		ORDER BY strName ASC
	];
	my $query = $db->prepare($statement) or query_error($statement);
	$query->execute or query_error($statement);

	my $cnt=0;
	while (my $dref = $query -> fetchrow_hashref()) {
		my $cl= $cnt%2==0 ? ' class="resultrow" ' :  ' class="resultrowshadedwithborder" ';
		if(defined $dref->{intDataAccess} and !($dref->{intDataAccess} == $Defs::DATA_ACCESS_FULL  or $dref->{intDataAccess} == $Defs::DATA_ACCESS_READONLY))	{
			$dref->{strPassword}='<i>Withheld</i>';
		}
		$body .= qq[
		<tr>
			<td $cl>$dref->{strName}</td>
			<td $cl>$dref->{strEmail}</td>
			<td $cl>$dref->{strUsername}</td>
			<td $cl>$dref->{strPassword}</td>
			<td $cl>].($Defs::DataAccessNames{$dref->{intDataAccess}} || 'Unknown (no upload)').qq[</td>
			<td $cl><a href="$target?aID=$dref->{intAssocID}&bID=$govBodyID&a=UP">Uploads</a></td>
		<tr>
		];
		$cnt++;
	}
	$body .= qq[
			</table>
	];
	return $body;
}


sub listUploads	{
  my ($db, $intAssocID, $target) = @_;
                                                                                                        
  my $statement=qq[
    SELECT DATE_FORMAT(dtUploadDateTime,"%a %d/%m/%Y - %H:%i") AS dtUploadDateTimeFORMAT, strAppName, strAppVer, strAppType, intStatus, intUploadID
    FROM tblUpload
    WHERE intAssocID=$intAssocID
    ORDER BY dtUploadDateTime DESC
  ];
                                                                                                        
  my $query = $db->prepare($statement) or query_error($statement);
  $query->execute() or query_error($statement);
  my %UploadStatus=(
    0 => 'Success',
    1 => 'Fatal Error',
    2 => 'Warnings',
    -1 => 'Fatal Error/Processing/Crashed',
  );
  my $body='';
  my $count=0;
  while(my $dref= $query->fetchrow_hashref()) {
    $dref->{intStatus}=$UploadStatus{$dref->{intStatus}} || $dref->{intStatus};
    my $class='resultrow';
    if($count++%2==1) {
      $class='resultrowshadedwithborder';
    }
    my $errors=qq[<a href="$target?a=ULD&amp;aID=$intAssocID&amp;uID=$dref->{intUploadID}">Errors</a>];
    $errors='&nbsp;' if !$dref->{strDebug};
    foreach my $key (keys %{$dref}) { if(!$dref->{$key})  {$dref->{$key}='&nbsp;';} }
    $body.=qq[
      <tr>
        <td class="$class">$dref->{dtUploadDateTimeFORMAT}</td>
        <td class="$class">$dref->{strAppName}</td>
        <td class="$class">$dref->{strAppVer}</td>
        <td class="$class">$dref->{strAppType}</td>
        <td class="$class">$dref->{intStatus}</td>
        <td class="$class">$errors</td>
      </tr>
    ];
  }
  if(!$body)  {
    $body.=qq[
    <table cellpadding="1" cellspacing="0" border="0" width="90%" align="center">
      <tr>
        <td colspan="3" align="center"><b><br> No Uploads were found<br><br></b></td>
      </tr>
    </table>
    <br>
    ];
  }
  else  {
    $body=qq[
     <table class="coloredtop" cellpadding="1" cellspacing="0" border="0" width="95%" align="center">
      <tr>
        <th>Date/Time</th>
        <th>AppName</th>
        <th>AppVer</th>
        <th>AppType</th>
        <th>Status</th>
        <th>Errors</th>
      </tr>
                                                                                                        
      $body
    </table><br>
    ];
  }
	$body=qq[ <div class="heading6">Upload Log</div> $body ];
                                                                                                        
  return $body;
}

sub uploadDetail	{
  my ($db, $intAssocID, $target, $uploadID) = @_;
                                                                                                        
  my $statement=qq[
    SELECT DATE_FORMAT(dtUploadDateTime,"%a %d/%m/%Y - %H:%i") AS dtUploadDateTime, strAppName, strAppVer, strAppType, intStatus, strDebug
    FROM tblUpload
    WHERE intAssocID=$intAssocID
      AND intUploadID=$uploadID
    ORDER BY dtUploadDateTime DESC
  ];
                                                                                                        
  my $query = $db->prepare($statement) or query_error($statement);
  $query->execute() or query_error($statement);
  my $dref= $query->fetchrow_hashref();
	foreach my $key (keys %{$dref}) { if(!defined $dref->{$key})  {$dref->{$key}='&nbsp;';} }
	$dref->{strDebug}=~s/\n/<br>/g;
	return qq[
		<div class="heading6">Upload Log - Detailed Error</div> 
		<p>$dref->{strDebug}</p>

		<p><b>Error Reference</b>: See above for actual errors.</p>
   <ol style="background-color:#eeeeee;">
			<li><b>Error Importing Data</b>  There was an error in processing your data. This is just a warning. Probably nothing to worry about.</li>
    	<li><b>The competition data is too old</b>  $Defs::sitename will only allow a competition to be uploaded if it has a commencing date in the past 12 months.</li>
    	<li><b>Your Username/Password is incorrect</b></li>
    	<li><b>There seems to be a lot of byes in your competition</b> If this is correct then don't worry.  However this problem can be caused if the venues on your fixture are called different names to those in your venue section.</li>
    	<li><b>The data you sent does not seem to be a text attachment</b>  Please make sure that your email program sends the attachment as text.</li>
			<li><b>Your data does not seem seem to contain all the required fields for proper
data</b>  Try uploading your data again.</li>
    	<li><b>This data doesn't seem to contain results for some rounds</b>  In Sportzware trying checking the 'Batch Results Printed' option in competition administration.  Then try uploading your data again.</li>
    	<li><b>Miscellaneous Error</b></li>
		</ol>
	];
}

sub allowedAdmin	{
	my($db, $bID, $MemberID)=@_;

	my $statement=qq[
		SELECT intAuthID
		FROM tblAuth
		WHERE intMemberID=$MemberID
			AND intTypeID=$Defs::GOVBODY_AUTH_TYPE
			AND intEntityID=$bID
	];
  my $query = $db->prepare($statement) or query_error($statement);
  $query->execute() or query_error($statement);
  my $val= $query->fetchrow_array();
	$val||=0;
	return $val;
}
