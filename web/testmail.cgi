#!/usr/bin/perl -w
use Email; 

use strict; 
my $to = 'jervy.escoto@gmail.com'; 
my $from = 'j.escoto@sportingpulseinternational.com';
my $sbj = 'This is a test email.';
my $hdr = 'test testtwo testthree';
my $hMsg = '<strong>Hello world</strong>';
my $txtMsg = 'test message';
my $log_text = 'another test'; 
my $BCC = 'j.escoto@sportingpulseinternational.com';

sendEmail($to,$from,$sbj,$hdr, $hMsg, $txtMsg, $log_text, $BCC);

print "Check email if successful!";


