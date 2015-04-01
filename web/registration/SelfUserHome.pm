package SelfUserHome;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(
    showHome 
);
@EXPORT_OK = qw(
	showHome
);

use strict;
use lib '.','..','../..',"../../..","user";
use Defs;
use Lang;
use TTTemplate;

sub showHome {
	my (
		$Data,
        $user,
        $srp
	) = @_;

    my (
        $previousRegos ,
        $people,
        $found,
    ) = getPreviousRegos($Data, $user->id());

    my $resultHTML = runTemplate(
        $Data,
        {
            Name => $user->fullname(),
            PreviousRegistrations => $previousRegos,
            People => $people,
            Found => $found,
            srp => $srp,
        },
        'selfrego/home.templ',
    );    

    return $resultHTML;
}

sub getPreviousRegos {
    my (
		$Data,
        $userID,
    ) = @_;

    my $st = qq[
        SELECT
            A.intMinor,
            PR.*,
            E.strLocalName AS EntityName,
            P.strLocalFirstname,
            P.strLocalSurname,
            P.dtDOB,
            P.intGender
        FROM
            tblSelfUserAuth AS A
            INNER JOIN tblPersonRegistration_$Data->{'Realm'} AS PR
                ON (
                    A.intEntityTypeID = $Defs::LEVEL_PERSON
                    AND A.intEntityID = PR.intPersonID
                )
            INNER JOIN tblEntity AS E
                ON PR.intEntityID = E.intEntityID
            INNER JOIN tblPerson AS P
                ON PR.intPersonID = P.intPersonID
        WHERE
            A.intSelfUserID = ?
        ORDER BY 
            intMinor ASC,
            dtApproved DESC, 
            dtAdded DESC
    ];
    my $q = $Data->{'db'}->prepare($st);
    $q->execute(
        $userID,
    );
    my %regos = ();
    my %found = ();
    my @people = ();
    while(my $dref = $q->fetchrow_hashref())    {
        my $pID = $dref->{'intPersonID'} || next;
        if(!exists $regos{$pID})    {
            push @people, {
                strLocalFirstname => $dref->{'strLocalFirstname'} || '',
                strLocalSurname => $dref->{'strLocalSurname'} || '',
                intGender => $dref->{'intGender'} || '',
                dtDOB => $dref->{'dtDOB'} || '',
                intMinor => $dref->{'intMinor'},
                intPersonID => $pID,
            };
        }
        my $type = $dref->{'intMinor'} ? 'minor' : 'adult';
        $found{$type} = 1;
        $dref->{'strPersonTypeName'} = $Defs::personType{$dref->{'strPersonType'}} || '';
        $dref->{'strPersonLevelName'} = $Defs::personLevel{$dref->{'strPersonLevel'}} || '';

        push @{$regos{$pID}}, $dref;
    }
    
    return (
        \%regos,
        \@people,
        \%found,
    );
}
1;
