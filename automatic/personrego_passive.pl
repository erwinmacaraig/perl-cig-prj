#!/usr/bin/perl

use strict;
use lib "..", "../web";
use Utils;
use DBI;
use Defs;
use Data::Dumper;

{
    my $db = connectDB();
    my $realmID = 1;

    my $st = qq [
        UPDATE
            tblPersonRegistration_$realmID as PR
    		INNER JOIN tblNationalPeriod as NP ON (
    			NP.intNationalPeriodID = PR.intNationalPeriodID
	    	)
        SET
            PR.strStatus = ?
        WHERE
            (
			    (
				    NP.dtTo > '1900-01-01'
				    AND NP.dtTo < DATE(NOW())
			    )
		    )
            AND PR.strStatus = 'ACTIVE'
    ];

			    #OR
			    #(
				#    PR.dtTo > '1900-01-01'
				#    AND PR.dtTo < DATE(NOW())
                #    AND intOnLoan=0
			    #)
    my $q = $db->prepare($st);
    $q->execute(
        $Defs::PERSONREGO_STATUS_PASSIVE
    ) or query_error($st);
}
1;
