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
use NationalReportingPeriod;
use TTTemplate;
use GridDisplay;
use Reg_common;
use Utils;
sub showHome {
	my (
		$Data,
        $user,
        $srp
	) = @_;

    my (
        $previousRegos,
        $people,
        $found,
    ) = getPreviousRegos($Data, $user->id());

	#		
	my $transactions = getSelfRegoTransactionHistory($Data, $previousRegos);
	#
	my $documents = getUploadedSelfRegoDocuments($Data,$people);
	my $registrationHist = getSelfRegoHistoryRegistrations($Data, $previousRegos);
    my $resultHTML = runTemplate(
        $Data,
        {
            Name => $user->fullname(),
            PreviousRegistrations => $previousRegos,
            People => $people,
            Found => $found,
            srp => $srp,	
			Documents => $documents,	
			History => 	$registrationHist,
			Transactions => $transactions,
        },
        'selfrego/home.templ',
    );    

    return $resultHTML;
}
sub getSelfRegoTransactionHistory{
	my ($Data, $previousRegos) = @_; 
	my $txns = '';
	my %transactions = ();
	my $sth;
	foreach my $personIdKeyArr (keys %{$previousRegos}){ 
		foreach my $regoDetail (@{$previousRegos->{$personIdKeyArr}}){
			my $query = qq[ SELECT
            T.intQty,
            T.curAmount,
            P.strName as ProductName,
            P.strDisplayName as ProductDisplayName,
            P.strProductType as ProductType,
            T.intStatus,
            T.intTransactionID,
            TL.intPaymentType,
			I.strInvoiceNumber
        FROM
            tblTransactions as T
            INNER JOIN tblProducts as P ON (P.intProductID=T.intProductID)
			INNER JOIN tblInvoice as I ON (T.intInvoiceID = I.intInvoiceID)
            LEFT JOIN tblTransLog as TL ON (TL.intLogID=T.intTransLogID)
        WHERE
            T.intID = ?
            AND T.intTableType = $Defs::LEVEL_PERSON
            AND T.intPersonRegistrationID = ?];			
			$sth = $Data->{'db'}->prepare($query);
			$sth->execute($personIdKeyArr, $regoDetail->{'intPersonRegistrationID'});
			while(my $dref = $sth->fetchrow_hashref()){
				push @{$transactions{'txn'}},{
					TransactionNumber => $dref->{'intTransactionID'},
					InvoiceNumber => $dref->{'strInvoiceNumber'},
           			PaymentLogID=> $dref->{'intTransLogID'},
                    ProductName=> $dref->{'ProductName'},
                    ProductType=> $dref->{'ProductType'},
                    Amount=> $dref->{'curAmount'},
                    TXNStatus => $Defs::TransactionStatus{$dref->{'intStatus'}},
                    PaymentType=> $Defs::paymentTypes{$dref->{'intPaymentType'}} || '-',
                    Qty=> $dref->{'intQty'},				
				}
			}

		}
	}
	$transactions{'CurrencySymbol'} = $Data->{'SystemConfig'}{'DollarSymbol'} || "\$";
	$txns = runTemplate(
				$Data,
				\%transactions,
				'selfrego/selfregotxnbody.templ'			
			);
	return $txns;
	
}

