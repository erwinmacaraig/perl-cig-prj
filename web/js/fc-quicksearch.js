(function($){
	console.log("trigger search")
    jQuery.fn.quicksearch = function() {
        var client_string = jQuery("input.search-client-string").val();
		var role;
		var entity = [];
		var dtFrom;
		var dtTo;
		var tasktype;
		if($(".role").is(":checked")){			
			role = 	$("#PersonType").val();
			//console.log(role);
		}
		if($(".club").is(":checked")){
			entity.push(3);
			
		}
		if($(".venue").is(":checked")){
			entity.push(-47);
		}
		if($(".daterange").is(":checked")){			
			dtFrom = $("input#dtValidFrom").val();
 			dtTo = $("input#dtValidUntil").val();

		}
		var entities = entity.join();
		if($(".task").is(":checked")){
			tasktype = $("#TaskType").val();
				
		}		
		    /*	
			var role = [];
			jQuery(":checkbox.role").each(function(){
				if(jQuery(this).is(":checked")){
					role.push(jQuery(this).attr("value"));						
				}
			});
			var roles = role.join();
			*/
			//console.log(role);
			//client_string += '&roles=' + roles;
			//source: "ajax/aj_search.cgi?client=" + client_string,
        jQuery(this).autocomplete({
            delay: 0,
			source: function(request,response){
				jQuery.ajax({
					url: "ajax/aj_search.cgi",
					dataType: "json",
					data: {
						client: client_string,
						term: request.term,
						role: role,
						entity: entities,
						dtFrom: dtFrom,
						dtTo: dtTo,
						tasktype: tasktype
	
					},									
					success: function(data){
					var array = data.error ? [] : jQuery.map( data, function(item) {
	              		  	//your operation on data
							return {
										label : item.label,
										link: item.link
								};										
						});
						response(array);			 	
				    }
				});	 //end of jQuery.ajax		
			},
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
