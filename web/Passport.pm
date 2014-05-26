#
# $Header: svn://svn/SWM/trunk/web/Passport.pm 9161 2013-08-06 04:18:30Z eobrien $
#

package Passport;

use LWP::UserAgent;
use XML::Simple;
use CGI;
use MCache;
use strict;

sub new {
    my $this   = shift;
    my $class  = ref($this) || $this;
    my %params = @_;
    my $self   = {};
    $self->{'ID'}    = $params{'id'} || 0;
    $self->{'db'}    = $params{'db'};
    $self->{'cache'} = $params{'cache'} || new MCache();
    bless $self, $class;
    return $self;
}

sub id {
    my $self = shift;
    return $self->{'ID'};
}

sub loggedin {
    my $self = shift;
    return 0 if !$self->{'ID'};
    return 0 if $self->status() != 2;    #User is confirmed
    return 1;
}

sub status {
    my $self = shift;
    return $self->{'Info'}{'Status'} || 0;
}

sub name {
    my $self = shift;
    return $self->{'Info'}{'FirstName'} || '';
}

sub fullname {
    my $self = shift;
    return join( ' ', $self->{'Info'}{'FirstName'}, $self->{'Info'}{'FamilyName'} );
}

sub email {
    my $self = shift;
    return $self->{'Info'}{'Email'} || '';
}

sub getInfo {
    my $self = shift;
    my ($field) = @_;
    return '' if !$field;
    return $self->{'Info'}{$field} || '';
}

sub loadSession {
    my $self = shift;
    my ($sessionK) = @_;

my %sessions = (
	'40whru4h535h345' => {
		FirstName => 'Warren',
		FamilyName => 'Rodie',
		Email => 'w.rodie@sportingpulseinternational.com',
		Status => 2,
		MemberID => 1,
	},
	'3490n4023894m2r' => {
		FirstName => 'Test',
		FamilyName => 'User',
		Email => 'w.rodie@sportingpulseinternational.com',
		Status => 2,
		MemberID => 20,
	},	
	'9034klfj450jljr' => {
		FirstName => 'Test',
		FamilyName => 'User',
		Email => 'w.rodie@sportingpulseinternational.com',
		Status => 2,
		MemberID => 21,
	},





);

    # This function returns information about the passport account
    # currently logged in

    my $output = new CGI;
    my $sessionkey = $sessionK || $output->cookie($Defs::COOKIE_PASSPORT) || '';
$sessionkey = '40whru4h535h345';
    return undef if !$sessionkey;

    if(exists $sessions{$sessionkey})	{
			my $info = $sessions{$sessionkey};
			$self->{'ID'} = $info->{'MemberID'};
			$self->{'Info'} = $info;
		}
		return undef;
}

sub bulkdetails {
    my $self = shift;

    # This function returns bulk information about a group of passportIDs
    # This allows no operation on the member - and no token is required
    my ($id_ref) = @_;    #Pass in ref to array of passportIDs

    return undef if !$id_ref;
    return undef if !ref $id_ref eq 'ARRAY';
    return undef if !scalar( @{$id_ref} );
    my $passport_str = join( ',', @{$id_ref} );
    return undef if $passport_str =~ /[^\d,]/;
    $passport_str =~ s/^,//;
    return undef if !$passport_str;

    my $cache = $self->{'cache'};
    my $cacheval = $cache->get( 'swm', "PS_BULK_$passport_str" );
    my ( $bulkreq_ok, $bulkreq ) = ( '', '' );
    if ($cacheval) {
        $bulkreq_ok = $cacheval->[0];
        $bulkreq    = $cacheval->[1];
    }
    if ( !$bulkreq_ok ) {
        ( $bulkreq_ok, $bulkreq ) =
          $self->_connect(
                           'BulkDetails',
                           {
                              Passports => $passport_str,
                           },
          );
        $cache->set( 'swm', "PS_BULK_$passport_str", [ $bulkreq_ok, $bulkreq ], undef, 60 * 10 ) if $cache;    #Cache for 10min
    }
    if ($bulkreq_ok) {
        return $bulkreq->{'Response'}{'Data'}{'Passports'};
    }
    return undef;
}

sub bulkdetails_hash {
    my $self = shift;

    # This function returns bulk information about a group of passportIDs
    # This allows no operation on the member - and no token is required
    my ($id_ref) = @_;    #Pass in ref to array of passportIDs

    my $ret = $self->bulkdetails($id_ref);
    return $ret if !$ret;
    if ( ref $ret ) {
        my %Passports = ();
        for my $p ( @{$ret} ) {
            $Passports{ $p->{'PassportID'} } = $p;
        }
        return \%Passports;
    }
    return undef;
}

