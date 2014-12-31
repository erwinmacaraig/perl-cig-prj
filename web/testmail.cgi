#!/usr/bin/perl -w
use Email; 

use strict; 
my $to = 'w.rodie@sportingpulseinternational.com'; 
my $from = 'w.rodie@sportingpulseinternational.com';
my $sbj = 'This is a test email.';
my $hdr = 'test testtwo testthree';
my $hMsg = '<strong>Hello world</strong>';
my $txtMsg = 'test message';
my $log_text = 'another test'; 
my $BCC = '';

my $ret = sendEmail($to,$from,$sbj,$hdr, $hMsg, $txtMsg, $log_text, $BCC);

print "Check email if successful! $ret\n";


