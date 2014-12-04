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

=item saveurl

If field editing is available, the URL that the save request is sent to.

=item client

A field that is passed as 'client=' to the saveurl

=item saveaction

A field that is passed as 'a=' to the saveurl

=item ajax_keyfield

This should represent a field in the data that is sent with the saverequest as 'key='

=item groupby

If specified, the grid is grouped by this field.  This value should be a column name as defined in the columns hash.

=item groupby_collection_name

The text label used for the grouping line indicating the number of items in the grouping. eg. 
7 'items', 10 'matches', 3 'people'. Default value is 'items'.

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
	my $groupby_collection_name  = $params{'groupby_collection_name'}  || 'items';
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
			if($field eq 'SelectLink' and $val)	{
				$val = qq[<a href = "$val" class = "btn-inside-panels">].$Data->{'lang'}->txt('View') .qq[</a>];
			}
			$tabledata .=qq[<td>$val</td>];
		}
		$tabledata .= "</tr>";
		$cnt++;
	}
	if($tabledata eq '') { $tabledata = '<tr><td colspan="20">Sorry there is no data to return</td></tr>'; }
    my %gridConfig = ();
    if(!$display_pager) {
        $gridConfig{'paging'} = 'false';
    }
	my ($columndefs , $headerInfo) = processFieldHeaders($columninfo);
    $gridConfig{'columns'} = $columndefs;
	my $config_str = to_json(\%gridConfig);
	$config_str =~s/"(false|true)"/$1/g;
    my $js = qq[
        var table = jQuery("#$gridID").dataTable($config_str);
    ];
    if(scalar(@{$grid_data}) > 0)   {
        $Data->{'AddToPage'}->add('js_bottom','inline',$js);
    }

	return qq[
		<table id = "$gridID" class = "table tableboxheader zebra" style = "$width">
			<thead>
				<tr class = "">$headers</tr>
			</thead>
			<tbody>
			$tabledata
			</tbody>
		</table>
	];

}


