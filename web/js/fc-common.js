//JS
function findInitialAccordionPanel(){
	$(".panel-default").find("#panel1").addClass("in");
	$(".panel-default").find("i.indicator").first().removeClass("fa-chevron-right").addClass("fa-chevron-down");

}

function toggleChevron(e) {
	$(e.target)
	.prev(".panel-heading")
	.find("i.indicator")
	.toggleClass("fa-chevron-right fa-chevron-down");

}

function checkIfDocsAllApproved() {
    var numberOfPendingDocs = $(".totalPendingDocs").val();
    var rejectedDocsFlag = $(".rejectedDocs").val();

    var docsComplete = false;

    if(rejectedDocsFlag == 1){
        //$("li.active span.circleBg").addClass("rejectedBg");
        $("li#docstab span.circleBg").addClass("rejectedBg");
        $("span.circleBg").find("i.documents-rejected").removeClass("documents-approved");

    } else {
        $("li#docstab span.circleBg span.circleBg").removeClass("rejectedBg");
        $("span.circleBg").find("i.documents-rejected").addClass("documents-approved");

        if (numberOfPendingDocs == 0) {
            docsComplete = true;
            $("body").find("i.documents-complete").removeClass("documents-incomplete");
        } else {
            $("body").find("i.documents-complete").addClass("documents-incomplete");
        }

    }

    var storedWorkTaskTabs = localStorage.getItem("workflowtabs");
    var visitedWorkTask = JSON.parse(storedWorkTaskTabs);

    var taskID = $(".taskID").val();
    
    var disableAction = function(e) {
        return false;
    }

    if(rejectedDocsFlag > 0) {
        jQuery("a.workflow-action[data-actiontype=REJECT], a.workflow-action[data-actiontype=HOLD]")
            .removeClass("btn-disabled")
            .addClass("btn-main")
            .unbind("click", disableAction)
            .click(function(f){
                jQuery("div#showWorkflowNotes").modal();
                jQuery("#workFlowActionForm input[type=hidden][name=type]").val(jQuery(this).data('actiontype'));
                f.preventDefault();
            });

        jQuery("a.workflow-action[data-actiontype=APPROVE]").bind('click', disableAction);
    } else {
        jQuery("a.workflow-action").bind('click', disableAction);
    }


    if (visitedWorkTask != null && visitedWorkTask.taskid == taskID){

        for (i = 0; i < visitedWorkTask.visited.length; i++) {
            jQuery("ul.nav-tabs li a[href="+ visitedWorkTask.visited[i] +"] i").removeClass("tab-not-visited");
        }
        
        jQuery("a.workflow-action").each(function(){
            var actiontype = jQuery(this).data('actiontype');

            switch(actiontype){
                case 'APPROVE':
                    if(jQuery(this).data('disabled') == 0  && docsComplete && jQuery("ul.nav-tabs li a i.tab-not-visited").length == 0){
                        jQuery(this)
                            .removeClass("btn-disabled")
                            .addClass("btn-main")
                            .unbind("click", disableAction)
                            .click(function(){
                                location.href = jQuery(this).attr("href");
                            });
                    } else {
                        //jQuery(this).bind('click', disableAction);
                    }
                    break;
                case 'HOLD':
                case 'REJECT':
                case 'RESOLVE':
                    if(jQuery("ul.nav-tabs li a i.tab-not-visited").length == 0 || rejectedDocsFlag > 0){
                        jQuery(this)
                            .removeClass("btn-disabled")
                            .addClass("btn-main")
                            .unbind("click", disableAction)
                            .click(function(f){
                                jQuery("div#showWorkflowNotes").modal();
                                jQuery("#workFlowActionForm input[type=hidden][name=type]").val(actiontype);
                                f.preventDefault();
                            });
                    }
                    break;
            }
        });
   
    } else {
        //if(rejectedDocsFlag > 0) {
        //    jQuery("a.workflow-action[data-actiontype=REJECT], a.workflow-action[data-actiontype=HOLD]")
        //        .removeClass("btn-disabled")
        //        .addClass("btn-main")
        //        .unbind("click", disableAction)
        //        .click(function(f){
        //            jQuery("div#showWorkflowNotes").modal();
        //            jQuery("#workFlowActionForm input[type=hidden][name=type]").val(jQuery(this).data('actiontype'));
        //            f.preventDefault();
        //        });

        //    jQuery("a.workflow-action[data-actiontype=APPROVE]").bind('click', disableAction);
        //} else {
        //    jQuery("a.workflow-action").bind('click', disableAction);
        //}
        //localStorage.removeItem("workflowtabs");
        //this means you are viewing a new work task
    }
    
 }
