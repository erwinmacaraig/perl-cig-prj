package Flow_DisplayFields;

use lib '.', '..';

use strict;
use CGI qw(params);
use lib 'comp';

use Date::Calc;
use List::Util qw /min/;
use Utils;
use DBUtils;
use Data::Dumper;
use Log;

sub new {

  my $this   = shift;
  my $class  = ref($this) || $this;
  my %params = @_;
  my $self   = {};
  ##bless selfhash to class
  bless $self, $class;

    #Set Defaults
    $self->{'Data'}           = $params{'Data'};
    $self->{'Lang'}           = $params{'Lang'};
    $self->{'SystemConfig'}   = $params{'SystemConfig'};

    $self->{'Fields'}      = $params{'Fields'};
    $self->{'FieldMessages'}      = $params{'FieldMessages'};

    return $self;
}


sub build {
    my $self = shift;
    my ( 
        $permissions, 
        $action, 
        $notabs, 
        $hideBlank
     )
      = @_;
    my $returnstr   = '';
    my $sectionlist = $self->{'Fields'}->{'sections'};
    $sectionlist = [ [ 'main', '' ] ] if !$sectionlist;
    $action ||= 'display';
    $hideBlank ||= 0; #if action = display and no content in field - then hide

    my $tabs           = '';
    my %sections       = ();
    my %sectioncount   = ();
    my $txt_compulsory = $self->txt( 'Compulsory Field' );
    my $compulsory = qq[<span class="compulsory">*</span>];
    #my $compulsory = qq[];
    if($action eq 'display')    { $compulsory = ''; }
    return '' if !$self->{'Fields'};
    return '' if !$self->{'Fields'}->{'order'};
    my @fieldorder =@{ $self->{'Fields'}->{'order'} };
    my %clientside_validation = ();

    my $scripts = '';

    my %sectionHasCompulsory = ();
  FIELD: for my $fieldname (@fieldorder) {
        next if !$fieldname;
        my $f = $self->{'Fields'}->{'fields'}{$fieldname};
        next if !$f;
        my $type = $f->{'type'} || 'text';

        my $active = exists($f->{'active'}) ? $f->{'active'} : 1;
        my $sname = $f->{'sectionname'} || 'main';
        my $label = $self->txt( $f->{'label'} ) || $f->{'label'} || '';
        my $val        = defined $f->{'value'} ? $f->{'value'} : '';
        my $field_html = '';
        my $row_class = '';
        my $edit       = $action eq 'edit' ? 1 : 0;
        my $add        = $action eq 'add' ? 1 : 0;
        my $visible_for_add = exists $f->{'visible_for_add'} ? $f->{'visible_for_add'} : 1;
        my $visible_for_edit = exists $f->{'visible_for_edit'} ? $f->{'visible_for_edit'} : 1;

        next if $f->{'noadd'} and $add;

        #next if $f->{'noedit'} and $edit;
        next if $f->{'nodisplay'} and $action eq 'display';
        $f->{'readonly'} = 1 if ( $f->{'noedit'} and $edit );
        next if !$label;
        next if !$active;

        my $field_has_permission = ((
                not defined $permissions
                    or not scalar keys %$permissions
            )
                or (  defined $permissions
                    and $permissions->{$fieldname} )
                or ( defined $type and $type eq 'textblock' ) 
                or ( defined $type and $type eq 'htmlrow' ) 
                ? 1 : 0 );

        if (   ( $edit and not $visible_for_edit )
            or ( $add and not $visible_for_add )
            or not $field_has_permission )
        {
            next;
        }

        my $is_editable_field =
          ( $type eq 'hidden' or not $f->{'readonly'} or ($f->{'readonly'} and  $f->{'Save_readonly'})) ? 1 : 0;

        # Field Messages
        my $premessage = '';
        my $postmessage = '';
        my $infomessage = '';
        if ( ( $edit or $add ) and $is_editable_field ) {

            if($self->{'FieldMessages'} and $self->{'FieldMessages'}{$fieldname}) {
                my $ft =  $self->{'FieldMessages'}{$fieldname}{'type'} || 'info';
                my $val =  $self->{'FieldMessages'}{$fieldname}{'msg'} || '';
                $premessage = $val if $ft eq 'pre';
                $postmessage = $val if $ft eq 'post';
                $infomessage = $val if $ft eq 'info';
            }
            if($infomessage)    {
                $infomessage =~ s/"/&quote;/g;
                $infomessage = qq[<a tabindex="0" class="btn fields-info-btn" role="button" data-toggle="popover" data-placement="auto" data-trigger="focus" title="$label" data-content="$infomessage" data-container="body"></a>];
            }
            my $disabled =
              $f->{'disabled'} ? 'readonly class="HTdisabled"' : '';

            my $onChange = '';

            $scripts .= qq [ /* script for $fieldname */ \n$f->{'script'} ] if ($f->{'script'});

            if ( $type eq 'textblock' ) {
                $sections{$sname} .=
                  qq[ <tr id = "l_row_$fieldname"><td colspan="2">$fieldname</td></tr> ];
                next FIELD;
            }
            if ( $type eq 'textvalue' ) {
                $sections{$sname} .= qq[ <tr id = "l_row_$fieldname"><td colspan="2">$val</td></tr> ];
                next FIELD;
            }
            if ( $type eq 'header' ) {
                $sections{$sname} .= qq[ <tr id = "l_row_$fieldname"><th colspan="2">$label</th></tr> ];
                next FIELD;
            }
            if ( $type eq 'htmlrow' ) {
                $sections{$sname} .= $val || '';
                $clientside_validation{$fieldname}{'compulsory'} = 1 if $f->{'compulsory'};
                next FIELD;
            }
            if ( $type eq 'htmlblock' ) {
                if ( $f->{'nolabelsuffix'} ) {
                    $sections{$sname} .=
                      qq[<tr  id = "l_row_$fieldname"><td>&nbsp;</td><td colspan="2">$val</td></tr>];
                    next FIELD;
                }
                $field_html = $val;
            }
            elsif ( $type eq 'hidden' ) {
                $field_html =
                  qq[<input type="hidden" name="d_$fieldname" value="$val"/>\n];

                if ( ( $f->{addonly} and $f->{display} ) ) {
                    $field_html .= $f->{display};
                }
            }
            elsif ( $type eq 'textarea' ) {
                $row_class = 'form-textarea';
                my $rows = $f->{'rows'} ? qq[ rows = "$f->{'rows'}" ] : '';
                my $cols = $f->{'cols'} ? qq[ cols = "$f->{'cols'}" ] : '';
                $val =~ s/<br>/\n/ig;
                $field_html =
qq[<textarea name="d_$fieldname" id="l_$fieldname" $rows $cols $disabled $onChange>$val</textarea>\n];
            }
            elsif ( $type eq 'text' ) {
                $row_class = 'form-input-text';
                my $sz = $f->{'size'} ? qq[ size="$f->{'size'}" ] : '';
                my $ms =
                  $f->{'maxsize'} ? qq[ maxlength="$f->{'maxsize'}" ] : '';
                my $txt_format =
                  $f->{'format_txt'}
                  ? qq[ <span class="HTdateformat">$f->{'format_txt'}</span>]
                  : '';
                my $ph =
                  ( defined $f->{'placeholder'} )
                  ? qq[ placeholder="$f->{'placeholder'}" ]
                  : '';
                my $isReadonly = '';
                if ($f->{'Save_readonly'}){
                    $isReadonly = qq[ readonly = "readonly" ];
                }
                $val =~s/"/&quot;/g;
                $field_html =
qq[<input type="text" name="d_$fieldname" value="$val" $isReadonly id="l_$fieldname" $sz $ms $ph $disabled $onChange / >$txt_format\n];
            }
            elsif ( $type eq 'checkbox' ) {
                $row_class = 'form-checkbox';
                if ( $val eq '' and $f->{default} ) {
                    $val = $f->{default};
                }
                my $checked = ( $val and $val == 1 ) ? ' checked ' : '';
                $field_html =
qq[<input class="nb" type="checkbox" name="d_$fieldname" value="1" id="l_$fieldname" $checked $disabled $onChange / >\n];
            }
            elsif ( $type eq 'lookup' ) {
                $row_class = 'form-select';
                my $otheroptions = '';
                $otheroptions = qq[style="width:$f->{'width'}"]
                  if ( exists $f->{'width'} and $f->{'width'} );
                $field_html = $self->drop_down(
                    "$fieldname",      $f->{'options'},
                    $f->{'order'},       $f->{'value'},
                    $f->{'size'},        $f->{'multiple'},
                    $f->{'firstoption'}, $otheroptions,
                    $onChange,           $f->{'class'},
                    $f->{'disable'},
                );
            }
            elsif ( $type eq 'date' ) {
                my $adddatecsvalidation = $f->{'adddatecsvalidation'} || '';
                $row_class = 'form-select';
                $val = '' if $val eq '00/00/00';
                $val = '' if $val eq '00/00/0000';
                $val = '' if $val eq '0000-00-00';
                $val ||= '';
                my $datetype = $f->{'datetype'} || '';
                my $maxyear = $f->{'maxyear'} || '';
                my $minyear = $f->{'minyear'} || '';
                if ( $datetype eq 'dropdown' ) {
                    $field_html =
                      $self->_date_selection_dropdown( $fieldname, $val, $f,
                        $disabled, $onChange, $maxyear, $minyear, $adddatecsvalidation);
                }
                else {
                    $field_html =
                      $self->_date_selection_picker( $fieldname, $val, $f, $disabled,
                        $onChange );
                }
            }
            elsif ( $type eq 'time' ) {
                $row_class = 'form-select';
                $field_html =
                  $self->_time_selection_box( $fieldname, $val, $f, $disabled, 0,
                    $onChange );
            }
            elsif ( $type eq '_SPACE_' ) {
                $row_class = 'form-space';
                $field_html = '&nbsp;';
            }
            if ( ( $f->{'compulsory'} or $f->{'validate'} or $f->{'compulsoryIfVisible'})
                and $type ne 'hidden' )
            {
                $clientside_validation{$fieldname}{'compulsory'} =
                  $f->{'compulsory'};
                $clientside_validation{$fieldname}{'validate'} =
                  $f->{'validate'};
                $clientside_validation{$fieldname}{'compulsoryIfVisible'} =
                  $f->{'compulsoryIfVisible'};
                $clientside_validation{$fieldname}{'validateData'} =
                  $f->{'validateData'};
                $clientside_validation{$fieldname}{'adddatecsvalidation'} =
                  $f->{'adddatecsvalidation'};
            }
            $label = qq[$label] if $label;
        }
        else {
            if ( $type eq 'lookup' ) {
                $field_html = $self->txt($f->{'options'}{$val}) || "&nbsp;";
            }
            elsif ( $type eq 'htmlrow' ) {
                $sections{$sname} .= $val || '';
                next FIELD;
            }
            elsif ( $f->{'displaylookup'} ) {
                $field_html =
                  $self->txt( $f->{'displaylookup'}{$val} );
            }
            elsif ( $f->{'displayFunction'} ) {
                my @p = ();
                if( $f->{'displayFunctionParams'} ) {
                   @p =  @{$f->{'displayFunctionParams'}};
                }
                unshift @p, $val;
                $field_html = $f->{'displayFunction'}->(@p);
            }
            else {
                $val =~ s/\n/<br>/g;
                $val = '' if $val eq '00/00/00';
                $val = '' if $val eq '00/00/0000';
                $val = '' if $val eq '00/00/0000 00:00';
                $val = '' if $val eq '0000-00-00';
                $val = '' if $val eq '0000-00-00 00:00';
                $field_html = $val;
            }
            next FIELD if $val eq '';
            
        }

        if (    $self->{'Fields'}->{'options'}
            and $self->{'Fields'}->{'options'}{'labelsuffix'} )
        {
            $label .= $self->{'Fields'}->{'options'}{'labelsuffix'}
              if $f->{'label'} and !$f->{'nolabelsuffix'};
        }
        $label ||= '&nbsp;';
        $label = $compulsory.$label if $f->{'compulsory'} and $type ne 'hidden';
        if (    $self->{'Fields'}->{'options'}
            and $self->{'Fields'}->{'options'}{'hideblank'}
            and !$f->{'neverHideBlank'} )
        {
            next if !$field_html;
        }
        my $pretext  = $f->{'pretext'}  || '';
        my $posttext = $f->{'posttext'} || '';
        my $compulsory_replace =
            $f->{'compulsory'}
          ? $compulsory
          : '';
        $pretext = $premessage. $pretext;
        $posttext = $postmessage. $posttext;
        $pretext =~ s /XXXCOMPULSORYICONXXX/$compulsory_replace/g;
        $posttext =~ s /XXXCOMPULSORYICONXXX/$compulsory_replace/g;

        if ($f->{'compulsory'}) {
            $row_class = join(' ', $row_class, 'required');
            $sectionHasCompulsory{$sname} = 1;
        }

        if (
            $self->{'Fields'}->{'options'}{'verticalform'}
            or (    $self->{'Fields'}->{'options'}{'verticalformedit'}
                and $action ne 'display' )
          )
        {
            $sections{$sname} .= qq[
            <tr class="$row_class"><td class="label HTvertform-l" colspan="2">$label</td></tr>
            <tr><td class="value HTvertform-v" colspan="3">$pretext$field_html$infomessage$posttext</td> </tr>
            ];
        }
        else {
            $sectioncount{$sname}++;
            my $rowcount =
              ( $sectioncount{$sname} % 2 ) ? 'HTr_odd' : 'HTr_even';
            if($f->{'swapLabels'})  {
                $sections{$sname} .= qq[
                <div class="form-group" id = "l_row_$fieldname">
                    <div class="col-md-4 txtright">$pretext$field_html$infomessage$posttext</div>
                    <label class="col-md-6 control-label" for="l_$fieldname">$label</label>
                </div>
                ];
            }
            else    {
                $sections{$sname} .= qq[
                <div class="form-group" id = "l_row_$fieldname">
                    <label class="col-md-4 control-label txtright" for="l_$fieldname">$label</label>
                    <div class="col-md-6">$pretext$field_html$infomessage$posttext</div>
                </div>
                ];
            }
        }
    }

    my %usedsections = ();
    for my $s ( @{$sectionlist} ) {

        my $sectionheader = $self->{'Data'}->{'lang'}->txt($self->txt( $s->[1] )) || '';
        my $requiredfield = $self->txt('Required fields') || '';
        my $ROSectionclass = '';
        if($action eq 'display')    {
            $requiredfield = ''; 
            $ROSectionclass = 'fieldSectionGroupWrapper-DisplayOnly';
        }

        if ( $sections{ $s->[0] } ) {
        #if ( $sections{ $s->[0] } or $s->[4] ) {
            next if $s->[2] and not $self->display_section( $s->[2] );
            my $extraclass = $s->[3] || '';
            my $footer = $s->[4] || '';
            $usedsections{ $s->[0] } = 1;
            if ($notabs) {
                my $sh = '';
                if ( $sectionheader ) {
                    $sh = qq[ <h3 class="panel-header sectionheader">$sectionheader</h3>];
                }
                my $compulsory_string = '';
                if($sectionHasCompulsory{$s->[0]})   {
                    $compulsory_string = '<p><span class="notice-error">'.$compulsory.$requiredfield.'</span></p>';
                }
                $returnstr .= qq[
                    <div class = "fieldSectionGroupWrapper $ROSectionclass" id = "fsgw-].$s->[0].qq[">
                    $sh<div class = "panel-body fieldSectionGroup $extraclass" id = "fsg-].$s->[0].qq["><fieldset>$compulsory_string].$sections{ $s->[0] }.qq[</fieldset>$footer</div></div>];
            }
            else {
                #my $style=$s ? 'style="display:none;" ' : '';
                my $sh = q{};
                if ( $s->[1] ) {
                    $sh = qq[ <tr><th colspan="2" class="sectionheader $extraclass">$sectionheader</th></tr>];
                }
                $tabs .= qq[<li><a id="a_sec$s->[0]" class="tab_links" href="#sec$s->[0]">$sectionheader</a></li>];

                $returnstr .= qq~
                <tbody id="sec$s->[0]" class="new_tab">
                $sh
                $sections{$s->[0]}
                </tbody>
                ~;
            }
        }
    }
    if(!scalar(@{$sectionlist}))    {
        $returnstr = qq[ <fieldset> $returnstr </fieldset> ];
    }
    my $tableinfo = $self->{'Fields'}->{'options'}{'tableinfo'} || ' class = "HTF_table" ';
    if ($returnstr) {
        my $validation =
          $self->generate_clientside_validation( \%clientside_validation);

        $returnstr = qq[
            $validation
            $returnstr
            <script type="text/javascript">
            $scripts
            </script>
        ];
    }
    my $html_head_init = $self->_date_selection_picker_init();
    return wantarray
        ?( $returnstr, \%usedsections, $html_head_init, $tabs )
        : $returnstr;
}

