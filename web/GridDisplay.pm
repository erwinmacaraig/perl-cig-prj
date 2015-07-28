#
# $Header: svn://svn/SWM/trunk/web/GridDisplay.pm 11517 2014-05-08 05:27:49Z mstarcevic $
#

package GridDisplay;

require Exporter;
@ISA =  qw(Exporter);
@EXPORT = qw(showGrid);
@EXPORT_OK = qw(showGrid);

use lib ".", "..","../..";
use strict;
use Utils;
use JSON;
use CGI qw(escape unescape param);
use MIME::Base64 qw(encode_base64url decode_base64url);
use HTML::Entities;
use URI::Escape;
=head1 NAME

GridDisplay - Perl interface to a javascript based grid

=head1 SYNOPSIS

  use SimpleGrid;

  my $grid  = showGrid(
    Data => $Data,
    columns => \@headers,
    rowdata => \@rowdata,
    gridid => 'grid',
    width => '99%',
    height => 700,
    filters => $filterfields,
  );

=head1 DESCRIPTION

This code provides a grid output of the data passed in. There are two grid output options that can be generated.  A fully functional Javascript based grid (using SlickGrid) or a basic table based HTML version.


=head2 showGrid()

There is only one function exported, showGrid(). This is the function that takes the parameters and generates the grid.

showGrid accepts a series of named parameters.

=over 1

=item Data (Required)

The reference to the SP Membership Data Hash

=item columns (Required)

A reference to an array defining the columns to be displayed in the grid.  See below (Column Definition) for details on the format and options available.

=item rowdata (Required)

A reference to an array of hashes defining the data to be displayed in the grid.  See below (Data Definition) for details on the format and options available.

=item gridid (Required)

A string that is prefixed to the DOM elements and Javascipt to generate a unique instance name for this grid.

=item width (Required)

Indicates the width of the grid.  This can either be a number or a percentage.  Any variable that is purely numbers is taken to be a width in pixels. eg 100 or '90%'.

=item height

Indicates the display height of the grid.  If blank the grid will be set automatically to the height needed to fit the grid data.  This may results in lower performance.  If a height is set then the data will scroll inside the grid element.  This value can either be a number or a percentage.  Any variable that is purely numbers is taken to be a width in pixels. eg 100 or '90%'.

=item display_pager

A boolean value indicating whether the grid should display a pager line on the bottom of the grid. 1= true, 0 = false.

=item filterfields

A reference to an array of hashes of available filters for the grid.  See below (Filter Definition) for details on the the format and options available.

=item simple

If this value is set, then a simple HTML table based grid is generated rather than a full Javascript based grid. If this is set then most other layout parameters are ignored. 

=back 

=head1 COLUMN DEFINITION

The header definition is an array of hashes.

  my @headers = (
    {
      type => 'Selector',
      field => 'SelectLink',
    },
    {
      name =>   'Name',
      field =>  'title',
    },
    );


Each hash can have the following keys.

=over 1

=item field (Required)

    The fieldname in the data that this column relates to.

=item name (Required)

    This is the label for the column.  This is required for all columns except those defined as type = 'Selector' or 'RowCheckbox'.

=item type

    The type of column.  The default value of blank indicates that the data in the column is a simple string value.

Other options

=over 1

=item Selector

    The type indicates a row selection button.  This has specific formatting and is used as a click through to detail of the grid.

=item RowCheckbox

    This column type should be specified first and applies a checkbox to select an entire row.

=item tick

    This column displays a tickbox if the value is true.

=item datetime

    This column displays as a date time

=item HTML

    This column displays as a HTML element as defined by the value

=item selectlist

    The value displayed is from a lookup table

=back 

=item editor

If a saveurl has been specified then cell editing is available.  If the column is specified as one of these types, then the user can edit it.

=over 1

=item checkbox

    The column is edited as a checkbox

=item text

    The column is edited as a text box

=item date
        
    The column is edited as a date selection box

=item datetime
        
    The column is edited as a date selection box and a time selection box

=item selectbox

    The column is edited as a dropdown list, where the values come from the 'options' parameter of the column.

=back

=item hide

    If this option is true, then the column will not display. A boolean value where 1 = true, 0 = false.

=item sortable

    If this option is true, then the column be able to be sorted by clicking the column header.  Default is true. A boolean value where 1 = true, 0 = false.

=item resizable

    If this option is true, then the column be able to be resized by dragging the column header.  Default is true. A boolean value where 1 = true, 0 = false.  The changed column width is not saved.

=item width

    Specifies (in pixels) the width of the column.  

=item class

    Adds an additional CSS class to the column

=item sorttype

    Gives hints to the grid sorting on how to handle the column sorting. By default this is a text based sort.  If this value is set to 'number' then a numerical sort is used.

