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
            for my $line (@lines)   {
                $lineNum++;
            #my $filecontents = join('',@lines);
                #my @matches =  $filecontents =~ /\btxt\(['"]([^\)]+)['"]\)/gs;
                my @matches =  $line=~ /\btxt\(['"]([^\)]+)['"]\)/gs;
                if(scalar(@matches))    {
                    foreach my $i (@matches)    {
                        push @{$LangKeys{$i}}, "#: $relativefile Line:$lineNum";
                    }
                }
            }
    }

    #process Field Labels
    my $fieldlabels_p = getFieldLabels({},$Defs::LEVEL_PERSON,1);
    for my $k (keys $fieldlabels_p) {
        $LangKeys{$fieldlabels_p->{$k}} = ['# :Person FieldLabels'];
    }
    my $fieldlabels_c = getFieldLabels({},$Defs::LEVEL_CLUB,1);
    for my $k (keys $fieldlabels_c) {
        $LangKeys{$fieldlabels_c->{$k}} = ['#: Club Field Labels'];
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


