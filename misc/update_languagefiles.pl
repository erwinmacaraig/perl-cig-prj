#!/usr/bin/perl

use lib "..","../web";
#use lib "/Users/Administrator/src/FIFASPOnline","/Users/Administrator/src/FIFASPOnline/web";
use strict;
use File::Find;
use Defs;
use FieldLabels;
use Data::Dumper;

my %LangKeys = ();
my @files = ();

main();

sub main	{


    #get list of files - from web directory and templates dir
    finddepth(\&wanted,(
        $Defs::fs_base.'/templates',
        $Defs::fs_base.'/web',
    ));
    my $existingKeys = {};
    if(scalar(@ARGV))    {
        $existingKeys = getExistingKeys($ARGV[0]);
    }

    #process through list of files
    for my $filename (@files)	{
            chomp $filename;
            open FILEIN, "<$filename";
            my @lines = <FILEIN>;
            my $filecontents = join('',@lines);
            my @matches =  $filecontents =~ /\btxt\(['"]([^\)]+)['"]\)/gs;
            if(scalar(@matches))    {
                foreach my $i (@matches)    {
                    if(!exists $existingKeys->{$i}) {
                        $LangKeys{$i} = 1;
                    }
                }
            }
    }

    #process Field Labels
    my $fieldlabels_p = getFieldLabels({},$Defs::LEVEL_PERSON,1);
    for my $k (keys $fieldlabels_p) {
        $LangKeys{$k} = 1;
    }
    my $fieldlabels_c = getFieldLabels({},$Defs::LEVEL_CLUB,1);
    for my $k (keys $fieldlabels_c) {
        $LangKeys{$k} = 1;
    }


    print "#Updated ".scalar(localtime)."\n";
    foreach my $key (sort keys %LangKeys)   {
        $key =~ s/"/\\"/g;
        print qq[msgid "$key"\n].qq[msgstr ""\n\n];
    }
}

sub wanted {
    if($File::Find::name =~/\.(pm|cgi|html|templ)$/)  {
        push @files, $File::Find::name;
    }
  return;
}

sub getExistingKeys {
    my ($filename) = @_;
    open FILEIN, "<$filename" or die("Cannot open file $filename\nUse absolute path\n");
    my @lines = <FILEIN>;
    my $filecontents = join('',@lines);
    my @matches =  $filecontents =~ /msgid\s+"(.*?)"/gs;
    my %keys = ();
    if(scalar(@matches))    {
        foreach my $i (@matches)   {
            $keys{$i} = 1;
        }
    }
    return \%keys;
}

             