function calculateProducts(){
    var totalProduct = 0;
    $('input[type="checkbox"]:checked').each(function() {
        totalProduct += parseFloat($('#cost_'+this.name+'').val());          
    });
    $('.totalValue').html('$'+totalProduct.toFixed(2));
}
function updateRegoProductsTotal(chkb,id_cost,id_total,client,formatter){	
	var total = parseFloat($("#"+id_total).val());
   
	//if( $('form#flowFormID td.col-1 input[type="checkbox"]:checked').prop("checked") == true){
	if( $('#'+chkb).prop("checked") == true){
		total = total + parseFloat($("#"+id_cost).val());	
	}	
	else {
		total = total - parseFloat($("#"+id_cost).val());
	}
	
	if(total > 0){
		$("#payOptions").css("display","block");
	}
	else {
		$("#payOptions").css("display","none");
		total = 0;
	}
	//$("#totalAmountUnpaidInFlow").val(total);
	$('#TotalAmountUnformatted').val(total);
	$.ajax(
		{
			method: "POST",
			url:formatter + "/formatcurrencyamount.cgi",
			data:"amount=" + total + "&client="+ client 			
		}).done(
			function(formattedamount){
				$("#totalAmountUnpaidInFlow").html(formattedamount);
				
			}
	);




	//$("#"+id_total).html(total);
	//total = parseFloat(total);
	//console.log(total);
	//alert(total);
}


