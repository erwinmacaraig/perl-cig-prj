(function($) {
	jQuery.noConflict();
	product = (function(){
		closewin = function() {
			//window.close();
			//console.log('close win.');
		};
		return {
			show_status : function(msg) {
				console.log(msg);
				$('#loading').empty().append(msg).show().fadeOut(7000);
				console.log('>>'+$('#loading').val());
			}
		}
	}());
	$(document).ready(function(){
		$('form#productform').submit(function() {
			//product.show_status('Loading...');
			//$('#loading').val('Loading...').show();
			var strname = $("input[name=strname]").val();
			var realmid = $("select[name=realmID]").val();
			
			if (strname && realmid) {
				$(this).attr("action", "admin_product.cgi");
				var pid = $('input[name=pid]').val();
				if( parseInt(pid) > 0 )
					$('input[name=action]').val('editproduct');
				else
					$('input[name=action]').val('addproduct');
				return true;
			} else {
				$('#loading').empty().append('Required fields cannot be empty!').show().fadeOut(7000);
				return false;
			}
		});
		$('button#edit').click(function(){
			var pid = $(this).closest('tr').attr('id').split('-')[1];
			console.log(pid);
			$('input[name=productid]').val(pid);
			$('form#listform')
			.append($('<input/>').attr({'type':'hidden','name':'action'}).val('edit'))
			.submit();
			
		});
	});
})(jQuery);