sub search {
    my $self = shift;

    # This function returns bulk information about a group of passportIDs
    # where the member's name matches the search string
    # This allows no operation on the member - and no token is required
    my ($search_string) = @_;    #Pass in ref to array of passportIDs

    my $cache = $self->{'cache'};
    my $cacheval = $cache->get( 'swm', "PS_SEARCH_$search_string" );
    my ( $searchreq_ok, $searchreq ) = ( '', '' );
    if ($cacheval) {
        $searchreq_ok = $cacheval->[0];
        $searchreq    = $cacheval->[1];
    }
    if ( !$searchreq_ok ) {
        my ( $searchreq_ok, $searchreq ) =
          $self->_connect(
                           'Search',
                           {
                              SearchCriteria => $search_string,
                           },
          );
        $cache->set( 'swm', "PS_SEARCH_$search_string", [ $searchreq_ok, $searchreq ], undef, 60 * 10 ) if $cache;    #Cache for 10min
    }
    if ($searchreq_ok) {
        my %Passports = ();
        for my $p ( @{ $searchreq->{'Response'}{'Data'}{'Passports'} } ) {
            $Passports{ $p->{'PassportID'} } = $p;
        }
        return \%Passports;
    }
    return undef;
}

sub isMember {
    my $self = shift;

    # This function returns the ID and status of the member for a given email address
    my ($email) = @_;    #Pass in ref to array of passportIDs

    return undef if !$email;
    my $cache = $self->{'cache'};
    my $cacheval = $cache->get( 'swm', "ISMEMBER_$email" );
    my ( $ismemberreq_ok, $ismemberreq ) = ( '', '' );
    if ($cacheval) {
        $ismemberreq_ok = $cacheval->[0];
        $ismemberreq    = $cacheval->[1];
    }
    if ( !$ismemberreq_ok ) {

        ( $ismemberreq_ok, $ismemberreq ) =
          $self->_connect(
                           'IsMember',
                           {
                              Email => $email,
                           },
          );
        $cache->set( 'swm', "PS_ISMEMBER_$email", [ $ismemberreq_ok, $ismemberreq ], undef, 60 * 10 ) if $cache;    #Cache for 10min
    }
    if ($ismemberreq_ok) {
        return (
                 $ismemberreq->{'Response'}{'Data'}{'PassportID'},
                 $ismemberreq->{'Response'}{'Data'}{'Status'},
        );
    }
    return ( 0, 0 );
}

sub addModule {
    my $self = shift;
    my ( $modulename, $email ) = @_;
    $modulename ||= 'SPMEMBERSHIP';

    # This function sets the module SPWEBSITES in the passport
    my $cache = $self->{'cache'};
    my ( $addmodulereq_ok, $addmodulereq ) =
      $self->_connect(
                       'AddModulesBulk',
                       {
                          Module => $modulename,
                          Email  => $email,
                       },
      );
    return ( 0, 0 );
}

sub create_passport {
    my $self = shift;
    my ($params) = @_;

    my ( $ok, $response ) =
      $self->_connect(
                       'CreatePassport',
                       {
                          'Email'      => $params->{'Email'},
                          'Firstname'  => $params->{'Firstname'},
                          'Familyname' => $params->{'Familyname'},
                          'Country'    => $params->{'Country'},
                          'State'      => $params->{'State'},
                       }
      );
    if ($ok) {
        return ( $response->{'Response'}{'Data'}{'PassportID'}, [] );
    }
    else {
        my $data = $response->{'Response'}{'Data'};
        return ( undef, ['An error occured while trying to call the web service.'] )
          if ( !$data );
        return ( undef, ref $data eq 'ARRAY' ? $data : [$data] );
    }
}

# ---------

sub _connect {
    my $self = shift;
    my (
         $action,
         $data,
    ) = @_;

    my $app_signature = $Defs::PassportSignature;
    my $ua            = LWP::UserAgent->new;
    $ua->agent("SWM");
    my $req = HTTP::Request->new( GET => "$Defs::PassportURL/api/" );
    my %Request = (
                    Request => {
                                 Version      => '1.0',
                                 Action       => $action,
                                 AppSignature => $app_signature,
                                 Data         => $data || '',
                    },
    );
    my $msg = XMLout( \%Request, KeepRoot => 1, NoAttr => 1, KeyAttr => [] );

    $req->header( 'Content-type' => 'application/xml' );
    $req->content($msg);

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    my $responsetxt;

    my $ok = 0;
    my $Response;
    if ( $res->is_success ) {
        $responsetxt = $res->content;
    }
    if ($responsetxt) {

        #don't attempt to process the xml if it's not set, otherwise it will try to find an xml file with the same name as the cgi, which is pointless and confusing
        $Response = XMLin( $responsetxt, ForceArray => ['Passports'], KeyAttr => [], suppressempty => 1, KeepRoot => 1 );
    }
    if (     $Response->{'Response'}{'Result'}
         and $Response->{'Response'}{'Result'} eq 'SUCCESS' )
    {
        $ok = 1;
    }

    return (
             $ok,
             $Response,
    );
}

1;