$(document).ready(function(){
    calculateProducts();
    $('[data-toggle="popover"]').popover()
	
    $('form#flowFormID td.col-1 input[type="checkbox"]').click(function(){        
		
    });

    $("#menu li.subnav a.menutop").mouseover(function(){
        $("#menu li.subnav a.menutop").removeClass("selected");
        $(this).addClass("selected");
    });

    $("#menu li.subnav ul").mouseleave(function(){
        $("#menu li.subnav a.menutop").removeClass("selected");
    });
    $("#menu li.subnav a.menutop").mouseleave(function(){
        $("#menu li.subnav a.menutop").removeClass("selected");
    });

  findInitialAccordionPanel();
  $("#accordion").on("hidden.bs.collapse", toggleChevron);
  $("#accordion").on("show.bs.collapse", toggleChevron);


    // transfer type selection
    $("div#transfer_type_option a").click(function(e){
        e.preventDefault();

        var selected = jQuery(this).prop("id");
        $("input[name=transfer_type][value=" + selected.toUpperCase() + "]").prop("checked", true);

        switch(selected){
            case "int_transfer_in":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#domestic").removeClass("active");
                    $("div#transfer_type_option a#int_transfer_return").removeClass("active");

                    $("div#itc_selection").show("slide", {direction: "down"}, "fast");
                    $("div#peoplelookup_form").hide("slide", {direction: "down"}, "fast");
                    $("div#transfer_search_result").hide("fast");

                    $("input[name=request_type]").val('int_transfer_in');
                }

                break;
            case "int_transfer_return":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#domestic").removeClass("active");
                    $("div#transfer_type_option a#int_transfer_in").removeClass("active");

                    $("div#itc_selection").hide("slide", {direction: "down"}, "fast");
                    $("div#peoplelookup_form").show("slide", {direction: "down"}, "fast");
                    $("div#transfer_search_result").hide("fast");

                    $("input[name=request_type]").val('int_transfer_return');
                }

                break;

            case "domestic":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#int_transfer_in").removeClass("active");
                    $("div#transfer_type_option a#int_transfer_return").removeClass("active");

                    $("div#itc_selection").hide("slide", {direction: "down"}, "fast");
                    $("div#peoplelookup_form").show("slide", {direction: "down"}, "fast");
                    $("div#transfer_search_result").hide("fast");

                    $("input[name=request_type]").val('transfer');
                }
              break;
        }

    });

    
    //this is a temporary fix for the last two steps - documents and complete
    $(".document-upload").insertAfter($("fieldset").first());


     $(document).on("change", "input.paytxn_chk", function(){
         var gridID = $("input.paytxn_chk").closest("table").attr("id");
         var gridTable;
         if($.fn.dataTable.isDataTable("#" + gridID)) {
            gridTable = $("#" + gridID).DataTable({
                "retrieve": true
            });
         }

		var totalamount = 0;
		$("#l_intAmount").val('');
		$("#block-manualpay").css('display','none');
		var client = $('#clientstr').val();
		//if(this.checked){
          //$('#payment_manual').show();
		 // } else {
          //$('#payment_manual').hide();
          //$('#payment_cc').hide();
        //}
          
		  //check if manual pay is enabled
            if($('#manualpayment').length || $('#payment_cc').length){
                $('input[type="checkbox"]:checked', gridTable.cells().nodes()).each(function(index){
                    totalamount += parseFloat(this.value);
                    $("#block-manualpay").css('display','block');
                });
                //$('input[type="checkbox"]:checked').each(function (){
                //	totalamount += parseFloat(this.value);
                //    console.log(totalamount);
                //	$("#block-manualpay").css('display','block');
                //});
                $("#l_intAmount").val(totalamount.toFixed(2));
                //
                $.ajax({
                    method: "POST",
                    url:"formatcurrencyamount.cgi",
                    data:"amount=" + totalamount + "&client="+ client 			
                }).done(
                    function(formattedamount){
                        $("#id_total").val(totalamount);
                        $("#manualsum").html(formattedamount);
                    }
                );
                //
                if(totalamount > 0){
                    $('#payment_manual').css('display','block');
                    $('#payment_cc').show();
                }
                else {
                    $('#payment_manual').css('display','none');
                    $('#payment_cc').hide();
                }
			}
     });

     $("#btn-manualpay").click(function() {
            if($('#paymentType').val() == '') {
                alert("You Must Provide A Payment Type");
                return false;
            }
     }); 

	
   //Request transfer
   //validate the comment form when it is submitted
    $("form#personRequestForm").validate({
        rules: {
            search_keyword: {
                required: true
            }
        },
        messages: {
            search_keyword: "Search keyword is required."
        },
        
        errorLabelContainer: "#errorMsg"
    });

    //Pay Invoice Validation
    $("form#invoiceFormQry").validate({
        rules: {
          PersonType: {
            required: true
          }
        },

        messages: {
            PersonType: "Person type required"
        },

        errorLabelContainer: "#errorMsg"

    });

    //$("form#personInitRequest").submit(function(e){
    //    if($(this).find("input[type=checkbox]:checked").length == 0){
    //        e.preventDefault();
    //        $("div#init_error").slideDown();
    //    }
    //});

    checkIfDocsAllApproved();

    jQuery("input.search").on("keypress", function(){
		jQuery("input.search").quicksearch();
	});
	

    jQuery("input[type=checkbox]#selectall").on("click", function(){
        var targetprefix = jQuery(this).data("targetprefix");

        if(jQuery(this).prop("checked")) {
            jQuery("input[id^=" + targetprefix + "]").prop("checked", true);
        } else {
            jQuery("input[id^=" + targetprefix + "]").prop("checked", false);
        }
    });

        if ($(window).width() <= 480) {  
            jQuery("#menu .subnav").addClass("dropdown").removeClass("subnav");
            jQuery("#menu .dropdown a.menutop").addClass("dropdown-toggle").removeClass("menutop").attr("aria-expanded", true).attr("role", "button").attr("data-toggle", "dropdown");
            jQuery("#menu .dropdown ul").addClass("dropdown-menu").attr("role", "menu");
            
            jQuery(".defaultnav").attr("style", "display:none;");
            jQuery(".smartphonenav").attr("style", "display:block;");
        }else{
            jQuery(".defaultnav").attr("style", "display:block;");
            jQuery(".smartphonenav").attr("style", "display:none;");
        }
        
    $(window).resize(function() {
        if ($(window).width() <= 480) {  
            jQuery("#menu .subnav").addClass("dropdown").removeClass("subnav");
            jQuery("#menu .dropdown a.menutop").addClass("dropdown-toggle").removeClass("menutop").attr("aria-expanded", true).attr("role", "button").attr("data-toggle", "dropdown");
            jQuery("#menu .dropdown ul").addClass("dropdown-menu").attr("role", "menu");
        
            jQuery(".defaultnav").attr("style", "display:none;");
            jQuery(".smartphonenav").attr("style", "display:block;");
        }else{
            jQuery(".defaultnav").attr("style", "display:block;");
            jQuery(".smartphonenav").attr("style", "display:none;");
        }
    });   


    $("div#int_transfer_type_option a").click(function(e){
        e.preventDefault();

        var selected = jQuery(this).prop("id");
        console.log(selected);
        $("input[name=transfer_type][value=" + selected.toUpperCase() + "]").prop("checked", true);

        switch(selected){
            case "int_transfer_out":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#int_transfer_type_option a#int_transfer_return").removeClass("active");

                    $("input[name=request_type]").val('int_transfer_out');
                }

                break;
            case "int_transfer_return":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#int_transfer_type_option a#int_transfer_out").removeClass("active");

                    $("input[name=request_type]").val('int_transfer_return');
                }
                break;
        }

    });


    $("div#loan_type_option a").click(function(e){
        e.preventDefault();

        var selected = jQuery(this).prop("id");
        console.log(selected);
        $("input[name=transfer_type][value=" + selected.toUpperCase() + "]").prop("checked", true);

        switch(selected){
            case "int_loan":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");

                    $("div#loan_type_option a#domestic_loan").removeClass("active");

                    $("div#itc_selection").slideToggle("fast");
                    $("div#peoplelookup_form").slideToggle("fast");
                    $("div#transfer_search_result").slideToggle("fast");


                }

                break;
            case "domestic_loan":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");

                    $("div#loan_type_option a#int_loan").removeClass("active");
                    $("div#itc_selection").slideToggle("fast");
                    $("div#peoplelookup_form").slideToggle("fast");
                    $("div#transfer_search_result").slideToggle("fast");
                }
                break;
        }

    });

});
/*
$(window).scroll(function() {

    if ($(this).scrollTop()>0)
     {
        if ($(window).width() <= 480) {  
            $('.pageHeading').fadeOut();
        }
     }else{
        if ($(window).width() <= 480) { 
            $('.pageHeading').fadeIn();
        }
     }
});
*/
var columnCounter = 0;
jQuery(document).ready(function(){
    $(window).resize(function(){
        $("body,nav").removeAttr("style")
        // no padding for view in dashboards 
        if($(window).width()< 612){
        }
    }) 
    // fixingnav of nav in mobile sizez
    $(".navbar-toggle").click(function(){
        if($(window).width()>=275 && $(window).width()<313){
            $(".navbar-fixed-top").animate({
                'margin-left':'0'
            })
            $(".header").animate({
                "margin-left": "72%"
            })
            $(".navmenu-fixed-left").addClass("opend")
            $(".offcanvas:not(.opend)").css('display','block');
            $(".offcanvas:not(.navmenu-fixed-left)").animate({
              "margin-left": "-34%"
            })
        }
    })

    var headers = "";
    jQuery('a.btn-proceed').each(function() {
        var t = jQuery(this).html();
        jQuery(this).html(jQuery(this).html() + ' <span class ="fa fa-angle-right fa-2x proceed-chevron"></span>');
    });
    jQuery('input.btn-proceed').each(function() {
        var text = jQuery(this).val();
        var id = 'replaced' + jQuery(this).attr('id');
        var classes = jQuery(this).attr('class');
        jQuery(this).after('<a href = "#" class = "btn ' + classes + '" id = "' + id + '">' + text + '<span class ="fa fa-angle-right fa-2x proceed-chevron"></span></a>');
        if(!jQuery(this).is(':visible')) {
            jQuery('#' + id).hide(); 
        }
        jQuery(this).hide();
        form = jQuery(this).parents('form').get(0);
        formId = jQuery(form).attr('id');
        if(!formId) {
            jQuery(form).attr('id','proceedbtn-form');
            formId = 'proceedbtn-form';
        }
        jQuery('#' + id).click(function(e)   {
            e.preventDefault();
            jQuery('#' + formId).submit();
        });

    });
    $(".res-table tr td").click(function(){
        var index = $(this).index()
        $(".res-table tbody tr").each(function() {
        $(this).children(':eq('+index+')').addClass('ellipsis');
       
        })
    });

    function checkWidth(){
        return $(window).width() < 800
    }
    jQuery('.res-table').each(function() {
        var table = this;
        if( checkWidth() == true  || $(table).find("thead tr th").length > 20){

        var dropdownGenerator = function(){
            var headers = '';
            $(table).find(".res-headers th").each(function() {
                 // create li elements for our custom dropdown
                 if ($(this).html() != "") {
                    // check if a header is empty
                    var headerChecker = function(val){if(val == " "){return "Actions";}else{return val;}}
                     headers += '<li>\
                                  <a selcol="false" ellipsis="false" class="small responsiveTableColumnOptions" tabindex="-1" >  \
                                    &nbsp;'+headerChecker($(this).html())+'\
                                  </a>\
                                </li>';
                    columnCounter += 1;
                };
            });
            // wrap up made li's with a custom ul
            return '<div class="button-group responsiveTablesDropDown">\
                      <button type="button" class="btn btn-default btn-sm dropdown-toggle" data-toggle="dropdown">' + $('#label_columns').val() + ' <i class = "fa fa-caret-down"></i></button>\
                          <ul style="top:inherit" class="dropdown-menu res-items-group">\
                          '+ headers +'\
                          </ul>\
                    </div>';
        }
        // check if dropdown is empty
        if($(table).find(".res-items-group").length<=0){
            $(table).wrap('<div class="res-wrapper"></div>'); 
            $(table).before(dropdownGenerator())
            var toInitialize = $(table).attr("initial-cols").split("-").map(Number);   
            var toInitializeLength = toInitialize.length;
            for (var v = 0; v < toInitializeLength; v++) {
                $(table).parent().parent().find(".res-items-group li:eq("+toInitialize[v]+") a").attr('selcol','true');
            };
            // wrap entire table with a div for width purposes
            // fit the width of visible columns based on percentage
            $(table).find('thead tr th:not(.res-invisible)').each(function () {
                $(this).css('width',90/columnCounter+"%")    
            });   
        }
        responsiveTableDraw(table);
    }
    });
});