sub old {
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
	my $groupby_collection_name  = $params{'groupby_collection_name'}  || 'items';
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
	my $pagerdisplay = $display_pager ? '' : 'display:none;';

	my ($columndef_str, $checkbox_row_select, $headerInfo) = processFieldHeaders($columninfo, $saveurl);
	my $groupby_fieldlabel = '';
	if($groupby)	{
		$groupby_fieldlabel = $headerInfo->{$groupby}->{'name'} || '';
	}
	my $checkbox_select_column = '';
	if($checkbox_row_select)	{
		$checkbox_select_column = 'gridcolumns.unshift(checkboxSelector.getColumnDefinition());';
	}
	my $data_str = to_json($grid_data);
	my $update_filter_js = '';
	my $filter_event_js = '';
	my $filter_panel = '';
	if($filterfields and scalar(@{$filterfields}))	{
		($update_filter_js, $filter_event_js)  = makeFilterJS($gridID, $filterfields);
	}

    my $show_msg_method = ($msg_area_id) 
        ? qq[
              jQuery("#$msg_area_id").html(msg);
              jQuery("#$msg_area_id").show()
          ] 
        : qq[
              alert(msg);
          ];

    my $show_msg_function = qq[
        function showMessage(msg) { 
            $show_msg_method 
        }
    ];

    my $clear_msg_method = '';

    $clear_msg_method = qq[
        jQuery("#$msg_area_id").html('');
        jQuery("#$msg_area_id").hide();
    ] if $msg_area_id;

    my $clear_msg_function = qq[
        function clearMessage() { 
            $clear_msg_method 
        }
    ];

	my $body = '';
	#$flat =  uri_escape($flat);
my  $reportlink = qq[<div id="grid-report" style="padding:12px;">
 <span class="button-small generic-button"><a class="show-select$basicgrid" href="#"><span class="basic-g$basicgrid">Basic Grid</span><span class="advanced-g$basicgrid" style="display:none;">Advanced Grid</span></a></span></div>
	<div class="regs-test" id="copythis$basicgrid" style="display:none;">
		<div id="flatgrid">
			$flat
		</div>
	</div>
<script>
jQuery(".show-select$basicgrid").click(function () {
	jQuery("#copythis$basicgrid").toggle();
	jQuery(".basic-g$basicgrid").toggle();
	jQuery(".advanced-g$basicgrid").toggle();
	jQuery(".grid-widget$basicgrid").toggle();
});
</script>
] if($basicgrid);

    $reportlink ||= '';
	$body = qq~
		$reportlink
		<div class = "grid-widget$basicgrid">
			<div id = "$gridID" style="$width;$height;">Loading...</div>
			<div id="pager_$gridID" style="$width;height:20px;$pagerdisplay"></div>
		</div>
		<script>
            $cellValidator
			var grid_$gridID;
			var dataView_$gridID;
		</script>
	~;
	my $js = qq~
		{
			var screenwidth = jQuery("#content").width() - $content_width_adjustment;
			jQuery("#$gridID").width(screenwidth);
			jQuery("#pager_$gridID").width(screenwidth);

			var gridoptions = {
				asyncEditorLoading: true,
				editable: true,
				autoEdit: true,
				forceFitColumns: true,
				autoHeight: $autoheight,
				enableCellNavigation: true,
				syncColumnCellResizer: true,
				enableColumnReorder: false
			};
			var checkboxSelector = new Slick.CheckboxSelectColumn({ cssClass: "slick-cell-checkboxsel" });

			var groupbyfield = '$groupby';
			var griddata = $data_str;
			var gridcolumns = $columndef_str;
			$checkbox_select_column
			var gridstyles_$gridID = new Array;
			var groupItemMetadataProvider_$gridID = new Slick.Data.GroupItemMetadataProvider();
			dataView_$gridID = new Slick.Data.DataView({
				groupItemMetadataProvider: groupItemMetadataProvider_$gridID,
				inlineFilters: true
			});

			var pluginOptions = {
  			  clipboardCommandHandler: function(editCommand){ undoRedoBuffer.queueAndExecuteCommand.call(undoRedoBuffer,editCommand); }
  			};

            $clear_msg_function

			grid_$gridID = new Slick.Grid("#$gridID", dataView_$gridID, gridcolumns, gridoptions);
			grid_$gridID.setSelectionModel(new Slick.RowSelectionModel({selectActiveRow: false}));		
			grid_$gridID.registerPlugin(groupItemMetadataProvider_$gridID);
			new Slick.Controls.Pager(dataView_$gridID, grid_$gridID, jQuery("#pager_$gridID "));
			grid_$gridID.onSort.subscribe(function(e, args) {
				clearHighlighting();
				sortdir = args.sortAsc ? 1 : -1;
				sortcol = args.sortCol.field;
				var headerclass = args.sortCol.headerCssClass || '';
				sorttype = 'string';
				if(headerclass.indexOf('grid_sorttype_num') >= 0)	{
					sorttype = 'number';
				}
				dataView_$gridID.sort(comparer, args.sortAsc);
			})
            grid_$gridID.onAddNewRow.subscribe(function (e, args) {
                var item = args.item;
                var column = args.gridcolumn;
                grid.invalidateRow(dataView_$gridID.length);
                 dataView_$gridID.push(item);
                grid_$gridID.updateRowCount();
                grid_$gridID.render();
            });
            grid_$gridID.onClick.subscribe(function (e) {
                grid_$gridID.removeCellCssStyles('highlight');
                clearMessage();
            });
			dataView_$gridID.onRowsChanged.subscribe(function(e,args) {
					grid_$gridID.invalidateRows(args.rows);
					grid_$gridID.render();
			});

			function clearHighlighting () {
				 if (typeof gridstyles_$gridID != 'undefined' && gridstyles_$gridID) {
                    for(var i=0, len= gridstyles_$gridID.length; i < len; i++){
					   grid_$gridID.removeCellCssStyles(gridstyles_$gridID~.qq~[i]);
			    	}
                 }
			}

            $show_msg_function

            function highlightRow(row) {
                var hash  = {};
                hash[row] = {};
                jQuery.each(gridcolumns, function(index, value) {
                    if (index > 0) {
                        hash[row][value.id] = 'grid_row_warning';
                    }
                });
                grid_$gridID.setCellCssStyles('highlight', hash);
            }

			function collapseAllGroups() {
				dataView_$gridID.beginUpdate();
				for (var i = 0; i < dataView_$gridID.getGroups().length; i++) {
					dataView_$gridID.collapseGroup(dataView_$gridID.getGroups()[i].value);
				}
				dataView_$gridID.endUpdate();
			}

			function expandAllGroups() {
				dataView_$gridID.beginUpdate();
				for (var i = 0; i < dataView_$gridID.getGroups().length; i++) {
					dataView_$gridID.expandGroup(dataView_$gridID.getGroups()[i].value);
				}
				dataView_$gridID.endUpdate();
			}

			function clearGrouping() {
				dataView_$gridID.groupBy(null);
			}

			$filter_event_js
			function updateFilter_$gridID() {
				clearHighlighting();
				var SearchParams = new Array;
				$update_filter_js
				dataView_$gridID.setFilterArgs({
					SearchParams: SearchParams
				});
				dataView_$gridID.refresh();
			}

			// wire up model events to drive the grid
			dataView_$gridID.onRowCountChanged.subscribe(function (e, args) {
				grid_$gridID.updateRowCount();
				grid_$gridID.render();
			});
			grid_$gridID.onCellChange.subscribe(function(e,args) {
                var cols = grid_$gridID.getColumns();
                var colfield = cols[args.cell].field;
                var row = args.row;
                var changes = {};
                changes[row] = {};
                changes[row][colfield] = 'grid_edit_sent';
                grid_$gridID.setCellCssStyles(colfield+args.item.id,changes);
                gridstyles_$gridID.push(colfield+args.item.id);
                jQuery.getJSON("$saveurl", { 'client': "$client", 'id' : args.item.id, 'col' : colfield, 'val' : args.item[colfield], 'a' : '$saveaction', 'key' : args.item['$ajax_keyfield'], 'extraid' : args.item['extraid'] || 0 }, function(json) {
                    if(json.complete)	{
                        changes[row][colfield] = 'grid_edit_complete';
                        grid_$gridID.removeCellCssStyles(colfield+args.item.id);
                        grid_$gridID.setCellCssStyles(colfield+args.item.id,changes);
                        gridstyles_$gridID.push(colfield+args.item.id);
                    }
                });
			});

            grid_$gridID.onValidationError.subscribe(function(e,args) {
                showMessage(args.validationResults.msg)
				Slick.GlobalEditorLock.cancelCurrentEdit();
                grid_$gridID.gotoCell(args.row, args.cell);
                grid_$gridID.resetActiveCell();
                highlightRow(args.row);
            });

			function filterEvent_$gridID(event, field) {
				Slick.GlobalEditorLock.cancelCurrentEdit();
				// clear on Esc
				if (event && event.which == 27) {
					field.value = "";
				}
				updateFilter_$gridID();
			}

			function applyGroupBy(dataView, grid, groupbyfield) {
				if(!groupbyfield) {
					return false;
				}
				var cols = grid.getColumns();
				var visibleColumns = [];
				for(var i=0, len= cols.length; i < len; i++){
					if(cols[i].field != groupbyfield) {
						visibleColumns.push(cols[i]);
					}
				}
				grid.setColumns(visibleColumns);
				dataView.groupBy(
					groupbyfield,
					function (g) {
						return '<span class = "grid_group_title">$groupby_fieldlabel:  ' + g.value + '</span>'
							+ (g.rows[0]['grouprow'] || '')
							+"  <span style='color:green'>(" + g.count + " $groupby_collection_name)</span>" ;
					},
					function (a, b) {
						return a.value- b.value;
					}
				);
			}

			dataView_$gridID.onPagingInfoChanged.subscribe(function (e, pagingInfo) { });

			dataView_$gridID.beginUpdate();
			dataView_$gridID.setItems(griddata);
			dataView_$gridID.setFilter(gridFilter);
			updateFilter_$gridID();
			applyGroupBy(dataView_$gridID, grid_$gridID,groupbyfield);
			dataView_$gridID.endUpdate();
			jQuery("#$gridID").show();
            grid_$gridID.autosizeColumns();
            grid_$gridID.updateRowCount();
            grid_$gridID.render();
			grid_$gridID.registerPlugin(new Slick.AutoTooltips());
			grid_$gridID.registerPlugin(checkboxSelector);
			jQuery(".slick-pager-settings-expanded").toggle();
		}
	~;
	$Data->{'AddToPage'}->add('js_bottom','inline',$js);

	return $body || '';
}

sub processFieldHeaders	{
	my ($headers) = @_;

	my @output_headers = ();
	my %headerInfo = ();
	for my $field (@{$headers})	{
		my $name = $field->{'name'};	
		if($field->{'type'} and $field->{'type'} eq 'Selector')	{
			$name = ' ';
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
			}
		}
		$row{'className'} = $field->{'class'} if $field->{'class'};
		$field->{'sorttype'} ||= '';
		$row{'type'} = 'num' if $field->{'sorttype'} eq 'number';
		$headerInfo{$fieldname} = \%row;
		push @output_headers, \%row;
	}

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

sub buildGrid {

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
