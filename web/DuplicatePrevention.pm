package DuplicatePrevention;

require Exporter;

@ISA       = qw(Exporter);
@EXPORT    = qw(duplicate_prevention);
@EXPORT_OK = qw(duplicate_prevention);

use strict;
use Utils;
use TTTemplate;

sub duplicate_prevention {
	my ($Data, $new_member, $registering_as, $current_member_id) = @_; 

    return '' if '12' !~ /$Data->{'SystemConfig'}{'DuplicatePrevention'}/;

    #$new_member contains the new member's details to be used for dup checking.

    $registering_as ||= [];
    return '' if !@$registering_as;

    my @new_member_types = ();

    #$registering_as contains the types that the member is registering as or being added as/changed to.
    #Because it can come from different sources, a bit of manipulation is done to each of the types.
    foreach my $member_type (@$registering_as) {
        $member_type =  lc($member_type);
        $member_type =~ s/^yn//;
        $member_type =~ s/^d_int//;
        $member_type =~ s/^matchofficial/umpire/;
        $member_type =  ucfirst($member_type);

        my $config_name   = 'DuplicatePrevention_'.$member_type;
        my $do_prevention = (exists $Data->{'SystemConfig'}{$config_name}) ? $Data->{'SystemConfig'}->{$config_name} : 1;

        push @new_member_types, $member_type if $do_prevention;
    }

    return '' if !@new_member_types;

    # at this point @new_member_types will contain the types to be checked eg (Player Coach Umpire...Volunteer).

    my @sub_realms = ($Data->{'RealmSubType'}); #at a minumum, check the current sub realm.

    if ($Data->{'SystemConfig'}{'DuplicatePrevention_OtherSubRealms'}) {
        my $other_sub_realms = $Data->{'SystemConfig'}{'DuplicatePrevention_OtherSubRealms'};
        $other_sub_realms    =~ s/ //g; #remove all spaces.

        my $delimiter = ($other_sub_realms =~ /\|/) ? '\|' : ','; #either a pipe or a comma could be used as a delimiter.
        push @sub_realms, split($delimiter, $other_sub_realms);
    }

    my $by_member_type   = ($Data->{'SystemConfig'}{'DuplicatePrevention'} == 1) ? 1 : 0; #1 = by member type, 2 (really anything other than 0 or 1) = across all types.
    my $across_all_types = !$by_member_type * 1;

    my @member_types = ($by_member_type)
        ? @new_member_types
        : qw(Player Coach Umpire Official Misc Volunteer);

    my $result_html = '';

    #only DuplicatePrevention_IgnorePending taken into account; AllowPendingRegistration (also on SystemConfig) is deliberately ignored.
    my $matched_members = get_matched_members(
        $Data->{'db'}, 
        $new_member, 
        \@member_types, 
        $Data->{'Realm'}, 
        \@sub_realms, $Data->{'SystemConfig'}{'DuplicatePrevention_IgnorePending'},
        $current_member_id
    );

    if (@$matched_members) {
        my %template_data = (matched=>$matched_members);  #no need to set format arg. 
        my $template_file = 'primaryclub/matchedMembers.templ'; #makes minimal use of the template.
        $result_html = runTemplate($Data, \%template_data, $template_file);
    }

    return $result_html;
}

#check to see if the player has a member season record for any of the types within the subrealms.
sub get_matched_members {
    my ($dbh, $new_member, $member_types, $realm_id, $sub_realms, $ignore_pending, $current_member_id) = @_;

    $ignore_pending    ||= 0;
    $current_member_id ||= 0; #should only be set if the member is currently in pending and being approved.

    my $source = "tblMember_Seasons_$realm_id AS MS";

    $source .= ' INNER JOIN tblMember  AS M USING (intMemberID)';
    $source .= ' INNER JOIN tblAssoc   AS A USING (intAssocID)';
    $source .= ' INNER JOIN tblSeasons AS S USING (intSeasonID)';

    my @fields = (
        'DISTINCT M.strFirstname', 
        'M.strSurname', 
        'M.intGender',
        'M.strEmail', 
        'M.strPhoneMobile',
        'M.dtDOB', 
        'M.strNationalNum',
        'A.strName AS AssocName',
        'S.strSeasonName AS SeasonName',
    );
     
     my %tempHash = ();
 
     foreach my $member_type (@$member_types) {
         $tempHash{"MS.int$member_type".'Status'} = 1;
     }

    #intPlayerPending will be 0 if not pending, 1 if pending, -1 if rejected.
    #if ignorePending, get only rows where it has a value of 0; otherwise all values.
    #intMSRecStatus will be 1 if not pending, 0 if pending.
    #if ignorePending, get only rows where it has a value of 1; otherwise all values.
    my @player_pending = ($ignore_pending) ? (0) : (-1, 0, 1);
    my @ms_rec_status  = ($ignore_pending) ? (1) : (0, 1);

    my @where = (
        -and => [
            {
                'A.intRealmID'        => $realm_id,
                'A.intAssocTypeID'    => {-in => [@{$sub_realms}]},
                'M.strFirstname'      => $new_member->{'firstname'},
                'M.strSurname'        => $new_member->{'surname'},
                'M.dtDOB'             => $new_member->{'dob'},
                'M.intMemberID'       => {'!=', $current_member_id},
                'M.intStatus'         => {-in => [1, 2]}, #include members marked as possible dupes.
                'MS.intMSRecStatus'   => {-in => [@ms_rec_status]},
                'MS.intPlayerPending' => {-in => [@player_pending]},
            },
            -nest => [
                -or => [ %tempHash]
            ]
        ]
    );

    my @order = ('AssocName', 'SeasonName');

    my ($sql, @bind_values) = getSelectSQL($source, \@fields, \@where, \@order);

    my $q = $dbh->prepare($sql);

    $q->execute(@bind_values);

    my $matched_members = $q->fetchall_arrayref();

    return $matched_members;
}

1;