=item options

    A string of options for the selectbox editor to use.  Format: key1,value1|key2,value2.

=item sortdata

    This value allows sorting of a hidden field instead of the visible field.  This value should be the hash key where the value resides.

=back 

=head1 DATA DEFINITION

The Data Definition is an array of hashes, where each row is a grid row, and each hash key is a column for the grid.

    @rowdata = (
        {
            id => 1,
            title => 'Title 1',
        },
        {
            id => 2,
            title => 'Title 2',
        },
    );


    Each row must have a key called 'id' which must be a unique value for each row.
    Sorting is peformed on the datafield, but will in preference use a key suffixed with '_RAW'.

=head1 FILTER DEFINITION

The Filter Definition is an array of hashes, where each row is a different filter.  The actual filter fields control fields (search boxes/select boxes) are not actually part of the grid, instead using DOM element IDs the grid will listen for events on existing elements,

  $filterfields = [
    {
      field => 'title',
      elementID => 'id_textfilterfield',
      type => 'regex',
    },
    {
      field => 'seasonID',
      elementID => 'dd_seasonfilter',
      allvalue => '-99',
    },
    );

  Each filter definition can contain the following options

=over 1 

=item field (Required)

The field in the data that this filter is applied to

=item elementID (Required) 

The ID of the DOM element that this filter relates to

=item type

By default the filter is a string equals comparison.  Where the value in the DOM element must equal the value in the datafield.  If type is set to 'regex' then the comparison is whether the data field contains the value in the DOM element.

=item allvalue

This is the value in the DOM element that indicates that the filter should not be applied.

=back 


=cut

sub makeExportTable
{

	my %params = @_;
    my $flat .= qq[<table id="tblFlat" class="listTable"><thead>];
    $flat .= qq[<tr>];

    foreach my $th (@{$params{'columns'}}){

                if($th->{'options'}) {
                    my %options = split(/[|,]/, $th->{'options'});
                    $th->{'optionssplit'} = \%options;
                }    
        $flat .= qq[<td><b>$th->{'name'}</b></th>] if($th->{'name'});
    }
    $flat .= qq[
                </tr>
                </thead>
                <tbody>
                ];
    my $i=0;
    foreach my $row(@{$params{'rowdata'}} ) {
        my $shade=$i%2==0? ' class="rowshade" ' : '';
        $i++;
        $flat .= qq[<tr>];
        foreach my $th (@{$params{'columns'}}){
            if($th->{'name'}) {
                my $field = $row->{$th->{'field'}} || '';
                if($th->{'optionssplit'}) { $field = $th->{'optionssplit'}{$field} if($th->{'optionssplit'}{$field} and $field!='') };
                $flat .= qq[<td$shade>$field</td>];
            }
        }


        $flat .= qq[</tr>];
    }

    $flat .= qq[
                </tbody>
                </table>
                ];
	$flat =~ s#</?(?:a)\b.*?>##g;
	return $flat;

}

