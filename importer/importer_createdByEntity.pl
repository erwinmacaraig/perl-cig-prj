#!/usr/bin/perl

use strict;

use lib "..","../web","../web/comp", "../web/user", '../web/RegoForm', "../web/dashboard", "../web/RegoFormBuilder",'../web/PaymentSplit',  "../web/Reg_Common";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use SystemConfig;
use Reg_common;

main();

sub main {
}
