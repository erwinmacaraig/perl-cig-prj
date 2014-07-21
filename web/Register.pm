package Register;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = @EXPORT_OK = qw(
	handleRegister
);

use strict;
use Utils;
use Reg_common;
use TTTemplate;
use Log;
use Data::Dumper;
use JSON qw( encode_json decode_json );

sub handleRegister {
    my ( 
    	$action, 
    	$Data
    	 ) = @_;
 
	my $body = '';
	my $title = '';
	
    if ($action eq 'REG_GetMyList2') {
        GetMyList2();
    }
    elsif ($action eq 'REG_GetMyList3') {
        GetMyList3();
    }
    elsif ($action eq 'REG_GetMyList4') {
        GetMyList4();
    }
    elsif ($action eq 'REG_GetMyList5') {
        GetMyList5();
    }
	else {
        ( $body, $title ) = showScreen( $Data );		
	};
   
    return ( $body, $title );
}

sub GetMyList2 {

    my $id = param('ID') || '';

    #Select * from tblXXXX where xxx = $id;

    my $array1_ref = [{v => $id . "-" . 1, t => 'Test 21'}, {v => $id . "-" . 2, t => 'Test 22'}, {v => $id . "-" . 3, t => 'Test 23'}];

    print "Content-type: application/json\n\n";
    print encode_json($array1_ref);

}

sub GetMyList3 {

    my $id = param('ID') || '';

    #Select * from tblXXXX where xxx = $id;

    my $array1_ref = [{v => 1, t => 'Test 31'}, {v => 2, t => 'Test 32'}, {v => 3, t => 'Test 33'}];

    print "Content-type: application/json\n\n";
    print encode_json($array1_ref);

}

sub GetMyList4 {

    my $id = param('ID') || '';

    #Select * from tblXXXX where xxx = $id;

    my $array1_ref = [{v => 1, t => 'Test 41'}, {v => 2, t => 'Test 42'}, {v => 3, t => 'Test 43'}];

    print "Content-type: application/json\n\n";
    print encode_json($array1_ref);

}

sub GetMyList5 {

    my $id = param('ID') || '';

    #Select * from tblXXXX where xxx = $id;

    my $array1_ref = [{v => 1, t => 'Test 11'}, {v => 2, t => 'Test 22'}, {v => 3, t => 'Test 33'}];

    print "Content-type: application/json\n\n";
    print encode_json($array1_ref);

}

sub showScreen {

my $body = q[

<script type="text/javascript">

var client = getQuerystringNameValue("client");
var scriptName = window.location.href.split('?')[0];

$(document).ready(function () {
    $("#select1").on("change",function(e) {
         var objSelect1 = $(this);
         $.ajax({ url: scriptName, data: { "Action": "REG_GetMyList2&client=" + client, "ID": objSelect1.val() }, dataType: "json" })
              .done(function (data) {
                    PopulateSelect($("#select2"), data);
	        });
    });

    $("#select2").on("change",function(e) {
         var objSelect2 = $(this);
         $.ajax({ url: scriptName, data: { "Action": "REG_GetMyList3&client=" + client, "ID": objSelect2.val() }, dataType: "json" })
              .done(function (data) {
                    PopulateSelect($("#select3"), data);
	        });
    });
    $("#select3").on("change",function(e) {
         var objSelect3 = $(this);
         $.ajax({ url: scriptName, data: { "Action": "REG_GetMyList4&client=" + client, "ID": objSelect3.val() }, dataType: "json" })
              .done(function (data) {
                    PopulateSelect($("#select4"), data);
	        });
    });
    $("#select4").on("change",function(e) {
         var objSelect4 = $(this);
         $.ajax({ url: scriptName, data: { "Action": "REG_GetMyList5&client=" + client, "ID": objSelect4.val() }, dataType: "json" })
              .done(function (data) {
                    PopulateSelect($("#select5"), data);
	        });
    });


});


function PopulateSelect(objSelect, data) {
    objSelect[0].options.length = 1;
    objSelect[0].selectedIndex = 0;    
    if (data != null) {
        for (var i = 0, numShown = 1; i < data.length; i++) {
            var optionData = data[i];
            objSelect[0].options[numShown++] = new Option(optionData.t, optionData.v);
        }
    }
    objSelect[0].disabled = (data == null || data.length == 0);
}

function getQuerystringNameValue(name)
{
    // For example... passing a name parameter of "name1" will return a value of "100", etc.
    // page.htm?name1=100&name2=101&name3=102

    var winURL = window.location.href;
    var queryStringArray = winURL.split("?");
    var queryStringParamArray = queryStringArray[1].split("&");
    var nameValue = null;

    for ( var i=0; i<queryStringParamArray.length; i++ )
    {           
        queryStringNameValueArray = queryStringParamArray[i].split("=");
        if ( name == queryStringNameValueArray[0] )
        {
            nameValue = queryStringNameValueArray[1];
        }                       
    }
    return nameValue;
}

</script>

</head>
<body>
<table border="1">
<tr><td>Registration Type</td>
<td>
<select id="select1" name="select1" >
<option value="">-- None --</option>
<option value="PLAYER">Player</option>
<option value="COACH">Coach</option>
<option value="REFEREE">Referee</option>
</select></td>
</tr>

<tr><td>Sport</td>
<td><select default="0" id="select2" name="select2" disabled="disabled">
<option value="">-- None --</option>
</select>
</td>
</tr>

<tr><td>Level</td>
<td><select default="0" id="select3" name="select3" disabled="disabled">
<option value="">-- None --</option>
</select>
</td>
</tr>

<tr><td>Reg Type</td>
<td><select default="0" id="select4" name="select4" disabled="disabled">
<option value="">-- None --</option>
</select>
</td>
</tr>

<tr><td>Age Level</td>
<td><select default="0" id="select5" name="select5" disabled="disabled">
<option value="">-- None --</option>
</select>
</td>
</tr>

</table>


];

    return ($body);

}

1;