sub showGrid {
	my %params = @_;

    my $self = shift;
    my $flat = makeExportTable(%params);
	my $Data                     = $params{'Data'}                     || return ''; #array of hashes of column names and details
	my $columninfo               = $params{'columns'}                  || return ''; #array of hashes of column names and details
	my $grid_data                = $params{'rowdata'}                  || return ''; #array of hashes with grid data
	my $gridID                   = $params{'gridid'}                   || 'grid';
	my $height                   = $params{'height'}                   || '';
	my $width                    = $params{'width'}                    || '';
	my $basicgrid                = $params{'basicgrid'}                || '';
	my $filterfields             = $params{'filters'}                  || [];
    my $cellValidator            = $params{'cellValidator'}            || ''; #a javascript function which does the required cell validation
    my $msg_area_id              = $params{'msgareaid'}                || ''; #the id of the div which will contain any messages generated
    my $content_width_adjustment = $params{'content_width_adjustment'} || 20;
 	my $client                   = $params{'client'}                   || '';
	my $saveurl                  = $params{'saveurl'}                  || '';
	my $saveaction               = $params{'saveaction'}               || '';
	my $ajax_keyfield            = $params{'ajax_keyfield'}            || 'id';
	my $groupby                  = $params{'groupby'}                  || '';
	my $coloredTopClass          = $params{'coloredTop'}               || 'yes';
	my $groupby_collection_name  = $params{'groupby_collection_name'}  || 'items';
	my $grid_title_display       = $params{'gridtitle'}                || '';
	#
	my $sortColumn				 = $params{'sortColumn'} || [];
	my $instanceDestroy			 = $params{'instanceDestroy'} || 'false';
	#
	my $display_pager            = exists $params{'display_pager'} 
		? $params{'display_pager'} 
		: 1;

	if($width)	{
		$width .= 'px' if $width =~/^\d+$/;
		$width = "width:$width";
	}
	my $autoheight = 'true';
	if($height)	{
		$height .= 'px' if $height =~/^\d+$/;
		$height = "height:$height";
		$autoheight = 'false';
	}

	if($params{'simple'})	{
		return simpleGrid(
			$Data,
			$columninfo, 
			$grid_data,
			$width,
		);
	}

	$display_pager = 0 if scalar(@{$grid_data}) < 25;
	for my $i ((
        "//cdn.datatables.net/1.10.4/js/jquery.dataTables.min.js",
	))	{
		$Data->{'AddToPage'}->add('js_bottom','file',$i);
	}
	for my $i ((
	))	{
		$Data->{'AddToPage'}->add('css','file',$i);
	}

	$width ||= '';
	my $headers = '';
	my $tabledata = '';
	for my $h (@{$columninfo})	{
		my $field = $h->{'field'} || next;
		my $name = $h->{'name'} || '';
		next if $h->{'hide'};
		$name = ' ' if $field eq 'SelectLink';
		next if !$name;
		$headers .= qq[<th>$name</th>];
	}
	my $cnt = 0;
	for my $row (@{$grid_data})	{
		$tabledata .= qq[<tr class = "">];
		for my $h (@{$columninfo})	{
			my $field = $h->{'field'} || next;
			my $type = $h->{'type'} || '';
			next if $h->{'hide'};
			my $val = defined $row->{$field}
				? $row->{$field}
				: '';
			if($type eq 'tick')	{
				$val = $val
					? qq[<img src="images/gridcell_tick.png">] 
					: "";
			}
			if($type eq 'RowCheckbox')	{
				$val = qq[<input type = "checkbox" name = "chk_$field].qq[_$val" class = "grid_chk chk_$field" value = "$val">];
			}
			if($field eq 'SelectLink' and $val)	{
                my $txt = $Data->{'lang'}->txt('View');
                $txt = $h->{'text'} if $h->{'text'};
				$val = qq[<a href = "$val" class = "btn-inside-panels">$txt</a>];
			}
            my $sortdata = '';
			if($h->{'sortdata'})    {
                $sortdata = qq[ data-sort = "$row->{$h->{'sortdata'}}" ];
            }
			$tabledata .=qq[<td$sortdata>$val</td>];
		}
		$tabledata .= "</tr>";
		$cnt++;
	}
	if($tabledata eq '') { $tabledata = '<tr><td colspan="20">'.$Data->{'lang'}->txt('Sorry there is no data to return').'</td></tr>'; }
    my %gridConfig = ();
    if(!$display_pager) {
        $gridConfig{'paging'} = 'false';
    }
    $gridConfig{'dom'} = 'ilftpr';
    $gridConfig{'language'}{'search'} = $Data->{'lang'}->txt('Filter');
    $gridConfig{'language'}{'sInfo'} = $Data->{'lang'}->txt('Showing _START_ to _END_ of _TOTAL_ entries');
    $gridConfig{'language'}{'sLengthMenu'} = $Data->{'lang'}->txt('Show _MENU_ entries');
    $gridConfig{'language'}{'oPaginate'} = {
        sFirst=>    $Data->{'lang'}->txt("First"),
        sLast=>     $Data->{'lang'}->txt("Last"),
        sNext=>     $Data->{'lang'}->txt("Next"),
        sPrevious=> $Data->{'lang'}->txt("Previous")
    };
    $gridConfig{'language'}{'sZeroRecords'} = $Data->{'lang'}->txt("No matching records found");
	my ($columndefs , $headerInfo) = processFieldHeaders($columninfo);
    $gridConfig{'columns'} = $columndefs;
	$gridConfig{'order'} =  $sortColumn;
	$gridConfig{'destroy'} = $instanceDestroy;
	my $config_str = to_json(\%gridConfig);
	$config_str =~s/"(false|true)"/$1/g;
    my $js = qq[
        var table = jQuery("#$gridID").dataTable($config_str);
    ];
    if(scalar(@{$grid_data}) > 0)   {
        $Data->{'AddToPage'}->add('js_bottom','inline',$js);
    }

    my $coloredtop = $coloredTopClass eq 'yes' ? 'tableboxheader' : '';
    my $initialCols = $headerInfo->{'initialColumns'} || '1';
    my $gridtitle = $grid_title_display ? qq[ <div class="pageHeading">$grid_title_display</div> ] : '';

	return qq[
        $gridtitle
		<table id = "$gridID" initial-cols="$initialCols" class = "res-table table $coloredtop zebra" style = "$width">
			<thead>
				<tr class = " res-headers ">$headers</tr>
			</thead>
			<tbody>
			$tabledata
			</tbody>
		</table>
	];

}


