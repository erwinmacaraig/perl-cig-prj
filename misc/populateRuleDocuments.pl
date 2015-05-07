#!/usr/bin/perl

use strict;

use lib "..","../web";

use Defs;
use Utils;
use DBI;
use CGI qw(unescape);
use Data::Dumper;

main();

sub main	{


	my %Data = ();
	my $db = connectDB();
    my @ruleIDs;
    my @itemIDs;


    my $personType = $ARGV[0] || '';

    print "Invalid parameter.\n" if !$personType or !$Defs::personType{$personType};
    return if !$personType or !$Defs::personType{$personType};

    my $sti = qq [
        SELECT distinct intID from tblRegistrationItem where strPersonType = '$personType' and strItemType = 'DOCUMENT'
    ];

    my $q = $db->prepare($sti);
    $q->execute();

    while(my $dref = $q->fetchrow_hashref()){
        push @itemIDs, $dref->{'intID'};
    }

    my $st = qq[
        SELECT intWFRuleID from tblWFRule where strPersonType = '$personType'
    ];

    $q = $db->prepare($st);
    $q->execute();

    while(my $dref = $q->fetchrow_hashref()){
        my $ruleID =  $dref->{'intWFRuleID'};
        foreach my $itemID (@itemIDs) {
            print  "INSERT INTO `tblWFRuleDocuments` (`intWFRuleDocumentID`, `intWFRuleID`, `intDocumentTypeID`, `intAllowApprovalEntityAdd`, `intAllowApprovalEntityVerify`, `intAllowProblemResolutionEntityAdd`, `intAllowProblemResolutionEntityVerify`, `tTimeStamp`) VALUES (0, $ruleID, $itemID, 1,1,1,0,NOW());\n";
        }
    }
}
