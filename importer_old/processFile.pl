#! /usr/bin/perl
use lib ".";
use strict;
use DBI;
use Getopt::Long;
use warnings;
use ProcessFile;

my $filename = '';  
my $configFile= '';  
GetOptions ('filename=s' => \$filename, 'config=s'=> \$configFile);

main($filename, $configFile);

sub main    {
    my ($filename, $configFile) = @_;
    open FILE, "<" , "data/$filename"  or print "ERR";
    my $db = connectDB();
    my @lines = <FILE>;
    processFile($db, \@lines, $configFile);
    close FILE;
}

sub processFile {

my ($db, $data_ref, $configFile) = @_;

use Data::Dumper;

	my %config=();
	if ($configFile)	{
		open FILE, "data/$configFile" or die $!;
		while (<FILE>)
		{
		   chomp;
		   my ($key, $val) = split /=/;
			next if (!$key);
			if ($key =~/\./)	{
		   		my ($keyPrim, $keySec) = split(/\./, $key);
			   	$config{$keyPrim}{$keySec} = $val;
			}
			else	{
			   $config{$key} = $val;
			}
		}
		close FILE;
	}
	my $realmID = $config{'Realm'} || return;
	my $subRealmID = $config{'SubRealm'} || 0;
    my $sectionHeader='';
    my (@venues, @clubs, @members, @players, @players2, @players3, @referees, @coaches)=();
    my %IDs=();

    my %sectionColumns=();
    my %hasSections=();
    my $sectionLine=0;
    for my $line (@$data_ref) {
        $line=~s ///g;
        $line=~s /"//g;

        if ($line =~ /^###.*_START###/) {
            $sectionLine=1;
            $sectionHeader = $line;
            $sectionHeader =~ s/###//;
            $sectionHeader =~ s/_START###//;
	%sectionColumns=();
            next;
        }
        if ($line =~ /^###.*_END###/) {
            $sectionHeader='';
            next; 
        }
        next if ! $sectionHeader;
        next if ! chomp($line);
        my @sd =split /\t/,$line;
        $sectionHeader= 'Venues' if ($sectionHeader =~ /Venues/);
        $sectionHeader= 'Members' if ($sectionHeader =~ /Members/);
        $sectionHeader= 'Clubs' if ($sectionHeader =~ /Clubs/);
	if ($sectionLine == 1)	{
        	if ($sectionHeader =~ /Players3/)	{
        		$sectionHeader= 'Players3';
		}
		elsif ($sectionHeader =~ /Players2/)	{
        		$sectionHeader= 'Players2';
		}
		elsif ($sectionHeader =~ /Players/)	{
        		$sectionHeader= 'Players';
		}
	}
        $sectionHeader= 'Referees' if ($sectionHeader =~ /Referees/);
        $sectionHeader= 'Coaches' if ($sectionHeader =~ /Coaches/);
	my $tSectionHeader=$sectionHeader;
	$tSectionHeader='Players' if ($sectionHeader=~ /Players/);  ##Handle multi player section
        if ($sectionHeader) {
            $hasSections{$sectionHeader}=1;

            if ($sectionLine == 1)  {
                my $column = 0;
                for my $colName (@sd)  {
                    $column++;
                    $colName =~ s/\s+$//;
                    $sectionColumns{$tSectionHeader}{$column} = $colName;
                }
                $sectionLine=0;
                next;
            }
            my %row=();
            my $column=0;
            for my $i (@sd)  {
                $column++;
                my $fieldname = $sectionColumns{$tSectionHeader}{$column} || '';
		if ($fieldname eq 'ClubName' or $fieldname eq 'AssocName')	{
			$i =~ s/^\s+//;
		}
		$i = '' if ($i eq '-');
                $row{$fieldname} = $i;
            }
            push @venues, \%row if ($sectionHeader eq 'Venues');
            push @clubs, \%row if ($sectionHeader eq 'Clubs');
            push @members, \%row if ($sectionHeader eq 'Members');
            push @players, \%row if ($sectionHeader eq 'Players');
            push @players2, \%row if ($sectionHeader eq 'Players2');
            push @players3, \%row if ($sectionHeader eq 'Players3');
            push @referees, \%row if ($sectionHeader eq 'Referees');
            push @coaches, \%row if ($sectionHeader eq 'Coaches');
        }
    }
	my $assoc_ref = getAssocs($db, $realmID, \%IDs);
	getSeasons($db, $realmID, \%IDs);
	getProducts($db, $realmID, \%IDs);
	print "V\n";
	handle_venues($db, \%config, $assoc_ref, \%IDs, \@venues) if $hasSections{'Venues'};    
	print "C\n";
	handle_clubs($db, \%config, $assoc_ref, \@clubs, \%IDs) if $hasSections{'Clubs'};    
	print "M\n";
	handle_members($db, \%config, $realmID, \@members, \%IDs,0,$config{'Members_MemberStatusOverride'}) if $hasSections{'Members'};    
	$config{'CreatedFrom'}++;
	print "P\n";
	handle_players($db, \%config, $realmID, $subRealmID, $assoc_ref, \@players, \%IDs) if $hasSections{'Players'};    
	$config{'CreatedFrom'}++;
	print "P2\n";
	handle_players($db, \%config, $realmID, $subRealmID, $assoc_ref, \@players2, \%IDs) if $hasSections{'Players2'};    
	$config{'CreatedFrom'}++;
	print "P3\n";
	handle_players($db, \%config, $realmID, $subRealmID, $assoc_ref, \@players3, \%IDs) if $hasSections{'Players3'};    
	$config{'CreatedFrom'}++;
	print "RCT_C\n";
	handle_RefCoachTypes($db, 'Referees', \%config, $realmID, $subRealmID, \@referees, \%IDs) if $hasSections{'Referees'};    
	$config{'CreatedFrom'}++;
	print "RCT_R\n";
	handle_RefCoachTypes($db, 'Coaches', \%config, $realmID, $subRealmID, \@coaches, \%IDs) if $hasSections{'Coaches'};    
	print "\nRUN EXTRA SQL\n\n";
	print "\nRUN CONFIG SQL\n\n";

}

sub connectDB   {
    my $driver = "mysql"; 
    my $database = "regoSWM";
    my $dsn = "DBI:$driver:database=$database";
    my $userid = "root";
    my $password = "devel3757";

    my $dbh = DBI->connect($dsn, $userid, $password ) or die $DBI::errstr;
$dbh->do("SET NAMES 'utf8'");
    return $dbh;
}