sub processFieldHeaders	{
	my ($headers) = @_;

	my @output_headers = ();
	my %headerInfo = ();
    my @initialColumns = ();
    my $cnt = 0;
    my $gotSelector = 0;
	for my $field (@{$headers})	{
		my $name = $field->{'name'};	
        my $selector = 0;
		if($field->{'type'} and $field->{'type'} eq 'Selector')	{
			$name = ' ';
            $selector = 1;
		}
		next if !$name;
		next if $field->{'hide'};
		my $fieldname = $field->{'field'} || next;	
		my $id = $field->{'id'} || $fieldname;
		my $sortable = 'true';
		if(exists $field->{'sortable'} and !$field->{'sortable'})	{
			$sortable = 'false';
		}
		my %row = (
            name => $name,
            sortable => $sortable,
		);

		$row{'width'} = $field->{'width'} if $field->{'width'};
		if($field->{'type'})	{
			if($field->{'type'} eq 'HTML')  {
				$row{'type'} = 'HTML';
            }
            if($field->{'type'} eq 'datetime')  {
				$row{'type'} = 'date';
            }
			if($field->{'type'} eq 'Selector')	{
				$row{'sortable'} = 'false';
				$row{'searchable'} = 'false';
                push @initialColumns, $cnt;
                $selector = 1;
			}
		}
        if($field->{'defaultShow'} and !$selector) {
                push @initialColumns, $cnt;
        }
        $gotSelector = 1 if $selector;
		$row{'className'} = $field->{'class'} if $field->{'class'};
		$field->{'sorttype'} ||= '';
		$row{'type'} = 'num' if $field->{'sorttype'} eq 'number';
		$headerInfo{$fieldname} = \%row;
		push @output_headers, \%row;
        $cnt++;
	}
    if(scalar(@initialColumns) == 1 and $gotSelector)   {
        unshift @initialColumns, 0;
    }
    $headerInfo{'initialColumns'} = join('-',@initialColumns);
	return (\@output_headers, \%headerInfo);
}

sub makeFilterJS		{
	my ($gridID, $filterfields) = @_;
	my $update_filter_js = '';
	my $filter_event_js = '';

	my $cnt = 0;
	for my $filter (@{$filterfields})	{
		$filter->{'type'} ||= '';
		$filter->{'allvalue'} ||= '';
		$update_filter_js .= qq~	SearchParams[$cnt] = new Array('$filter->{"field"}',jQuery('#$filter->{"elementID"}').val(),'$filter->{'type'}', '$filter->{'allvalue'}'); ~;
		$cnt++;
		if($filter->{'type'} eq 'regex')	{
			$filter_event_js .= qq[ jQuery("#$filter->{'elementID'}").keyup(function (e) { filterEvent_$gridID(e, this); });];
		}
		elsif($filter->{'type'} eq 'reload')
		{
            $filter_event_js .= qq[ jQuery("#$filter->{'elementID'}").change(function () {$filter->{'js'};  document.location.reload();  });];
		}
		else	{
			$filter_event_js .= qq[ jQuery("#$filter->{'elementID'}").change(function () { filterEvent_$gridID(); });];
		}
	}


	return ($update_filter_js, $filter_event_js);
}

sub simpleGrid	{

	my (
		$Data,
		$columninfo, 
		$grid_data,
		$width,
	) = @_;
	$width ||= '';
	my $headers = '';
	my $tabledata = '';
	for my $h (@{$columninfo})	{
		my $field = $h->{'field'} || next;
		my $name = $h->{'name'} || '';
		next if $h->{'hide'};
		$name = ' ' if $field eq 'SelectLink';
		next if !$name;
		$headers .= qq[<th>$name</th>];
	}
	my $cnt = 0;
	for my $row (@{$grid_data})	{
		$tabledata .= qq[<tr class = "">];
		for my $h (@{$columninfo})	{
			my $field = $h->{'field'} || next;
			my $type = $h->{'type'} || '';
			next if $h->{'hide'};
			my $val = defined $row->{$field}
				? $row->{$field}
				: '';
			if($type eq 'tick')	{
				$val = $val
					? qq[<img src="images/gridcell_tick.png">] 
					: "";
			}
			if($field eq 'SelectLink' and $val)	{
				$val = qq[<a href = "$val" class = "btn-inside-panels">].$Data->{'lang'}->txt('View') .qq[</a>];
			}
			$tabledata .=qq[<td>$val</td>];
		}
		$tabledata .= "</tr>";
		$cnt++;
	}
	if($tabledata eq '') { $tabledata = '<tr><td colspan="20">Sorry there is no data to return</td></tr>'; }

	return qq[
		<table class = "table zebra" style = "$width">
			<thead>
				<tr class = "">$headers</tr>
			</thead>
			<tbody>
			$tabledata
			</tbody>
		</table>
	];
}

1;
