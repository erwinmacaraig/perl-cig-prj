#!/usr/bin/perl -w

#
# $Header: svn://svn/SWM/trunk/web/schools.cgi 10307 2013-12-16 23:23:18Z tcourt $
#

use strict;
use lib ".", "..";
use DBI;
use CGI qw(:standard escape);
use Utils;
use DeQuote;

main();

sub main	{

	my $fn = param('fn') ;
	my $anchorid = param('anchorid') ;
	my $anchorname = param('anchorname') ;
	my $anchorsuburb = param('anchorsuburb');
	my $anchorOtherSchoolName = '';
	
	my $searchtype = param('searchtype') || 0;
	my $searchschool = param('searchschool') || '';
	my $searchstate = param('searchstate') || '';
	my $schoolRealm= param('srealm') || 0;
	 $searchschool =~ s/\.//g;

				### THIS WORKS opener.document[formname][anchor].value = this.document.popupf.ffield.value;
	my $body = '';

	my $db=connectDB();
	if ($searchschool) {
		#Perform School Search
			my ($safeSearchSchool, $safeSearchState)=($searchschool, $searchstate); 
			$safeSearchSchool = "%$safeSearchSchool%";
			deQuote($db, \$safeSearchState);
			deQuote($db, \$safeSearchSchool);
			$schoolRealm=~s/[^\d]//g; #Remove everything not a digit
			my $state=$safeSearchState ne "''" ? " AND strState=$safeSearchState" : '';

			my $statement = qq[   
				SELECT intSchoolID, strName, strState, strSuburb, strPostalCode
				FROM tblSchool
				WHERE strName LIKE $safeSearchSchool
					AND intSchoolRealm = $schoolRealm
					$state
				ORDER BY strName 
				LIMIT $Defs::SCHOOL_SEARCH_LIMIT
			];
			my $query = $db->prepare($statement) or query_error($statement);
			$query->execute or query_error($statement);

			my $rowCount=0;		

			while (my $school = $query->fetchrow_hashref())   {
				$rowCount++;
				$school->{'strSuburb'}||='';
				$school->{'strName'}||='';
				my $escname=$school->{'strName'};
				$escname=~s/'/\\'/g;
				my $escsuburb=$school->{'strSuburb'};
				$escsuburb=~s/'/\\'/g;
				my $cookieValue = qq[$escname|$school->{intSchoolID}|$escsuburb];

				my $class=($rowCount % 2) ? 'class="rowshade"' : '';

				$body .= qq[
					<tr>
						<td $class>$school->{strName}</td>
						<td $class>$school->{strSuburb}</td> 
						<td $class align='right'>$school->{strPostalCode}</td>
						<td $class><input type="button" value="Select" name="select"  
					onclick="SetCookie('$Defs::SCHOOL_COOKIE','$cookieValue',null,'/','$Defs::cookie_domain');return setvalue('$fn', '$anchorname', '$anchorid', '$anchorsuburb', '$escname', '$school->{intSchoolID}', '$escsuburb');"></td>
					</tr>
				];
			}
			if (!$rowCount) {
				$body.='No schools found matching these criteria. Try typing only part of the school\'s name if you are unsure of the spelling.';
			}
			else {
				my $limitMsg = ($rowCount==$Defs::SCHOOL_SEARCH_LIMIT) ? "<p class=warningmsg'>These results have been restricted to $Defs::SCHOOL_SEARCH_LIMIT. If you can't find your school in the list, please enter more specific criteria.</p>" : '';	
				$body=qq[
					$limitMsg
					<table class="listTable">
						<tr>
							<th>School Name</th><th>Suburb</th><th style="text-align:right;">Post Code</th><th>&nbsp;</th>
						</tr>
						$body
					</table>
				];
			}
			my $cookieValue = qq[--school not found--|1|];
			$body.=qq[<br>Can't find your school? <input type="button" name="unknownschool" value="Click here" onclick="SetCookie('$Defs::SCHOOL_COOKIE','$cookieValue',null,'/','$Defs::cookie_domain');return setvalue('$fn','$anchorname','$anchorid','$anchorsuburb','--school not found--','1','');">];
	}
 
 	my $stateOptions='';	
	#Get state options
	{
		my $st=qq[SELECT DISTINCT strState FROM tblSchool WHERE intSchoolRealm = $schoolRealm ORDER BY strState ASC];
			my $q= $db->prepare($st);
			$q->execute;
			while(my ($state)=$q->fetchrow_array())	{
				$state||='';
				my $selected = ($searchstate eq $state) ? ' selected' : '';
				$stateOptions.=qq[<option value='$state'$selected>$state</option>];
			}
	}
	disconnectDB($db);

	 print qq^Content-type: text/html\n\n
		<html>
		<link rel="stylesheet" type="text/css" href="css/style.css">
		<script language="JavaScript1.2" type="text/javascript" src="js/jscookie.js"></script>
		<script language="JavaScript" type="text/javascript">
			function setvalue(formname, anchorname, anchorid, anchorsuburb, schooltext, schoolid, schoolsuburb)	{
				parent.document[formname][anchorid].value = schoolid;
				parent.document[formname][anchorname].value = schooltext;
				parent.document[formname][anchorsuburb].value = schoolsuburb;
				closeSchools();
				return true;
			}
			function closeSchools()	{
				parent.document.getElementById("schoolframe").style.display="none";
				parent.document.getElementById("schoolsearchbtn").style.display="block";
				return true;
			}
		</script>
		<body>
			<form name="schoolsearch">
				<input type="hidden" name="fn" value="$fn">
				<input type="hidden" name="anchorid" value="$anchorid">
				<input type="hidden" name="anchorname" value="$anchorname">
				<input type="hidden" name="anchorsuburb" value="$anchorsuburb">
				
				<input type="hidden" name="srealm" value="$schoolRealm">
				<input type="hidden" name="searchtype" value="1">
				<input type="button" value="Cancel"  style='text-align:right; float:right; cursor:pointer; margin:4px; padding:0px' onclick="closeSchools(); return true;">
				<div class="label" style="text-align:left;">Enter Your School Name:</div><input type="text" name="searchschool" value="$searchschool" size="20" maxlength="50" onblur="unhighlightField(this);" onfocus="highlightField(this);">
				<select name="searchstate">
					$stateOptions	
				</select>
				<input type="submit" value="Find"> 
			</form>
			<form name="schoollookup">
			<input type="hidden" name="fn" value="$fn">
			<input type="hidden" name="anchorid" value="$anchorid">
			<input type="hidden" name="anchorname" value="$anchorname">
			<input type="hidden" name="anchorsuburb" value="$anchorsuburb">
			$body		
			</form>
			</body>
			</html>
		^; 
}



