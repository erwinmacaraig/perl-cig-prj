function update_options(optionType, dtype)   {
    jQuery('input#currentoption').val(optionType);

    var currentoption = jQuery('input#currentoption').val();
    var optiontrigger = jQuery('input#optiontrigger').val();

    var qstring = '';
    qstring = qstring + '&dtype=' + dtype;
    qstring = qstring + '&etype=' + jQuery('#l_etype').val();
    qstring = qstring + '&sp=' + jQuery('#l_sport').val();
    qstring = qstring + '&pt=' + jQuery('#l_type').val();
    qstring = qstring + '&per=' + jQuery('#l_role').val();
    qstring = qstring + '&pl=' + jQuery('#l_level').val();
    qstring = qstring + '&ag=' + jQuery('#l_age').val();
    qstring = qstring + '&nat=' + jQuery('#l_nature').val();
    qstring = qstring + '&ol=' + jQuery('#originLevel').val();
    qstring = qstring + '&r=' + jQuery('#rID').val();
    qstring = qstring + '&sr=' + jQuery('#srID').val();
    qstring = qstring + '&eID=' + jQuery('#l_eId').val();
    qstring = qstring + '&pID=' + jQuery('#pID').val();
    qstring = qstring + '&client=' + jQuery('#client').val();
    qstring = qstring + '&transfer=' + jQuery('#transfer').val();
    qstring = qstring + '&dsport=' + jQuery('#dsport').val();
    qstring = qstring + '&dentityrole=' + jQuery('#dentityrole').val();
    qstring = qstring + '&dnat=' + jQuery('#dnat').val();
    qstring = qstring + '&dlevel=' + jQuery('#dlevel').val();

    qstring = qstring + '&itc=' + jQuery('#itc').val();
    qstring = qstring + '&preqtype=' + jQuery('#preqtype').val();

    if(currentoption != '' && currentoption === optionType && optiontrigger === currentoption) {
        //do nothing to avoid duplicate call
    }
    else if(optionType == 'complete')    {
      if(jQuery('#replacedflow-btn-continue').length>0) {
          jQuery('#replacedflow-btn-continue').show();
      }
      else {
          jQuery('#flow-btn-continue').show();
      }

      if(jQuery("input#l_ma_comment").length > 0){
        jQuery("input#l_ma_comment").show();
      }
    }
    else    {
        jQuery.getJSON('ajax/aj_person_registerwhat.cgi?otype=' + optionType + qstring, function(data)    {
          var items = [];
          if(data.results == 1) {
            jQuery('#l_' + optionType ).html('<option selected = "selected" value = "' + data.options[0].value + '">' + data.options[0].name + '</option>');
            jQuery('#l_' + optionType ).fcToggle('rebuild');
            chooseOption(data.options[0].value,optionType, data.options[0].name); 
          }
          else if(data.results > 1) {
              var defValue = jQuery('#defvalue_' + optionType).val();
              jQuery.each( data.options, function( key, val ) {
                var selected = '';//(defValue && defValue == val.value) ? ' SELECTED ' : '';
                items.push( '<option value = "' + val.value + '" ' + selected + '>' + val.name + '</option>' );
              });
              jQuery('#l_' + optionType ).html('<option />' + items.join(''));
              jQuery('#l_' + optionType ).fcToggle('rebuild');
              jQuery('#regopt_options_title').html(jQuery('#regopt_title_' + optionType).html());
          }
          else  {
              var error;
              error = (data.error) ? data.error : '';
              jQuery('.notavailable').show();           
             //(jQuery('#regopt_title_nooptions').html() + ": " + "<br/>" + error);
          }
          if(optionType == 'etype' && jQuery('#clientLevel').val() && data.results != 1) {
              jQuery('#l_' + optionType ).val(jQuery('#clientLevel').val()); 
              jQuery('#l_' + optionType ).fcToggle('rebuild');
              jQuery('#l_' + optionType).trigger('change');
          }
          if(optionType == 'eId' && jQuery('#clientID').val() && data.results != 1)   {
              jQuery('#l_' + optionType ).val(jQuery('#clientID').val()); 
              jQuery('#l_' + optionType ).fcToggle('rebuild');
              jQuery('#l_' + optionType).trigger('change');
          }
        });
    }
}

function chooseOption(val, optionType, name)  {
    jQuery('#l_' + optionType).val(val);
    var nextlayer = {
        'type' : 'etype',
        'etype' : 'eId',
        'eId' : 'sport',
        'sport' : 'role',
        'role' : 'level',
        'level' : 'age',
        'age' : 'nature',
        'nature' : 'complete'
    };
    var next = nextlayer[optionType];
    if(next == 'etype' && jQuery('#eselect').val() == 0)    {
        next = 'sport';
    }

    //jQuery('input#currentoption').val(optionType);
    update_options(next);
}

jQuery('.regoptions').on('change','select',function(e) {
    var optionTrigger = jQuery("#" + e.target.id).attr('data-type');
    jQuery('input#optiontrigger').val(optionTrigger);

    var optionType = jQuery(this).attr('data-type');
    var v = jQuery(this).val();
    if(v)   {
        var optionName = jQuery(this).text();
        clearBelow(optionType);
        chooseOption(v, optionType, optionName);
    }
    e.preventDefault();
    return false; 
});

function clearBelow(optionType) {

    switch (optionType) {
        case 'type':
            jQuery('#l_etype').html('');
            jQuery('#l_etype').fcToggle('rebuild');
        case 'etype':
            jQuery('#l_eId').html('');
            jQuery('#l_eId').fcToggle('rebuild');
        case 'eId':
            jQuery('#l_sport').html('');
            jQuery('#l_sport').fcToggle('rebuild');
        case 'sport':
            jQuery('#l_role').html('');
            jQuery('#l_role').fcToggle('rebuild');
        case 'role':
            jQuery('#l_level').html('');
            jQuery('#l_level').fcToggle('rebuild');
        case 'level':
            jQuery('#l_age').html('');
            jQuery('#l_age').fcToggle('rebuild');
        case 'age':
            jQuery('#l_nature').html('');
            jQuery('#l_nature').fcToggle('rebuild');
        case 'nature':
            jQuery('#regopt_options_continue').hide();
            jQuery('.notavailable').hide();           
    }
}
