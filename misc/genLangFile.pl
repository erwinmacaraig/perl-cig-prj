#!/usr/bin/perl

use lib "..","../web";
use lib "/home/warren/src/spil/FIFASPOnline/", "/home/warren/src/spil/FIFASPOnline/web";
#use lib "/Users/Administrator/src/FIFASPOnline","/Users/Administrator/src/FIFASPOnline/web";
use strict;
use File::Path  qw(make_path);
use Defs;
use FieldLabels;
use Data::Dumper;

my %LangKeys = ();
my @files = ();

main();

sub main	{
    my %excludeFiles = (
        'web/List.pm' => 1,
        'web/ListMembers.pm' => 1,
        'web/Clearances/Clearances.pm' => 1,
        'web/Clearances/ClearancesList.pm' => 1,
        'web/Clearances/ClearanceSettings.pm' => 1,
        'web/Seasons.pm' => 1,
        'web/AssocOptions.pm' => 1,
        'web/AssocServices.pm' => 1,
        'web/EntitySettings.pm' => 1,
        'web/AgeGroups.pm' => 1,
        'web/Search.pm' => 1,
        'web/ServicesContacts.pm' => 1,
        'web/AuthMaintenance.pm' => 1,
        'web/RegoFormBuilder/RegoFormOptions.pm' => 1,
        'web/RegoFormBuilder/RegoForm.pm' => 1,
        'web/RegoForm/RegoFormBaseObj.pm' => 1,
        'web/RegoForm/RegoForm_Member.pm' => 1,
        'web/dashboard/DashboardConfig.pm' => 1,
        'web/ProductPhoto.pm' => 1,
        'web/Photo.pm' => 1,
        'web/Welcome.pm' => 1,
        'templates/user/login_orgs.templ' => 1,
        'templates/user/linkmember.templ' => 1,
        'templates/team/invite_teammates.templ' => 1,
    );
    my @params = @ARGV;
    my $outputfilepath = shift @params;
    my @files = @params;
    my ($outputdir, $outputfile) = $outputfilepath =~ /(.*)\/([^\/]*)/;
    make_path($outputdir);
    open OUTPUT , ">$outputdir/$outputfile";
    open OUTPUT2 , ">$outputdir/$outputfile.out";

    #process through list of files
    for my $filename (@files)	{
            chomp $filename;
            open FILEIN, "<$filename";
            my @lines = <FILEIN>;
            my $lineNum = 0;
            my $relativefile = substr $filename, (length($Defs::fs_base)+1);
            next if $excludeFiles{$relativefile};
            for my $line (@lines)   {
                $lineNum++;
            #my $filecontents = join('',@lines);
                #my @matches =  $filecontents =~ /\btxt\(['"]([^\)]+)['"]\)/gs;
                #my @matches =  $line=~ /\btxt\(['"]([^'"]+)['"]/gs;
                my @matchesRaw =  $line=~ /\btxt\((["'])((?:\\?+.)*?)\1/gs;
                my @matches =();
                for my $m (@matchesRaw) {
                    next if $m eq "'";
                    next if $m eq '"';
                    push @matches, $m;
                }

                if(scalar(@matches))    {
                    foreach my $i (@matches)    {
                        next if $i =~ /^\s+$/;
                        push @{$LangKeys{$i}}, "#:$relativefile Line:$lineNum";
                    }
                }
            }
    }

    #process Field Labels
    my $fieldlabels_p = getFieldLabels({}, $Defs::LEVEL_PERSON,1);
    for my $k (keys $fieldlabels_p) {
        push @{$LangKeys{$fieldlabels_p->{$k}}}, '#:Person FieldLabels';
    }
    my $fieldlabels_c = getFieldLabels({},$Defs::LEVEL_CLUB,1);
    for my $k (keys $fieldlabels_c) {
        push @{$LangKeys{$fieldlabels_c->{$k}}},  '#:Club Field Labels';
    }
    no strict 'refs'; 
    for my $hash (qw(
        wfTaskType
        wfTaskStatus
        wfTaskAction
        sportType
        entitySportType
        personType
        personLevel
        entityStatus
        registrationNature
        personStatus
        personRegoStatus
        entityType
        genderInfo
        PersonGenderInfo
        genderEventInfo
        genderEntityInfo
        DataAccessNames
        tfInfo
        memberTypeName
        entityInfo
        NationalityType
        ProdTransactionStatus
        TransactionStatus
        TransLogStatus
        paymentTypes
        manualPaymentTypes
        DisplayEntityLevelNames
        LevelNames
        ageLevel
        ClubType
        VenueTypes
        memberNameFormat
        documentFor
        personTransferType
        personRequest
        personRequestResponse
        personRequestStatus
        person_certification_status
        fieldGroundNatureType
    ))  {
        my $hashname = 'Defs::'.$hash;
        for my $k (keys %{$hashname})   {   
            push @{$LangKeys{$hashname->{$k}}}, '#:Defs::'.$hash;
        }
    }

    foreach my $key (sort keys %LangKeys)   {
        $key =~ s/"/\\"/g;
        $key =~s/\\'/'/g;
        my $comments = '';
        if($LangKeys{$key} and ref $LangKeys{$key} eq 'ARRAY')  {
            $comments = join("\n",@{$LangKeys{$key}});
        }
        print OUTPUT qq[$comments\nmsgid "$key"\n].qq[msgstr ""\n\n];
        print OUTPUT2 qq[$comments\nmsgid "$key"\n].qq[msgstr ""\n\n];
    }
}


