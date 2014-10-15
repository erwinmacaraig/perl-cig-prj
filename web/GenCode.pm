package GenCode;

use Exporter;
@EXPORT=qw(new);

use lib "../web";
use strict;
use Utils;

#This code generates new unique numbers based on conditions contained in tblGenerate
# 
# Fields in tblGenerate

#intGenerateID: 2   - Unique ID
   #intRealmID: 1   - RealmID that this rule is for
#intSubRealmID: 0   - SubRealmID that this rule is for
  #intEntityID: 1   - EntityID that this rule is for
   #strGenType: PERSON   - What type of thing is the number for options, PERSON, ENTITY,FACILITY
    #intLength: 5        - Length of the Sequence number 
    #intMaxNum: 99999    - Maximum value of the sequence number
#intCurrentNum: 10006    - Current value of the sequence number
   #tTimeStamp: 2014-10-15 08:54:18
    #strFormat: %P%SEQUENCE%GENDER%-%YEAR
#  The format field of the number defines what the number looks like.  It consists of numerous different parts, all separated by a % character. Each part can be named with a string. %SEQUENCE is a special value that includes the automatically generatd sequence number.

    #strValues: GENDER=$params->{"gender"} == 2 ? "F" : "M"#YEAR=substr($params->{"dob"},2,2)

# The values field defines how to generate the parts defined in the format section.
# The Values field contains definitions of the format NAME followed by an = and then followed by a Perl expression.  The different values are delimited with a # character.  The Perl expression must return a value.
# The perl expression has access to a variable $params which is a reference to the has the user has passed in to the function.
# Any name in the strFormat field not in the strValues field will be added in to the number as a text string.  


sub new {

  my $this = shift;
  my $class = ref($this) || $this;
  my (
    $db, 
    $type,
    $realmID, 
    $subRealmID, 
    $entityID,
  )=@_;
  my %fields=();
	$fields{'db'}=$db || '';
	$fields{'realmID'} = $realmID || 0;
	$fields{'subRealmID'} = $subRealmID || 0;
	$fields{'entityID'} = $entityID || 0;
	$fields{'type'} = $type || 0;
	
	#Setup Values
	my $statement=qq[
        SELECT *
        FROM tblGenerate
        WHERE 
            strGenType = ?
            AND intRealmID = ?
            AND intSubRealmID IN (0,?)
            AND intEntityID IN (0,?)
        ORDER BY
            intEntityID DESC,
            intSubRealmID DESC
        LIMIT 1
	];
	my $query=$db->prepare($statement) or query_error($statement);
	$query->execute(
        $fields{'type'},
        $fields{'realmID'},
        $fields{'subRealmID'},
        $fields{'entityID'},
    );
	$fields{'Data'}= $query->fetchrow_hashref();
	if(!$fields{'Data'})	{ $fields{'Data'}{'strGenType'} = 0;	}
	$query->finish();

	my $self={%fields};
  bless $self, $class;
  ##bless selfhash to GenCode;
  ##return the blessed hash
  return $self;
}


sub getNumber	{
	#return a new member number

	my $self = shift;
	my($params)=@_;

  my @numberParts = ();
  return '' if !$self->Active();
  my $format =  $self->{'Data'}{'strFormat'} || '';
  return '' if !$format;
  my @formatarray = split/%/,$format;
  my $valueStr =  $self->{'Data'}{'strValues'} || '';
  my @valueArray = split /\#/,$valueStr;
  my %valueHash = ();
  for my $i (@valueArray)   {
    my($k,$v) = split /=/,$i,2;
    if($k and $v)   {
        $valueHash{$k} = $v;
    }
  }

  my $sequenceNumber = '';
  if($format =~/\%SEQUENCE/) {
    $sequenceNumber = $self->getSequenceNumber($params);
  }

  for my $part (@formatarray)   {
    if(exists($valueHash{$part}) and $valueHash{$part})   {
      push @numberParts, $self->evalPart($valueHash{$part}, $params) || '';
    }
    elsif($part eq 'SEQUENCE')  {
      push @numberParts, $sequenceNumber || '';
    }
    #elsif($part eq 'ALPHACHECK')  {
      #push @numberParts, $self->genCheckLetter($sequenceNumber) || '';
    #}
    else    {
      push @numberParts, $part;
    }
  }

  my $number = join('',@numberParts);
  return $number;
}

sub getSequenceNumber {
	my $self = shift;
	my($params)=@_;

  my $db = $self->{'db'} or return '';

  #Sequential Numbers
  my $statement_UPD=qq[
    UPDATE tblGenerate
    SET intCurrentNum=LAST_INSERT_ID(intCurrentNum+1)
    WHERE intGenerateID = ?
    LIMIT 1
  ];
  my $q = $db->prepare($statement_UPD);
  $q->execute($self->{'Data'}{'intGenerateID'});
  $self->{LastNum} = $q->{mysql_insertid} || 0;
  $q->finish();

  my $newnum=$self->{'LastNum'};
  my $gen_length = $self->{'Data'}{'intLength'};
  $newnum = sprintf("%0*d",$gen_length, $newnum);
  return $newnum;
}

sub genCheckLetter	{
	my($code)=@_;
	my $total_char=0;
	my @alpha_array=qw(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z);

	my @letter_array=split //,$code;
	for my $i (0 .. $#letter_array)	{
		next if $letter_array[$i]!~/\d/;
		$total_char+=$letter_array[$i];
	}
	my $index=($total_char%26);	
	return $alpha_array[$index];
}

sub evalPart {
	my $self=shift;
  my (
    $evalString,
    $params,
  ) = @_;
  return '' if !$evalString;
  my $output = '';
  my $eval = '$output = ('.$evalString.');';
  eval($eval);
  return $output || '';
}

sub Active	{
	my $self=shift;
	if($self->{Data}{strGenType})	{ return 1;	}
	else	{ 	return 0;	}
}

sub getPrefix	{
	my $self=shift @_;
	return $self->{Data}{strMemberPrefix} || '';
}

sub getSuffix	{
	my $self=shift @_;
	return $self->{Data}{strMemberSuffix} || '';
}
1;
