#!/usr/bin/perl -w

use DBI;
use CGI qw(:cgi escape unescape);

use strict;

use lib ".", "..", "../../..", "../..", "user","../../user";

use Defs;
use Utils;
use PageMain;
use Lang;
use TTTemplate;
use SelfUserObj;
use AddToPage;

main();

sub main {

    my %Data = ();
    my $db   = connectDB();
    $Data{'db'} = $db;
    my $lang = Lang->get_handle() || die "Can't get a language handle!";
    $Data{'lang'} = $lang;
    my $target = 'signup.cgi';
    $Data{'target'} = $target;
    $Data{'cache'}  = new MCache();
    $Data{'AddToPage'} = new AddToPage();

    my $action = param('a') || '';
    my $srp = param('srp') || '';

    my $body = '';
    my $template = 'selfrego/user/signup.templ';
    my $errors = [];
    if($action eq 'SIGNUP') {
        $errors = signup(\%Data);
        if(!scalar(@{$errors}))    {
            $template = 'selfrego/user/signupfinish.templ';
        }
    }
    $body = runTemplate(
        \%Data,
        {
            'Errors' => $errors,
            'srp' => $srp || '',
        },
        $template,
    );

    my $title = $lang->txt('Signup');

    regoPageForm(
              $title,
              $body,
              {},
              '',
              \%Data,
    );
}


sub signup  {
    my($Data) = @_;

    my %fields = (
        firstname => $Data->{'lang'}->txt('First name'),
        familyname => $Data->{'lang'}->txt('Family name'),
        email => $Data->{'lang'}->txt('Email'),
        password => $Data->{'lang'}->txt('Password 1'),
        password2 => $Data->{'lang'}->txt('Password 2'),
    );
    my %inputs = ();
    my $missing_fields = '';
    my @errors = ();
    for my $f (keys %fields) {
        $inputs{$f} = param($f) || '';
        if(!$inputs{$f})    {
            $missing_fields .= '<li>' . $fields{$f} .'</li>';
        }
    }
    if($missing_fields) {
        push @errors, $Data->{'lang'}->txt('You must fill in the following fields:').qq[<ul>$missing_fields</ul>];
    }
    if(scalar(@errors)) { return \@errors }
    if($inputs{'password'} ne $inputs{'password2'})   {
        push @errors, $Data->{'lang'}->txt('Password and Password 2 do not match');
    }
    require Mail::RFC822::Address;
    if(!Mail::RFC822::Address::valid($inputs{'email'}))   {
        push @errors, $Data->{'lang'}->txt('Email address is not valid');
    }
    if(scalar(@errors)) { return \@errors }
    my $user = new SelfUserObj(db => $Data->{'db'});
    $user->load(email => $inputs{'email'});
    if($user->ID()) {
        push @errors, $Data->{'lang'}->txt('Email already in use');
    }
    if(scalar(@errors)) { return \@errors }
    my %userdata = (
        strEmail => $inputs{'email'},
        strFirstName => $inputs{'firstname'},
        strFamilyName => $inputs{'familyname'},
    ); 
    $user->update(\%userdata);
    if($user->ID()) {
        $user->setPassword($inputs{'password'});
    }
    else    {
        push @errors, $Data->{'lang'}->txt('Error creating user account');
        if(scalar(@errors)) { return \@errors }
    }

    return [];
}
