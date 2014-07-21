#!/usr/bin/perl -w
#
# $Header: svn://svn/SWM/trunk/web/index.cgi 10277 2013-12-15 21:15:06Z tcourt $
#

use strict;
use lib ".", "..";
use CGI qw(param unescape escape cookie);
use Defs;
use Lang;
use TTTemplate; 
use Utils;

use DBI;

my $lang= Lang->get_handle() || die "Can't get a language handle!";
# need this one for other languages 

my $title=$lang->txt('APPNAME') || 'SportingPulse Membership'; 

my %Data = (
		lang => $lang,
	);
	
 my $globalnav = runTemplate(
    \%Data,
    {},
    'user/globalnav.templ',
  );

my $page = change_pw_form($lang);
  print "Content-type: text/html\n\n";
  ############# BEGIN HTML ########################
   print qq[<!DOCTYPE html><html lang="en" xmlns="http://www.w3.org/1999/xhtml">
    <head>
     <title>$title</title>
  		<script src = "https://ajax.googleapis.com/ajax/libs/jquery/1.7.1/jquery.min.js"></script>
  		<link rel="stylesheet" type="text/css" href="css/spfont.css">
      <link rel="stylesheet" type="text/css" href="css/style.css">
    <!--[if lt IE 8]>
    <style>
  .membership-login .auth-row input.fields {
  	line-height: 40px;
  }
  </style>
      <![endif]-->
    <!--[if IE]>
      <link rel="stylesheet" type="text/css" href="css/passport_ie.css" />
    <![endif]-->
  
    <!--[if lt IE 9]>
      <link rel="stylesheet" type="text/css" href="css/passport_ie_old.css" />
    <![endif]--> ];
    
    if($ENV{REQUEST_METHOD} eq 'POST'){
       	my $email = param('email'); 
       	my $errstr = '';
      
       	my $dbh = connectDB();       
        my $st = $dbh->prepare("SELECT email FROM tblUser WHERE email = ?");       	
       	if(!$st->execute($email)){
       		print "<br />There is an error. " . DBI::errstr();
       	}
       	if($st->rows > 0){ 
       		print qq[
       			<script type="text/javascript">
       				alert('Please check your email for the password reset link.');
       				window.location="index.cgi";
       			</script>       		
       		];
       		#generate link and mail to user
       	}
       	else { 
       	print qq[
	       	<script type="text/javascript">
	       		alert("Sorry $email address does not exist in our system.");
	       	</script>
	       		
       	];
       	}
       	
   }
    
    print qq[
  </head>
  <body class="membership-login">
  		$globalnav
      <div id="spheader">
  			<div id="spheader-int">
  				<img src="images/sp_membership.png" alt="" title="">
  			</div>
  		</div>
      <div id="pageholder">
        <div id="content">$page</div> <!-- End Content -->
        <div id="footer">
  	<div id="footer-topline"></div>
  		<div id="footer-content">
  				<a href="http://www.sportingpulse.com"><img src="images/SP_powered_rev.png" title="SportingPulse" alt="SportingPulse"></a>
  				<div class="footerline">].$lang->txt('COPYRIGHT').q[</div>
  		</div>
        </div>
      </div> <!-- End Page Holder -->
  </div> <!-- End wrapper -->
  <!-- START Nielsen Online SiteCensus V5.3 -->
  <!-- COPYRIGHT 2009 Nielsen Online -->
  <script type="text/javascript">
          var _rsCI="sportingpulse";
          var _rsCG="sportzmembership";
          var _rsDN="//secure-au.imrworldwide.com/";
          var _rsCL=1;
          var _rsUT="1";
          var _rsC0="";
          var _rsC1="advertising,ads";
  
  </script>
  <noscript>
    <div><img src="//secure-au.imrworldwide.com/cgi-bin/m?ci=sportingpulse&amp;cg=sportzmembership&amp;cc=1&amp;_rsUT=1&amp;_rsC1=advertising,ads" alt=""></div>
  </noscript>
  <!-- END Nielsen Online SiteCensus V5.3 -->
  
  <!-- START Tealium -->
  <script type="text/javascript">
    utag_data = window.utag_data || {};
    utag_data.net_site = 'sportingpulse';
  utag_data.net_section = 'sportzmembership';
  utag_data.ss_sp_ga_account = 'UA-144085-2';
  utag_data.ss_sp_pagename = 'SP Membership Login';
  utag_data.ss_sp_ads = '0';
  utag_data.ss_sp_sportname = 'nosport';
  utag_data.ss_sp_pagetype = 'membership';
  utag_data.ss_sp_ads_string = 'advertising,noads';
  
    
   (function(a,b,c,d){
    a='//tags.tiqcdn.com/utag/newsltd/sportingpulse/prod/utag.js';
    b=document;c='script';d=b.createElement(c);d.src=a;d.type='text/java'+c;d.async=true;
    a=b.getElementsByTagName(c)[0];a.parentNode.insertBefore(d,a);
    })();
  </script>
  <!-- END Tealium -->
    </body>
  </html>
  ];
  
  sub change_pw_form { 
  	my ($lang) = @_;	
  	return qq[
  	<div id="swm-login-wrap">
				<div class="spm-left">
					 <div class="membership-login-wrap passport-sign-box">        
	               <p class="pageHeading"><span class="spp_loggedout"> ] . $lang->txt("Retrieve") . qq[<span class="sp-passport"> ]. $lang->txt("SP Passport") .qq[ </span> ]. $lang->txt("Password") .qq[</p>
	               <span class="spp_loggedout"><p class="instruct"> ]. $lang->txt("Please enter your email address to retrieve your") . qq[ <span class="sp-passport">]. $lang->txt("SP Passport") .qq[</span> ]. $lang->txt("password") .qq[.</p>	 
	               <p>
	<form method = "POST" action = "$ENV{SCRIPT_NAME}">
	                       ]. $lang->txt("EMAIL") .qq[ <input type="text" name="email" style="width:250px;"><br />
	                      
	                        <span class="button generic-button"><input type="submit" value="] . $lang->txt("Send Me The Link") .qq["> </span>
	</p>
	</form>
					</div>
				</div>
				<div class="or-sep-vert"><img src="images/rule-vert.png"></div>
				<div class="spm-right">
				 
				<!-- End spm-right --> 
			  </div>
	                      </div>
	           
		
	</div>
  	
  	];
  
}