jQuery('.container').on( 'draw.dt','.res-wrapper .res-table', function () {
    responsiveTableDraw(this);
});

jQuery('.container').on('click','a.responsiveTableColumnOptions',function(e) {
    var st= jQuery(this).attr('selcol');
    var newstatus = jQuery(this).attr('selcol') == 'true' ? 'false' : 'true';
    jQuery(this).attr('selcol',newstatus);
    var t = jQuery(this).closest('.res-wrapper').find('table.res-table');
    responsiveTableDraw(t);
    $(this).closest(".dropdown-menu").prev().dropdown("toggle");
    e.preventDefault();
    return false;
});

function responsiveTableDraw(table) {
    var activeColumns = [];
    $(table).parent().parent().find('.responsiveTablesDropDown li a').each(function(index) {
        if(jQuery(this).attr('selcol') == 'true') {
            activeColumns.push(index);
        }
    });

    $.each(['tbody td', 'thead th', 'thead td'], function(index, ele) {
        $(table).find(ele).each(function(){
            var columnIndex = $(this).index();
            if($.inArray(columnIndex, activeColumns) != -1){
               $(this).removeClass('res-invisible');
            }
            else    {
               $(this).addClass('res-invisible');
            }
        });
    });
    return true;
}

function spinnerGenerator(command){
    if(command == "kill"){
        $(".spinner").remove()
    }else if(command == "generate"){
        $("body").append('<div class="spinner"></div>')
    }else{
        alert("nothing to do")
    }
}