sub display_section {
    my $self = shift;
    my ( $rule) = @_;

    foreach my $field ( keys %{ $self->{'Fields'}->{fields} } ) {
        $rule =~ s/$field/"$self->{'Fields'}->{fields}{$field}{value}"/g;
    }

    return eval($rule);
}

sub drop_down {
    my $self = shift;
    my (
        $name ,
        $options_ref,
        $order_ref,
        $default,
        $size,
        $multi,
        $pre,
        $otheroptions,
        $onChange,
        $class,
        $disabled,
    ) = @_;
    #DEBUG "genereate dropdown for $name";
    return '' if ( !$name or !$options_ref );
    if ( !defined $default ) { $default = ''; }
    $multi        ||= '';
    $size         ||= 1;
    $otheroptions ||= '';
    $onChange     ||= '';
    $class        ||= '';

    $disabled = $disabled ? 'disabled="disabled"': '';
    if ( !$order_ref ) {
        #Make sure the order array is set up if not already passed in
        my @order = ();
        for my $option (
            sort { $options_ref->{$a} cmp $options_ref->{$b} }
            keys %{$options_ref}
          )
        {
            push @order, $option;
        }
        $order_ref = \@order;
    }
    if ( $multi and $default =~ /\0/ ) {
        my @d = split /\0/, $default;
        $default = \@d;
    }

    my $subBody = '';
    for my $val ( @{$order_ref} ) {
        if($val =~/optgroup/){
            $subBody .=qq[ <$val>];
            next;
        }
        my $selected = '';
        if ( ref $default ) {
            for my $v ( @{$default} ) {
                $selected = 'SELECTED'
                  if $val eq $v;
            }
        }
        else { $selected = 'SELECTED' if $val eq $default; }
        $subBody .=
          qq[ <option $selected value="$val">].$self->txt($options_ref->{$val}).qq[</option>];
    }
    $multi = ' multiple ' if $multi;
    $size = min($size, scalar (keys %$options_ref) + 1);
    my $preoption =
      ( $pre and not $multi )
      ? qq{<option value="$pre->[0]">$pre->[1]</option>}
      : '';
    my $placeholder_text = $multi
        ? $self->txt('Select some options')
        : $self->txt('Select an option');
    $subBody = qq[
    <select name="d_$name" id="l_$name" size="$size" data-placeholder = "$placeholder_text" class = "$class" $multi $otheroptions $onChange $disabled>
    $preoption
    $subBody
    </select>
    ];
    return $subBody;
}

