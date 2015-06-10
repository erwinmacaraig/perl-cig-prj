#!/usr/bin/perl  -w 

use strict;

use lib '..','../..','../NationalCode';

use CGI qw(param);
use Defs;
use Utils;
use NationalCode;
use SystemConfig;

main();

sub main {
    my $fieldname= safe_param('f', 'word') || 0;
    my $nationalCode = safe_param($fieldname, 'word') || 0;
    my $gender = safe_param('intGender', 'number') || 0;
    my $dob_y = param('dtDOB_year') || '';
    my $dob_m = param('dtDOB_mon') || '';
    my $dob_d = param('dtDOB_day') || '';
    my $dob = param('dtDOB') || '0000-00-00';
    if($dob)    {
        $dob = sprintf("%d-%02d-%02d",$dob_y,$dob_m,$dob_d);
    }
    my $contentType = safe_param('contentType', 'word') || 'application/json';
    if($dob =~/\//)     {
        $dob =~ s/(\d+)\/(\d+)\/(\d+)/$3-$2-$1/;
    }

    my $db = connectDB();
    my %Data = (
        db => $db,
        Realm => 1,
    );

    my $systemConfig = getSystemConfig( \%Data );

#$country = 'fi';
#$nationalCode = '010101-123N';
#$validationType = 1;
#$dob = '1901-01-01';
#$gender = 1;

    my $output = "Content-Type: $contentType\n\n";
    my $response = undef;
    if($nationalCode)   {
        my $validator  = getNationalCodeValidator(
            $systemConfig,
            $nationalCode, 
            {
                gender => $gender,
                dob => $dob,
            },
        );
        $response = $validator->validate() if $validator;
    }
    $output .= $response ? 'true' : 'false';

    print $output;
}

