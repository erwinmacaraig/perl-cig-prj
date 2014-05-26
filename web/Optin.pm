#
# $Header: svn://svn/SWM/trunk/web/Optin.pm 8251 2013-04-08 09:00:53Z rlee $
#

package Optin;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(handleOptins);
@EXPORT_OK = qw(handleOptins);

use strict;

use lib "..";
use CGI qw(param unescape escape);
use Defs;
use Utils;
use HTMLForm;
use GridDisplay;
use Reg_common;
#use Data::Dumper;

sub handleOptins {
    my ($action, $Data, $client, $entityTypeID, $entityID)=@_;
    my $optinID = param('optinID') || 0;
    my $resultHTML  = q{};
    my $title       = q{};
    my $ret         = q{};
    
    if(!$entityTypeID or !$entityID)    {
        $entityTypeID = $Data->{'clientValues'}{'currentLevel'};
        $entityID = getID($Data->{'clientValues'}, $entityTypeID);
    }

    if ($action eq 'OPTIN_L') {
        #AgeGroup Details
        ($resultHTML,$title)=displayOptin($Data,$client,$entityTypeID,$entityID);
    }
    elsif ($action =~ /^OPTIN_/) {
        #List AgeGroups
        my $tempResultHTML = '';
        ($tempResultHTML,$title)=addOptin($action, $Data, $client, $entityTypeID, $entityID,$optinID);
        $resultHTML .= $tempResultHTML;
    }

    return ($resultHTML,$title);
}

sub displayOptin {
    my($Data,$client,$entityTypeID,$entityID)=@_;
    my $body = '';
    my $realm =$Data->{'Realm'};
    my @rowdata;
    my $st = qq[    
                SELECT 
                    intOptinID,
                    strOptinText,
                    intActive,
                    dtCreated,
            intDefault,
            tTimestamp
                FROM
                    tblOptin
                WHERE 
                    intEntityID = ?
                    AND intEntityTypeID =?
            AND intRealmID = ?
                ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute($entityID,$entityTypeID,$realm);
    while (my $i = $q->fetchrow_hashref()) { 
        push @rowdata, {
            id => $i->{'intOptinID'} || 0,
            SelectLink => "$Data->{'target'}?client=$client&amp;a=OPTIN_E&amp;optinID=$i->{intOptinID}",
            optinID => $i->{'intOptinID'},
            optinText => $i->{'strOptinText'},
            dtCreated => $i->{'dtCreated'},
            Active => ($i->{'intActive'} ==1) ?'Yes' : 'No',
            Default => ($i->{'intDefault'} ==1) ?'Yes' : 'No',
            tTimestamp => $i->{'tTimestamp'},
        };
    }
    my @headerdata = (
        {
            type => 'Selector',
            field => 'SelectLink',
        },
        {
            name => 'Description',
            field => 'optinText',
        },
        {
            name => 'Active',
            field => 'Active',
            width => 20,
        },
#       {
#           name => 'Default',
#           field => 'Default',
#           width => 20,
#       },
        {
            name => 'Date Created',
            field => 'dtCreated',
            width => 30,
        },
        {
            name => 'Last Changed ',
            field => 'tTimestamp',
            width => 30,
        },
    );
    if (@rowdata) {
        $body .= showGrid(
            Data => $Data,
            columns => \@headerdata,
            rowdata => \@rowdata,
            gridid => 'grid',
            width => '99%',
            height => 300,
        );
    }
    else    {
        my $add_optin = qq[<span class = "button-small generic-button"><a href="$Data->{'target'}?client=$client&amp;a=OPTIN_A">Add</a></span>];
        $body=$add_optin;
      
    }
    return ($body,$Data->{'lang'}->txt('Opt-Ins Setup'));
}

sub addOptin {
    my ($action, $Data, $client, $entityTypeID, $entityID,$optinID)= @_;
    my $lang = $Data->{'lang'};
    my $option='display';
    my $realm = $Data->{'Realm'};
    $option='edit' if $action eq 'OPTIN_E';
    $option='add' if $action eq 'OPTIN_A';
    $optinID ||=0;
    my $field=loadOptinDetails($Data->{'db'}, $entityTypeID, $entityID, $optinID) || ();
    my %FieldDefinitions=(
        fields=>    {
            strOptinText=> {
                label => "Opt-In Message",
                value => $field->{strOptinText},
                type  => 'textarea',
                rows => 5,
        cols=> 45,
                compulsory => 1,
                sectionname=>'Description',
            },
        intActive => {
            label => "Active",
            value => $field->{intActive},
            type  => 'checkbox',
            sectionname => 'Description',
            default => 1,
            displaylookup => {1 => 'Yes', 0 => 'No'},
        },
#       intDefault => {
#           label => "Default Setting",
#           value => $field->{intDefault},
#           type  => 'checkbox',
#           sectionname => 'Description',
#           default => 1,
#           displaylookup => {1 => 'Yes', 0 => 'No'},
#       },
        },
        order => [qw(strOptinText intActive)],
        sections => [
      ["Description"],
    ],
        options => {
            labelsuffix => ':',
            hideblank => 1,
            target => $Data->{'target'},
            formname => 'n_form',
            submitlabel => "Update",
            introtext => '',
            NoHTML => 1,
            updateSQL => qq[
                UPDATE tblOptin
                    SET --VAL--
                WHERE intOptinID = $optinID
                ],
            addSQL => qq[
                INSERT INTO tblOptin
                    (intEntityID, intEntityTypeID, intRealmID, dtCreated, --FIELDS-- )
                    VALUES ($entityID, $entityTypeID,$realm, SYSDATE(), --VAL-- )
                 ],
            },
            carryfields =>  {
                client => $client,
                a => $action,
                optinID => $optinID,
     
            },
    );
    my $resultHTML='';
    ($resultHTML, undef )=handleHTMLForm(\%FieldDefinitions, undef, $option, '',$Data->{'db'});
    my $title=qq[Opt-Ins Message];
   
    my $text = qq[<p><a href="$Data->{'target'}?client=$client&amp;a=OPTIN_L">Click here</a> to return to list of Opt-Ins</p>];
    $resultHTML = $text.qq[<br><br>].$resultHTML.qq[<br><br>$text];

    return ($resultHTML,$title);

}

sub loadOptinDetails  {
    my ($db, $entityTypeID, $entityID, $optinID) = @_;
    return if ! $db;
    my $st = qq[    
                SELECT 
                    intOptinID,
                    strOptinText,
                    intActive,
            intDefault,
                    dtCreated 
                FROM
                    tblOptin
                WHERE 
                    intOptinID  = ?
                ];
    my $q = $db->prepare($st);
    $q->execute($optinID);
    my $field=$q->fetchrow_hashref();
    $q->finish;
                                                      
    foreach my $key (keys %{$field})  { if(!defined $field->{$key}) {$field->{$key}='';} }
    return $field;
 
}

1;