sub gather    {
    my $self = shift;
    my ( 
        $params, 
        $permissions, 
        $option 
    ) = @_;

    my @problems   = ();
    my @fieldorder = @{ $self->{'Fields'}->{'order'} };
    my %outputdata = ();
    $permissions = undef if($permissions and !scalar(keys %{$permissions}));
    for my $fieldname (@fieldorder) {
        my $fieldvalue = '';
        my $name = "d_$fieldname";
        my $fv   = $self->{'Fields'}->{'fields'}{$fieldname};
        $fv->{'old_value'} = $fv->{'value'};
        my $active = exists($self->{'Fields'}->{'fields'}{$fieldname}{'active'}) ? $self->{'Fields'}->{'fields'}{$fieldname}{'active'} : 1;

        next if $self->{'Fields'}->{'fields'}{$fieldname}{'type'} eq 'htmlrow';
        next if $self->{'Fields'}->{'fields'}{$fieldname}{'SkipProcessing'};
        next if !$active;
        next if ( $permissions and !$permissions->{$fieldname} );
        if($option eq 'add')    {
            next if $self->{'Fields'}->{'fields'}{$fieldname}{'SkipAddProcessing'};
        }
        if($option eq 'edit')    {
            next if $self->{'Fields'}->{'fields'}{$fieldname}{'SkipEditProcessing'};
            next if $self->{'Fields'}->{'fields'}{$fieldname}{'noedit'};
        }
        #Update the form display
        if ( exists $params->{$name}
            and $fv->{'type'} ne 'htmlblock' )
        {
            $fieldvalue = $params->{$name};
        }

     #Handle the checkboxes - Data doesn't get sent if checkboxes aren't checked
        if (
            $fv->{'type'} eq 'checkbox'
            and !exists $params->{$name}
            and
            ( !$permissions or ( $permissions and $permissions->{$fieldname} ) )
            and ( !exists $fv->{'readonly'} or !$fv->{'readonly'} )
          )
        {
            $fieldvalue = 0;
        }

        if (
            ( $self->{'Fields'}->{'fields'}{$fieldname}{'type'} eq 'date' )
            or (    $self->{'Fields'}->{'fields'}{$fieldname}{'type'} eq 'hidden'
                and $self->{'Fields'}->{'fields'}{$fieldname}{'validate'} eq 'DATE' )
          )
        {

            if (
                not $self->{'Fields'}->{'fields'}{$fieldname}{'datetype'}
                or (    $self->{'Fields'}->{'fields'}{$fieldname}{'datetype'}
                    and $self->{'Fields'}->{'fields'}{$fieldname}{'datetype'} ne
                    'box' )
              )
            {

                if (    defined $params->{ $name . '_day' }
                    and defined $params->{ $name . '_mon' }
                    and defined $params->{ $name . '_year' } )
                {

                    my $d = $params->{ $name . '_day' }  || q{};
                    my $m = $params->{ $name . '_mon' }  || q{};
                    my $y = $params->{ $name . '_year' } || q{};

                    $params->{$name} = '0000-00-00' unless ( $d or $m or $y );

                    if ( $d and $m and $y ) {
                        $fieldvalue = "$d/$m/$y";
                        $fieldvalue = $params->{$name} = $self->_fix_date($fieldvalue);
                    }
                }
            }
        }

        if ( $self->{'Fields'}->{'fields'}{$fieldname}{'type'} eq 'time' ) {
            my $h = $params->{ $name . '_h' } || '';
            my $m = $params->{ $name . '_m' } || '';
            my $s = $params->{ $name . '_s' } || '';
            $h = "0$h" if length $h < 2;
            $m = "0$m" if length $m < 2;
            $s = "0$s" if length $s < 2;
            if ( $h or $m ) {
                $params->{$name} = "$h:$m:$s";
                $fieldvalue = $params->{$name};
            }
        }

        if (
            $fv->{'compulsory'}
            and (  !exists $params->{$name}
                or !defined $params->{$name}
                or $params->{$name} eq ''
                or $params->{$name} =~ /^\s*$/
                or $params->{$name} eq '0000-00-00' )
          )
        {
            next if ( $fv->{'noedit'} and $option eq 'edit' );
            next if ( $fv->{'noadd'}  and $option eq 'add' );
            next if $fv->{'readonly'};
            next if ( $permissions    and !$permissions->{$fieldname} );
            if($fv->{'label'})  {
                push @problems, $fv->{'label'} . ' : ' . $self->txt('Required');
            }
            next;
        }
        if (    $fv->{'validate'}
            and exists $params->{$name}
            and $params->{$name} ne '' )
        {
            my $errs =
              $self->_validate( $fv->{'validate'}, $params->{$name} );
            for my $err ( @{$errs} ) {
                push @problems, $fv->{'label'} . ' : ' . $err;
            }
        }
        $fieldvalue =~ s/</&lt;/g if $self->{'Fields'}->{'options'}{'NoHTML'};
        $fieldvalue =~ s/>/&gt;/g if $self->{'Fields'}->{'options'}{'NoHTML'};
        if (
            exists $self->{'Fields'}->{'fieldtransform'}{'textcase'}{$fieldname} )
        {
            my $field_case = $self->{'Fields'}->{'fieldtransform'}{'textcase'}{$fieldname} || '';
            $fieldvalue = $self->apply_case_rule( $fieldvalue, $field_case ) if $field_case;
        }

        $outputdata{$fieldname} = $fieldvalue;
    }

    return (\%outputdata, \@problems);
}

