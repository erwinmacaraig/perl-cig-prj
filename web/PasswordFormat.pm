package PasswordFormat;
require Exporter;
@ISA =	qw(Exporter);
@EXPORT = qw(isValidPasswordFormat);
@EXPORT_OK = qw(isValidPasswordFormat);

use strict;
use lib "..";
use Defs;
use Utils;


sub isValidPasswordFormat {
	#Returns 1 on success 0 on failure
	my(
		$Data,
		$password,
	) = @_;

    # at least 8 characters long
    #    must contain
    #    at least one lower case letter
    #    at least one upper case letter
    #    at least one non-alphabetic character eg. a number or special character.

    return 0 if !$password;
    return 0 if length($password) < 8;
    return 0 if $password !~/[\p{Number}\p{Punctuation}\p{Symbol}]/;
    return 0 if $password !~/\p{LowercaseLetter}/;
    return 0 if $password !~/\p{UppercaseLetter}/;

    return 1;
}


1;
