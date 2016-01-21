#!/usr/bin/perl -w

use lib '.','..';
use Defs;
use CGI qw(:cgi escape unescape);

use Lang;
use Utils;
use Reg_common;
use MD5;
use Data::Dumper;
use SystemConfig;
use L10n::DateFormat;
use L10n::CurrencyFormat;

use strict;

my $client = param('client') || 0; 
my $amount = param('amount') || 0;
my $db=connectDB();
my %Data = (
    db => $db,
    Realm => 1,
);

my %clientValues = getClient($client);
$Data{'clientValues'} = \%clientValues;
#( $Data{'Realm'}, $Data{'RealmSubType'} ) = getRealm( \%Data );
$Data{'SystemConfig'} = getSystemConfig( \%Data );
my $lang   = Lang->get_handle('', $Data{'SystemConfig'}) || die "Can't get a language handle!";
$Data{'lang'} = $lang;
my $currencyFormat = new L10n::CurrencyFormat(\%Data);

my $amountformatted = $currencyFormat->format($amount);
print "Content-Type: text/html \n\n";
print $amountformatted;



