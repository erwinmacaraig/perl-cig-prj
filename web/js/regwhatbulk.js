function update_options(optionType, dtype)   {
    var qstring = '';
    qstring = qstring + '&dtype=' + dtype;
    qstring = qstring + '&sp=' + jQuery('#l_sport').val();
    qstring = qstring + '&pt=' + jQuery('#l_type').val();
    qstring = qstring + '&per=' + jQuery('#l_role').val();
    qstring = qstring + '&pl=' + jQuery('#l_level').val();
    qstring = qstring + '&ag=' + jQuery('#l_age').val();
    qstring = qstring + '&nat=' + jQuery('#l_nature').val();
    qstring = qstring + '&ol=' + jQuery('#originLevel').val();
    qstring = qstring + '&r=' + jQuery('#rID').val();
    qstring = qstring + '&sr=' + jQuery('#srID').val();
    qstring = qstring + '&eID=' + jQuery('#selected_entityID').val();
    qstring = qstring + '&pID=' + jQuery('#pID').val();

    jQuery('#flow-btn-continue').hide();

    if(optionType == 'complete')    {
      jQuery('#flow-btn-continue').show();
    }
    else    {
        jQuery.getJSON('ajax/aj_person_registerwhat.cgi?dnat=RENEWAL&bulk=1&otype=' + optionType + qstring, function(data)    {
          var items = [];
          if(data.results == 1) {
            jQuery('#l_' + optionType ).html('<option SELECTED value = "' + data.options[0].value + '">' + data.options[0].name + '</option>');
            jQuery('#l_' + optionType ).fcToggle('rebuild');
            chooseOption(data.options[0].value,optionType, data.options[0].name); 
          }
          else if(data.results > 1) {
              jQuery.each( data.options, function( key, val ) {
                items.push( '<option value = "' + val.value + '">' + val.name + '</option>' );
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
        });
    }
}

function chooseOption(val, optionType, name)  {
    jQuery('#l_' + optionType).val(val);
    var nextlayer = {
        'type' : 'sport',
        'sport' : 'role',
        'role' : 'level',
        'level' : 'age',
        'age' : 'nature',
        'nature' : 'complete'
    };
    update_options(nextlayer[optionType]);
}

jQuery('.regoptions').on('change','select',function(e) {
    var optionType = jQuery(this).attr('data-type');
    var v = jQuery(this).val();
    var optionName = jQuery(this).text();
    clearBelow(optionType);
    chooseOption(v, optionType, optionName);
    e.preventDefault();
    return false; 
});

function clearBelow(optionType) {

    switch (optionType) {
        case 'type':
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
