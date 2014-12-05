(function( $ ){

    var methods = {
        init : function(options) {
            this.each(function() {
                build(jQuery(this));
            });
        },
        rebuild: function( ) {    
            this.each(function() {
                build(jQuery(this));
            });
        }
    };

    $.fn.fcToggle = function(methodOrOptions) {
        if ( methods[methodOrOptions] ) {
            return methods[ methodOrOptions ].apply( this, Array.prototype.slice.call( arguments, 1 ));
        } else if ( typeof methodOrOptions === 'object' || ! methodOrOptions ) {
            // Default to "init"
            return methods.init.apply( this, arguments );
        } else {
            $.error( 'Method ' +  methodOrOptions + ' does not exist on jQuery.fcToggle' );
        }    
    };

    function createNewElement(s) {
        var name = s.attr('name');
        var ele_id = 'toggleG' + name;
        var toggleOptions = '';
        var count = 0;
        var lastText = '';
        $(s).children('option').each(function()    {
            var o = $(this);
            var val = o.val();
            var txt = o.text();
            var tclass = '';
            if(val != '')   {
                lastText = txt;
                if($(s).val() == val)  { tclass = 'active'; }
                toggleOptions = toggleOptions + '<a id ="' + ele_id + '_' + val + '" class = "' + tclass +'" title = "' + txt + '" href = "#" data-val = "' + val + '">' + txt + '</a>';
                count++;
            }
        });
        if(count > 4)  {
            return '';
        }
        else if(count == 1)  {
            jQuery(s).after('<span id = "' + ele_id + '" >' + lastText + '</span>');
        }
        else    {
            jQuery(s).after('<div class = "toggle-type" id = "' + ele_id + '">' + toggleOptions + '</div>');
        }
        jQuery(s).hide();
        return ele_id;
    }


    function remove(s) {
        var name = s.attr('name');
        var ele_id = 'toggleG' + name;
        jQuery('#' + ele_id).remove();
        jQuery('#' + ele_id).off("click.fcToggle","a");
        jQuery(s).off("change.fcToggle");
        jQuery(s).show();
    }

    function build(s) {
        remove(s);
        var ele_id = createNewElement(s);
        if(ele_id == '') {
            return false;
        }
        jQuery('#' + ele_id).on("click.fcToggle", "a", function(e)   {
            if(!jQuery(this).hasClass('active')) {
                val = jQuery(this).attr('data-val');
                jQuery(s).val(val);
                jQuery(s).trigger('change');
            }
            e.preventDefault();
        });
        jQuery(s).on('change.fcToggle', function(e)   {
            jQuery('#' + ele_id).children('a').removeClass('active');
            var newval = jQuery(s).val();
            jQuery('#' + ele_id + '_' + newval).addClass('active');
        });

    }

})( jQuery );
