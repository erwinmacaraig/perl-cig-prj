(function($){

    jQuery.fn.quicksearch = function() {
        var client_string = jQuery("input.search-client-string").val();
        jQuery(this).autocomplete({
            delay: 0,
            source: "ajax/aj_search.cgi?client=" + client_string,
            position: {my: "right top", at: "right bottom"},
            select: function(event, response) {
                location.href = response.item.link;
            },
            _renderMenu: function(ul, items) {
                var self = this,
                currentCategory = "";
                var lastnumnotshown = 0;
                jQuery.each(items, function(index, item) {
                    if (item.category != currentCategory) {
                        if(lastnumnotshown) {
                            ul.append( "<li class='ui-autocomplete-notshown'>" + lastnumnotshown + " items not shown</li>" );
                        }
                        ul.append( "<li class='ui-autocomplete-category'>" + item.category + "</li>" );
                        currentCategory = item.category;
                    }
                    lastnumnotshown = item.numnotshown;
                    self._renderItem(ul, item);
                });
                if(lastnumnotshown) {
                    ul.append( "<li class='ui-autocomplete-notshown'>" + lastnumnotshown + " items not shown</li>" );
                }
            }
        });
    };
})(jQuery);