sub _validate {
    my $self = shift;
    my ( $type, $val ) = @_;

    my @errors = ();
    for my $t ( split /\s*,\s*/, $type ) {
        my ($param) = $t =~ /:(.*)/;
        $t =~ s/:.*//g;
        my ( $num1, $num2 ) = ( '', '' );
        if ($param) {
            ( $num1, $num2 ) = split /\~/, $param;
        }

        if ( $t eq 'NUMBER' ) {
            push @errors, $self->txt( 'is not a valid number' )
              if $val !~ /^\d+$/;
        }
        if ( $t eq 'FLOAT' ) {
            push @errors, $self->txt( 'is not a valid number' )
              if $val !~ /^[\d\.]+$/;
        }
        elsif ( $t eq 'NOSPACE' ) {
            push @errors, $self->txt( 'cannot have spaces' )
              if $val =~ /\s/;
        }
        elsif ( $t eq 'NOHTML' ) {
            push @errors, $self->txt( 'cannot contain HTML' )
              if $val =~ /[<>]/;
        }
        elsif ( $t eq 'DATE' ) {
            push @errors, $self->txt( 'is not a valid date' )
              if !$self->check_valid_date($val);
        }
        elsif ( $t eq 'MORETHAN' ) {
            push @errors,
              $self->txt( "is not more than [_1]", $num1 )
              if $val <= $num1;
        }
        elsif ( $t eq 'MORETHANEQUAL' ) {
            push @errors,
              $self->txt( "is not more than or equal to [_1]",
                $num1 )
              if $val < $num1;
        }
        elsif ( $t eq 'LESSTHAN' ) {
            push @errors,
              $self->txt( "is not less than [_1]", $num1 )
              if $val >= $num1;
        }
        elsif ( $t eq 'LESSTHANEQUAL' ) {
            push @errors,
              $self->txt( "is not less than or equal to [_1]",
                $num1 )
              if $val > $num1;
        }
        elsif ( $t eq 'BETWEEN' ) {
            push @errors,
              $self->txt( "is not between [_1] and [_2]",
                $num1, $num2 )
              if ( $val < $num1 or $val > $num2 );
        }
        elsif ( $t eq 'LENGTH' ) {
            push @errors,
              $self->txt( "must be [_1] characters long", $num1 )
              if length($val) != $num1;
        }
        elsif ( $t eq 'EMAIL' ) {
            require Mail::RFC822::Address;
            my @emails = split /;/, $val;
            foreach (@emails) {
                push @errors,
                  $self->txt( 'is not a valid email address' )
                  if !Mail::RFC822::Address::valid($_);
            }
        }
        elsif( $t eq 'SS_DATEMORETHAN') {
            my($year_before,$month_before,$day_before) = $num1 =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
            my($year_ahead,$month_ahead,$day_ahead) = $val =~/(\d\d\d\d)-(\d{1,2})-(\d{1,2})/;
            my $deltaDays = -1;

            if($val and $num1) {
                my $validLoanStart = Date::Calc::check_date( $year_before, $month_before, $day_before );
                my $validLoanEnd = Date::Calc::check_date( $year_ahead, $month_ahead, $day_ahead );

                if($validLoanStart and $validLoanEnd) {
                    $deltaDays = Date::Calc::Delta_Days($year_before, $month_before, $day_before, $year_ahead, $month_ahead, $day_ahead);
                }
            }
            else {
                return;
            }

            push @errors,
              $self->txt( "is not more than [_1]", $num1 )
              if ($deltaDays <= 0);
        }
    }

    return ( \@errors );
}

