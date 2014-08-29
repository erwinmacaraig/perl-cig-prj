package PersonRegistrationDetail;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
    personRegistrationDetail
);

use strict;
use WorkFlow;
#use Log;
use Data::Dumper;

sub personRegistrationDetail   {

    my ($Data, $entityID, $personRegistrationID) = @_;
    ## Needs to use PersonRegistration::getRegistrationDetail
    ## Needs to get list (SQL fine) of tasks and the Entity who is tasked with each row.... see SQL in PendingRegistrations.pm for SQL example
    ## Needs to be in a template/
    ## For top half, use HTMLForm so Status can be changed if $Data->{'clientValues'}{'authLevel'} >= $Defs::LEVEL_NATIONAL or $Data->{'SystemConfig'}{'ChangePRStatus_Level'} >= $Data->{'clientValues'}{'authLevel'} -- so basically we can set a tblSystemConfig value to what level can change per Realm.  "ChangePRStatus_Level" would be the name of the key-value pair in tblSystemConfig
    return "NEED PAGE FOR A REGISTRATION RECORD - This will show at top the full detail of the Registration, then a table at bottom showing the list of tasks";
    ## Used for both Registration History from Person level and Pending Registrations from an Entity.
}
1;
