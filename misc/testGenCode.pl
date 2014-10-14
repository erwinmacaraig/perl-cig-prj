#!/usr/bin/perl

use strict;
use lib "../","../web";
use Utils;
use GenCode;

my $db = connectDB();

my $code = new GenCode($db, 'PERSON',1,0,0);
print $code->getNumber({
dob => '1945-04-05',
gender => 1,
})."\n";

my $code = new GenCode($db, 'ENTITY',1,0,0);
print $code->getNumber({
entityType => 'school',
})."\n";