sub getSelfRegoHistoryRegistrations{
	my ($Data, $previousRegos) = @_;
	my %history = ();
	my $registrationhistory = '';
	foreach my $personIdKeyArr (keys %{$previousRegos}){ 
		foreach my $regoDetail (@{$previousRegos->{$personIdKeyArr}}){
			push @{$history{'regohist'}}, {
				NationalPeriodName => $regoDetail->{'strNationalPeriodName'},
				RegistrationType => $Defs::registrationNature{$regoDetail->{'strRegistrationNature'}},
				Status => $Defs::entityStatus{$regoDetail->{'strStatus'}},
				Sport => $Defs::sportType{$regoDetail->{'strSport'}},
				PersonType => $Defs::personType{$regoDetail->{'strPersonType'}},
				PersonEntityRole => $regoDetail->{'strPersonEntityRole'},
				PersonLevel => $Defs::personLevel{$regoDetail->{'strPersonLevel'}},
				AgeLevel => $Defs::ageLevel{$regoDetail->{'strAgeLevel'}},
				NPdtFrom => $regoDetail->{'NPdtFrom'},
				NPdtTo => $regoDetail->{'NPdtTo'},
				Certifications => $regoDetail->{'regCertifications'},
			};
		}
	}	
	$registrationhistory = runTemplate(
							$Data,
							\%history,
							'selfrego/selfregohistorybody.templ'			
							);
	return $registrationhistory;
}
sub getUploadedSelfRegoDocuments {
	my($Data, $people) = @_;
	my %TemplateData = ();
	my $docTable = '';
	my $lang = $Data->{'lang'};
	my $query = qq[SELECT intFileID, strDocumentName, strApprovalStatus FROM tblUploadedFiles INNER JOIN tblDocuments ON      tblUploadedFiles.intFileID = tblDocuments.intUploadFileID INNER JOIN tblDocumentType ON tblDocumentType.intDocumentTypeID = tblDocuments.intDocumentTypeID INNER JOIN tblPersonRegistration_$Data->{'Realm'} as pr ON pr.intPersonRegistrationID = tblDocuments.intPersonRegistrationID WHERE tblDocuments.intPersonID = ? ORDER BY tblDocuments.intPersonRegistrationID];
	my $q = $Data->{'db'}->prepare($query);
	foreach my $person (@{$people}){		
		$q->execute($person->{'intPersonID'});
		while(my $dref = $q->fetchrow_hashref()){
			next if(!$dref->{'intFileID'});	
			push @{$TemplateData{'alldocs'}},{
				strDocumentName => $lang->txt($dref->{'strDocumentName'}),									
			};		
		}
		$docTable .= runTemplate(
			$Data,
			\%TemplateData,
			'selfrego/selfregodocsbody.templ',
		);		
	}
	return $docTable;
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
            P.intGender,
            P.strStatus as PersonStatus,
            NP.strNationalPeriodName,
            NP.dtTo as NPdtTo
        FROM
            tblSelfUserAuth AS A
            INNER JOIN tblPersonRegistration_$Data->{'Realm'} AS PR
                ON (
                    A.intEntityTypeID = $Defs::LEVEL_PERSON
                    AND A.intEntityID = PR.intPersonID
                )
            INNER JOIN tblNationalPeriod as NP ON (
                NP.intNationalPeriodID = PR.intNationalPeriodID
            )
            INNER JOIN tblEntity AS E
                ON PR.intEntityID = E.intEntityID
            INNER JOIN tblPerson AS P
                ON PR.intPersonID = P.intPersonID
        WHERE
            A.intSelfUserID = ?
            AND PR.strStatus IN ('ACTIVE', 'PASSIVE', 'PENDING')
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
    my $allowTransferShown=0;
    while(my $dref = $q->fetchrow_hashref())    {
        my $pID = $dref->{'intPersonID'} || next;
        if(!exists $regos{$pID})    {
            $allowTransferShown=0;
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
        
        $dref->{'renewlink'} = '';
        $dref->{'allowTransfer'} =0;
        $dref->{'PRStatus'} = $Defs::personRegoStatus{$dref->{'strStatus'}} || '';
        if (
            ! $allowTransferShown
            and $Data->{'SystemConfig'}{'selfRego_' . $dref->{'strPersonLevel'} . '_allowTransfer'} 
            and ($dref->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE or $dref->{'strStatus'} eq $Defs::PERSONREGO_STATUS_PASSIVE)
            and $dref->{'strPersonType'} eq $Defs::PERSON_TYPE_PLAYER)    {
            $dref->{'allowTransfer'} =1;
            $allowTransferShown=1;
        }
        if ($Data->{'SystemConfig'}{'selfRego_RENEW_'.$dref->{'strPersonType'}} 
            and ($dref->{'strStatus'} eq $Defs::PERSONREGO_STATUS_ACTIVE or $dref->{'strStatus'} eq $Defs::PERSONREGO_STATUS_PASSIVE) 
            and $dref->{'PersonStatus'} eq $Defs::PERSON_STATUS_REGISTERED
        )   {
            my ($nationalPeriodID, undef, undef) = getNationalReportingPeriod($Data->{db}, $Data->{'Realm'}, $Data->{'RealmSubType'}, $dref->{'strSport'}, $dref->{'strPersonType'}, 'RENEWAL');
            if ($dref->{'intNationalPeriodID'} != $nationalPeriodID)    {
                $dref->{'renewlink'} = "?a=REG_RENEWAL&amp;pID=$pID&amp;dnat=RENEWAL&amp;rtargetid=$dref->{'intPersonRegistrationID'}&amp;_ss=r&amp;rfp=r&amp;dsport=$dref->{'strSport'}&amp;dtype=$dref->{'strPersonType'}&amp;dentityrole=$dref->{'strPersonEntityRole'}&amp;dlevel=$dref->{'strPersonLevel'}&amp;d_level=$dref->{'strPersonLevel'}&amp;de=$dref->{'intEntityID'}";
            }
        }

        push @{$regos{$pID}}, $dref;
    }
    
    return (
        \%regos,
        \@people,
        \%found,
    );
}
1;