sub apply_case_rule {
    my $self = shift;
    my ( $text, $case ) = @_;

    return $text if $case !~ /Lower|Upper|Title|Sentence/;

    my $new_text = '';
    if ( $case eq 'Lower' ) {
        $new_text = lc($text);
    }
    elsif ( $case eq 'Upper' ) {
        $new_text = uc($text);
    }
    elsif ( $case eq 'Title' ) {
        if ( $text eq uc($text) or $text eq lc($text) ) {
            $new_text = lc($text);
            $new_text = ucfirst($new_text);
            $new_text =~ s/(\w+)/\u$1/g;
            $new_text =~ s/([ \-'\(])/\u$1/g;
            $new_text =~ s/('S)/\L$1/g;
            $new_text =~ s/\s+$//;
        }
        else {
            $new_text = $text;
        }
    }
    else {
        $new_text = lc($text);
        $new_text = ucfirst($new_text);
    }

    return $new_text;

}

sub _fix_date {
    my $self = shift;
    my ( $date, %extra ) = @_;
    return '' if !$date;
    return '0000-00-00' if ( $date eq '0000-00-00' || $date eq '00/00/0000' );
    if ( exists $extra{NODAY} and $extra{NODAY} ) {
        my ( $mm, $yyyy ) = $date =~ m:(\d+)/(\d+):;
        if ( !$mm or !$yyyy ) {
            return ( $self->txt( "Invalid Date" ), '' );
        }
        if    ( $yyyy < 10 )  { $yyyy += 2000; }
        elsif ( $yyyy < 100 ) { $yyyy += 1900; }
        return "$yyyy-$mm-01";
    }
    my ( $dd, $mm, $yyyy ) = $date =~ m:(\d+)/(\d+)/(\d+):;
    if ( !$dd or !$mm or !$yyyy ) {
        return ( $self->txt( "Invalid Date" ), '' );
    }
    if    ( $mm < 10 )  { $mm = "0$mm"; }
    if    ( $dd < 10 )  { $dd = "0$dd"; }
    if    ( $yyyy < 10 )  { $yyyy += 2000; }
    elsif ( $yyyy < 100 ) { $yyyy += 1900; }
    return "$yyyy-$mm-$dd";
}

sub check_valid_date {
    my $self = shift;
    my ($date) = @_;
    return 1 if $date eq '0000-00-00';
    return 1 if $date eq '00/00/0000';
    my ( $y, $m, $d ) = split /\-/, $date;
    return Date::Calc::check_date( $y, $m, $d );
}

sub txt {
    my $self = shift;
    my $key        = shift;
    return '' if !$key;

    my %Lexicon = (
        'AUTO_INTROTEXT' =>
qq[To modify this information change the information in the boxes below and when you have finished press the <strong>'[_1]'</strong> button.<br><span class="intro-subtext"><strong>Note:</strong> All boxes marked with a [_2] are compulsory and must be filled in.</span>],
        'Required fields'            => 'Required fields',
        'Compulsory Field'            => 'Compulsory Field',
        'Invalid Date'                => 'Invalid Date',
        'Record added successfully'   => 'Record added successfully',
        'Database Error in Addition'  => 'Database Error in Addition',
        'Record updated successfully' => 'Record updated successfully',
        'Database Error in Update'    => 'Database Error in Update',
        'Problems'                    => 'Problems',
        'The following fields are compulsory and need to be filled in' =>
          'The following fields are compulsory and need to be filled in',
        'is not a valid number' => 'is not a valid number',
        'cannot have spaces'    => 'cannot have spaces',
        'cannot contain HTML'   => 'cannot contain HTML',
        'is not a valid date'   => 'is not a valid date',
        "is not more than [_1]" => "is not more than [_1]",
        "is not more than or equal to [_1]" =>
          "is not more than or equal to [_1]",
        "is not less than [_1]" => "is not less than [_1]",
        "is not less than or equal to [_1]" =>
          "is not less than or equal to [_1]",
        "is not between [_1] and [_2]" => "is not between [_1] and [_2]",
        "must be [_1] characters long" => "must be [_1] characters long",
        'is not a valid email address' => 'is not a valid email address',
    );

    my $txt = q{};
    if ($self->{'Lang'}) {

        $txt = $self->{'Lang'}->txt(
            $key,
            (
                map {
                    $self->{'Lang'}->txt($_)
                      || $_
                } @_
            )
        );

        $txt ||= q{};

    }
    if ( !$txt and exists $Lexicon{$key} ) {
        $txt = $Lexicon{$key} || '';

        #Check for replacements
        my @matches = $txt =~ /\[[_\d]+\]/g;
        my $num     = scalar @matches;
        for my $n ( 1 .. $num ) {
            $txt =~ s/\[_$n\]/$_[$n-1]/;
        }
    }
    $txt = $key if !$txt;
    return $txt;
}

sub _time_selection_box {
    my $self = shift;
    my ( $fieldname, $val, $f, $otherinfo, $showblank, $onChange ) = @_;
    $showblank ||= 0;
    $otherinfo ||= '';
    $val       ||= '';
    my ( $val_h, $val_m, $val_s ) = split /:/, $val;
    $val_h ||= '';
    $val_m ||= '';
    $val_s ||= '';
    my $hours = '';
    my $mins  = '';
    my $secs  = '';
    $val_h = '0' . $val_h if length($val_h) == 1;
    $val_m = '0' . $val_m if length($val_m) == 1;
    $val_s = '0' . $val_s if length($val_s) == 1;

    for my $j ( 0 .. 23 ) {
        $j = '0' . $j if $j < 10;
        my $selected = $j eq $val_h ? ' SELECTED ' : '';
        $hours .= qq[<option value="$j" $selected>$j</option>];
    }
    for my $j ( 0 .. 59 ) {
        $j = '0' . $j if $j < 10;
        my $selected = $j eq $val_m ? ' SELECTED ' : '';
        $mins .= qq[<option value="$j" $selected>$j</option>];
    }
    for my $j ( 0 .. 59 ) {
        $j = '0' . $j if $j < 10;
        my $selected = $j eq $val_s ? ' SELECTED ' : '';
        $secs .= qq[<option value="$j" $selected>$j</option>];
    }
    if ($showblank) {
        $mins  = qq[<option value=""> </option>] . $mins;
        $hours = qq[<option value=""> </option>] . $hours;
        $secs  = qq[<option value=""> </option>] . $secs;
    }
    my $field_html = qq[
    <select name="d_$fieldname]
      . qq[_h" style="vertical-align:middle" $otherinfo $onChange>$hours</select>:
    <select name="d_$fieldname]
      . qq[_m" style="vertical-align:middle" $otherinfo $onChange>$mins</select>
    <span class="HTdateformat">24 hour time</span>
    ];
    return $field_html;
}

sub _date_selection_dropdown {
    my $self = shift;
    my ( $fieldname, $val, $f, $otherinfo, $onChange, $maxyear, $minyear, $addcsvalidation) = @_;
    my ( $onBlur, $onMouseOut );
    if ($onChange) {
        ( $onBlur = $onChange ) =~
s/onChange=(['"])(.*)\1/onBlur=$1 alert(changed_$fieldname); alert('Hola'); if (changed_$fieldname==1) { $2 } $1/i;
        ( $onMouseOut = $onChange ) =~
s/onChange=(['"])(.*)\1/onMouseOut=$1 if (changed_$fieldname==1) { $2 } $1/i;
    }
    $onBlur     ||= '';
    $onMouseOut ||= '';

    $otherinfo ||= '';

    my %days = map { $_ => $_ } ( 1 .. 31 );
    $days{0} = $self->txt('Day');

    my %months = (
        0  => $self->txt('Month'),
        1  => $self->txt('Jan'),
        2  => $self->txt('Feb'),
        3  => $self->txt('Mar'),
        4  => $self->txt('Apr'),
        5  => $self->txt('May'),
        6  => $self->txt('Jun'),
        7  => $self->txt('Jul'),
        8  => $self->txt('Aug'),
        9  => $self->txt('Sep'),
        10 => $self->txt('Oct'),
        11 => $self->txt('Nov'),
        12 => $self->txt('Dec'),
    );
    $maxyear ||= (localtime)[5] + 1900 + 5;
    $minyear ||= 1900;
    my %years = map { $_ => $_ } ( $minyear .. $maxyear );
    $years{0} = $self->txt('Year');

    $val ||= '';
    my ( $val_y, $val_m, $val_d ) = split /\-/, $val;
    if ( !$val_d and $val =~ /\// ) {
        ( $val_d, $val_m, $val_y ) = split /\//, $val;
    }
    $val_d ||= '';
    $val_m ||= '';
    $val_y ||= '';
    $val_d =~ s/^0//;
    $val_m =~ s/^0//;

    my @order_d = ( 0 .. 31 );
    my @order_m = ( 0 .. 12 );
    my @order_y = reverse( $minyear .. $maxyear );
    unshift( @order_y, 0 );

    my $otherinfo_d =
      $otherinfo
      . qq[ id="l_d_$fieldname" onFocus="changed_temp_$fieldname=changed_$fieldname; changed_$fieldname=0;" onChange="changed_temp_$fieldname=1;" onBlur="changed_$fieldname=changed_temp_$fieldname; alert(changed_$fieldname);" ]
      if ($onChange);
    my $otherinfo_m =
      $otherinfo
      . qq[ id="l_m_$fieldname" onFocus="changed_temp_$fieldname=changed_$fieldname; changed_$fieldname=0;" onChange="changed_temp_$fieldname=1;" onBlur="changed_$fieldname=changed_temp_$fieldname; alert(changed_$fieldname);" ]
      if ($onChange);
    my $otherinfo_y =
      $otherinfo
      . qq[ id="l_y_$fieldname" onFocus="changed_temp_$fieldname=changed_$fieldname; changed_$fieldname=0;" onChange="changed_temp_$fieldname=1;" onBlur="changed_$fieldname=changed_temp_$fieldname; alert(changed_$fieldname);" ]
      if ($onChange);

    my $daysfield =
      $self->drop_down( "${fieldname}_day", \%days, \@order_d, $val_d, 1, 0, '', $otherinfo_d,'','df_date_day chzn-select' );
    my $monthsfield =
      $self->drop_down( "${fieldname}_mon", \%months, \@order_m, $val_m, 1, 0, '',
        $otherinfo_m ,'','df_date_month chzn-select');
    my $yearsfield =
      $self->drop_down( "${fieldname}_year", \%years, \@order_y, $val_y, 1, 0, '',
        $otherinfo_y ,'','df_date_year chzn-select');

    my $field_html =
qq[ <span $onMouseOut> <script language="JavaScript1.2">var changed_$fieldname=0; var changed_temp_$fieldname=0</script> ];
    $field_html .= $daysfield;
    $field_html .= $monthsfield;
    $field_html .= $yearsfield;

    my $datecsvalidation = '';
    if($addcsvalidation) {
        my $hidden_validator_name = 'd_' . $fieldname . '_dummyvalidator';
        $datecsvalidation = qq[ <input class="dummyvalidation" type="hidden" value="$val" name="$hidden_validator_name" />];
    }

    $field_html = qq[ <div class = "dateselection-group">$field_html </div> $datecsvalidation];
    return $field_html;
}

sub _date_selection_picker {
    my $self = shift;

    #my($name, $value) = @_;
    my ( $name, $value, $f, $otherinfo, $onChange ) = @_;
    my $fieldsref=$self->{'Fields'};
    my ( $date, $time ) = split( ' ', $value );
    $value = join( '/', reverse( split( '-', $date ) ) ) if $date;
    my $readonly ='';
    
    my @datepicker_options = (
        qq[dateFormat: 'yy-mm-dd'],
        qq[showButtonPanel: true],
    );
    
    # Date to and from restrictions
    # used when we have two date fields and we want to link them together
    if ($f->{'datepicker_options'}->{'link_min_field'}){
        # enforce our maximum date restriction on the min field
        my $min = $f->{'datepicker_options'}->{'link_min_field'};
        push @datepicker_options, qq[ 
            onClose: function( selectedDate ) {
                \$( "#l_$min" ).datepicker( "option", "maxDate", selectedDate );
            }
        ];
    }
    elsif ($f->{'datepicker_options'}->{'link_max_field'}){
        # enforce our minimum date restriction on the max field
        my $max = $f->{'datepicker_options'}->{'link_max_field'};
        push @datepicker_options, qq[ 
            onClose: function( selectedDate ) {
                \$( "#l_$max" ).datepicker( "option", "minDate", selectedDate );
            }
        ];
    }
    
    # Max and min date values
    if ($f->{'datepicker_options'}->{'min_date'}){
        # enforce our maximum date restriction on the min field
        my $min = $f->{'datepicker_options'}->{'min_date'};
        if ( $min =~ /(\d{4})-(\d{1,2})-(\d{1,2})/ ){
            $min = "$3/$2/$1";
        }
        push @datepicker_options, qq[minDate: '$min'] unless ($min eq '0000-00-00');
    }
    
    if ($f->{'datepicker_options'}->{'max_date'}){
        # enforce our maximum date restriction on the min field
        my $max = $f->{'datepicker_options'}->{'max_date'};
        if ( $max =~ /(\d{4})-(\d{1,2})-(\d{1,2})/ ){
            $max = "$3/$2/$1";
        }
        push @datepicker_options, qq[maxDate: '$max'] unless ($max eq '0000-00-00');
    }
    
    # Prevent user input, as this might be outside our date range
    # done in javascript, as if they load without javascript, will not lock
    # them out of editing this field
    if ( $f->{'datepicker_options'}->{'prevent_user_input'}){
        $readonly = qq[\$('#l_$name').attr("readonly", true)];
    }

    my $datepicker_options_string = join(",\n", @datepicker_options) || '';

    my $js = qq[
    <script type="text/javascript">
    jQuery().ready(function() {
            jQuery("#l_$name").datepicker({
                    $datepicker_options_string
                });
            $readonly
        });
    </script>
    ];

    my $field_html = qq[
    $js
    <input type="text" name="d_$name" value="$value" id="l_$name" size="12" class="datepicker">
    ];

    return $field_html;
}

sub _date_selection_picker_init {
    my $self = shift;

    my $jsurl = $self->{'Fields'}->{'options'}{'jsURL'} || 'js/';

    my @picker_fields = ();
    for my $fieldname ( @{ $self->{'Fields'}->{'order'} } ) {
        next if !$fieldname;
        my $f = $self->{'Fields'}->{'fields'}{$fieldname};
        next if !$f;
        my $type = $f->{'type'} || '';
        if ( $type eq 'date' ) {
            push @picker_fields, $fieldname
              if ( exists $f->{'datetype'} and $f->{'datetype'} eq 'picker' );
        }
    }

    return '' if !@picker_fields;
}

sub generate_clientside_validation {
    my $self = shift;
    my ( $validation ) = @_;
    
    my $field_prefix = 'd_';
    my $form_suffix = 'ID';
    
    if (defined $self->{'Fields'}->{'options'}{'field_prefix'}){
        $field_prefix = $self->{'Fields'}->{'options'}{'field_prefix'};
    }
    if (defined $self->{'Fields'}->{'options'}{'form_suffix'}){
        $form_suffix = $self->{'Fields'}->{'options'}{'form_suffix'};
    }
    
    my $formname = $self->{'Fields'}->{'options'}{'formname'} || 'flowForm';
    my $tab_div_id = $self->{'Fields'}->{'options'}{'tab_div_id'} ||'new_tabs_wrap';
    my $tab_class  = $self->{'Fields'}->{'options'}{'tab_class'}  || 'new_tab';
    my $tab_style  = $self->{'Fields'}->{'options'}{'tab_style'}  || 'none';
    
    my $body = '';

    my $messages = '';

    my %valinfo = ();
    my $remote_updates = '';

    my $dummy_validator = '';
    for my $k ( keys %{$validation} ) {
        if ( $validation->{$k}{'compulsory'} ) {
            $valinfo{'rules'}{ $field_prefix . $k }{'required'} = 'true';
            $valinfo{'messages'}{ $field_prefix . $k }{'required'} =
              $self->txt("Field required");
        }
        if ( $validation->{$k}{'compulsoryIfVisible'} ) {
            $valinfo{'rules'}{ $field_prefix . $k }{'required'} = qq[JAVASCRIPTfunction(element){if(jQuery('#].$validation->{$k}{'compulsoryIfVisible'}.qq[').is(SINGLEQUOTE:visibleSINGLEQUOTE)){return true;} return false;}JAVASCRIPT];
            $valinfo{'messages'}{ $field_prefix . $k }{'required'} =
              $self->txt("Field required");
        }
        if ( $validation->{$k}{'adddatecsvalidation'} and $validation->{$k}{'compulsory'}) {
            $valinfo{'rules'}{ $field_prefix . $k . '_dummyvalidator'}{'required'} = 'true';
            $valinfo{'messages'}{ $field_prefix . $k . '_dummyvalidator' }{'required'} =
              $self->txt("Field required");
        }
        if ( $validation->{$k}{'validate'} ) {
            for my $t ( split /\s*,\s*/, $validation->{$k}{'validate'} ) {
                my ($param) = $t =~ /:(.*)/;
                $t =~ s/:.*//g;
                my ( $num1, $num2 ) = ( '', '' );
                if ($param) {
                    ( $num1, $num2 ) = split /~/, $param;
                }
                if ( $t eq 'LENGTH' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'minlength'} = $num1;
                    $valinfo{'messages'}{ $field_prefix . $k }{'minlength'} =
                      $self->txt("This must be [_1] characters long", $num1);
                }
                elsif ( $t eq 'EMAIL' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'email'} = 'true';
                    $valinfo{'messages'}{ $field_prefix . $k }{'email'} =
                      $self->txt("Please enter a valid email address");
                }
                elsif ( $t eq 'BETWEEN' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'range'} =
                      [ $num1, $num2 ];
                    $valinfo{'messages'}{ $field_prefix . $k }{'range'} =
                      $self->txt("Please enter a value between [_1] and [_2]", $num1, $num2 );
                }
                elsif ( $t eq 'NUMBER' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'digits'} = 'true';
                    $valinfo{'messages'}{ $field_prefix . $k }{'digits'} =
                      $self->txt("Please enter only digits");
                }
                elsif ( $t eq 'FLOAT' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'number'} = 'true';
                    $valinfo{'messages'}{ $field_prefix . $k }{'number'} =
                      $self->txt("Please enter a valid number",
                        $num1, $num2 );
                }
                elsif ( $t eq 'URL' ) {
                    $valinfo{'rules'}{ $field_prefix . $k }{'url'} = 'true';
                    $valinfo{'messages'}{ $field_prefix . $k }{'url'} =
                      $self->txt("Please enter a valid URL");
                }
                elsif ( $t eq 'REMOTE' ) {
                    my $vdata = $validation->{$k}{'validateData'} || next;
                    my %remote_data = ();
                    my $otherfields =  $vdata->{'otherfields'} || [];
                    push @{$otherfields}, $k;
                    for my $f (@{$otherfields})    {
                        $remote_data{$f} = "REMOVEQfunction() { return jQuery('#l_$f' ).val(); }REMOVEQ";
                        $remote_updates .= qq[jQuery('#l_$f' ).on('change',function() { jQuery('#l_$k').removeData("previousValue");jQuery("#$formname$form_suffix").validate().element('#l_$k');}); ];
                    }
                    foreach my $k (keys %{$vdata->{'postvalues'}})    {
                        $remote_data{$k} = $vdata->{'postvalues'}{$k} || 0;
                    }

                    $valinfo{'rules'}{ 'd_' . $k }{'remote'} = {
                            url => $vdata->{'url'},
                            type => "post",
                            data => \%remote_data,
                    };
                    $valinfo{'messages'}{ 'd_' . $k }{'remote'} =
                      $self->txt("Number is invalid", $num1, $num2 );
                }
                elsif ($t eq 'DATE') {
                    my $fdtday = 'l_' . $k . '_day';
                    my $fdtmon = 'l_' . $k . '_mon';
                    my $fdtyear = 'l_' . $k . '_year';

                    my $targetfield = $field_prefix . $k;
                    my $targetdummyfield = $field_prefix . $k . '_dummyvalidator';

                    $dummy_validator .= qq [
                        jQuery('#$fdtday, #$fdtmon, #$fdtyear').on('change', function(){
                            var targetfield = '$targetfield';
                            var targetdummyfield = '$targetdummyfield';

                            var date = jQuery('#$fdtyear').val() + '-' + jQuery('#$fdtmon').val() + '-' + jQuery('#$fdtday').val();
                            jQuery('input[name="' + targetdummyfield + '"]').val(date);
                        });
                    ];

                    $valinfo{'rules'}{ $field_prefix . $k . '_dummyvalidator'}{'validDate'} = 'true';
                    $valinfo{'messages'}{ $field_prefix . $k . '_dummyvalidator' }{'validDate'} = $self->txt("Date is invalid");

                }
                elsif ($t eq 'CS_DATEMORETHAN') {
                    #num1 is the target date dummy field that we want dateTo to be compared with
                    my $targetdummyfield = $field_prefix . $num1 . '_dummyvalidator';

                    my $dTo = $self->{'Fields'}{'fields'}{$k}{'label'};
                    my $dFrom = $self->{'Fields'}{'fields'}{$num1}{'label'};

                    $valinfo{'rules'}{ $field_prefix . $k . '_dummyvalidator'}{'dateMoreThan'} = $targetdummyfield;
                    $valinfo{'messages'}{ $field_prefix . $k . '_dummyvalidator' }{'dateMoreThan'} =
                        $self->txt("[_1] is not more than [_2]", $dTo, $dFrom);
                }
            }
        }
    }

    my $val_rules;
    eval {
        require JSON;
        $val_rules = JSON::to_json( \%valinfo );
    };
    if ( $val_rules and $val_rules ne '{}' ) {

        $val_rules =~ s/['"]true['"]/true/g;
        $val_rules =~ s/["']false['"]/false/g;
        $val_rules =~ s/}$//;
        $val_rules =~ s/JAVASCRIPT['"]//g;
        $val_rules =~ s/['"]JAVASCRIPT//g;
        $val_rules =~ s/SINGLEQUOTE/'/g;
        $val_rules =~ s/"REMOVEQ//g;
        $val_rules =~ s/REMOVEQ"//g;
        $val_rules =~ s/REMOVEQ//g;
        $val_rules .= qq~
            ,
            ignore: ".ignore",
            errorClass: "form_field_invalid",
            validClass: "form_field_valid",
            invalidHandler: function(e, validator){
                if(validator.errorList.length){
                    var tabname = jQuery(validator.errorList[0].element).closest(".$tab_class").attr('id');
                    
                    if ( '$tab_style' == 'ui-tabs' ){
                        // Using divs and jquery tabs
                        var tab = document.getElementById(tabname);
                        \$('#$tab_div_id').tabs('select', '#' + tabname);
                    }
                    else if ('$tab_style' == 'tables'){
                        // Using html forms tables and black magic
                        jQuery('.tab_links').removeClass('active');
                        jQuery('#a_' + tabname ).addClass('active');
                        jQuery('.$tab_class').hide();
                        jQuery('#' + tabname ).show(); 
                        
                    }
                    //alert("Got invalid input on tab " + tabname);
                }
            },
            errorPlacement: function(error, element) {
                if(jQuery(element).is(":visible"))  {
                    error.insertAfter(element);
                }
                else if(jQuery(element).hasClass("dummyvalidation")) {
                    error.insertAfter(element);
                }
                else    {
                    jQuery(element).next(':visible');
                    error.insertAfter(jQuery(element).next(':visible')); 
                }
            },
        }
        ~;
        return qq[
        <script src = "//ajax.aspnetcdn.com/ajax/jquery.validate/1.9/jquery.validate.min.js"></script>
        <script type="text/javascript">
        jQuery().ready(function() {
                jQuery.validator.addMethod(
                    "validDate",
                    function(value, element) {
                        if(!value) {
                            return false;
                        }

                        var date = jQuery(element).val().split('-');
                        var d = date\[2\];
                        var m = date\[1\];
                        var y = date\[0\];

                        date = new Date(y, m-1, d);
                        if(date.getFullYear() == y && date.getMonth() + 1 == m && date.getDate() == d) {
                            return true;
                        }

                        return false;
                    },
                    ""
                );

                jQuery.validator.addMethod(
                    "dateMoreThan",
                    function(dateTo, element, dateFromElement) {
                        var dateFrom = jQuery('input[name="' + dateFromElement + '"]').val();

                        if(!dateTo || !dateFrom) {
                            return false;
                        }

                        var dtF = dateFrom.split('-');
                        var ddtF = dtF\[2\];
                        var mdtF = dtF\[1\];
                        var ydtF = dtF\[0\];

                        ddtF = (ddtF.length == 2) ? ddtF : "0" + ddtF;
                        mdtF = (mdtF.length == 2) ? mdtF : "0" + mdtF;

                        var dtT = dateTo.split('-');
                        var ddtT = dtT\[2\];
                        var mdtT = dtT\[1\];
                        var ydtT = dtT\[0\];

                        ddtT = (ddtT.length == 2) ? ddtT : "0" + ddtT;
                        mdtT = (mdtT.length == 2) ? mdtT : "0" + mdtT;


                        dtF = ydtF + "-" + mdtF + "-" + ddtF;
                        dtT = ydtT + "-" + mdtT + "-" + ddtT;

                        if(new Date(dtT) > new Date(dtF)) {
                            return true;
                        }

                        return false;
                    },
                    ""
                );



                // validate the comment form when it is submitted
                jQuery("#$formname$form_suffix").validate($val_rules);
                $remote_updates

                $dummy_validator
            });
        </script>
        ];
    }
    return '';
}

1;
# vim: set et sw=4 ts=4:
