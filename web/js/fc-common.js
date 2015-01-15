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
        console.log("new task:" + taskID);
    }
    
 }
function calculateProducts(){
    var totalProduct = 0;
    $('input[type="checkbox"]:checked').each(function() {
        totalProduct += parseFloat($('#cost_'+this.name+'').val());          
    });
    $('.totalValue').html('$'+totalProduct.toFixed(2));
}

$(document).ready(function(){
    
    calculateProducts();

    $('form#flowFormID td.col-1 input[type="checkbox"]').click(function(){
        calculateProducts();
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
            case "international":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#domestic").removeClass("active");

                    $("div#itc_selection").slideToggle("fast");
                    $("div#peoplelookup_form").slideToggle("fast");
                    $("div#transfer_search_result").slideToggle("fast");
                }

                break;
            case "domestic":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#international").removeClass("active");

                    $("div#itc_selection").slideToggle("fast");
                    $("div#peoplelookup_form").slideToggle("fast");
                    $("div#transfer_search_result").slideToggle("fast");
                }
              break;
        }

    });

    
    //this is a temporary fix for the last two steps - documents and complete
    $(".document-upload").insertAfter($("fieldset").first());

     $(document).on("change", "input.paytxn_chk", function(){
        if(this.checked){
          $('#payment_manual').show();
          $('#payment_cc').show();
        } else {
          $('#payment_manual').hide();
          $('#payment_cc').hide();
        }
     })

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

});
jQuery(document).ready(function(){

    jQuery('a.btn-proceed').each(function() {
        var t = jQuery(this).html();
        jQuery(this).html(jQuery(this).html() + ' <span class ="fa fa-angle-right fa-2x proceed-chevron"></span>');
    });
    jQuery('input.btn-proceed').each(function() {
        var text = jQuery(this).val();
        var id = 'replaced' + jQuery(this).attr('id');
        var classes = jQuery(this).attr('class');
        jQuery(this).after('<a href = "#" class = "' + classes + '" id = "' + id + '">' + text + '<span class ="fa fa-angle-right fa-2x proceed-chevron"></span></a>');
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

});
