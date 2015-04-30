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
    $(".res-table tr td").click(function(){
        var index = $(this).index()
        $(".res-table tbody tr").each(function() {
        $(this).children(':eq('+index+')').addClass('ellipsis');
       
        })
    })
    /*Saeid*/ 
    function checkWidth(){
        return $(window).width() < 800
    }
    // $(window).resize(function(){checkWidth()}) < 800
    if( checkWidth() == true  || $(".res-table thead tr th").length > 10){
        /* find responsive-table and prepend a dropdown*/ 
        // get No. of columns with res-table class
        var noOfRequests = $('.res-table').length;
        // Convert "initial-cols" 's  value to array
        var initialCols = [];
        // $(".res-table").attr("initial-cols").split("-").map(Number);   
        $(".res-table").each(function(){
            var key = $(this).index();
            var val = $(this).attr("initial-cols");
            item = {}
            item ["val"] = val;

            initialCols.push(item);
        })
        // get length of initialCols array
        initialColsLength = initialCols.length;
        // dropdown generator function
        var dropdownGenerator = function(i){
             $(".res-table:eq("+i+") .res-headers th").each(function() {
             // location of header (Numeric)
             headerLocation = $(this).index();
             // create li elements for our custom dropdown
             /* selcol = boolean
                ellipsis = boolean
                data = integer
                onclick = responsiveTables(int)
             */
             if ($(this).html() != "") {
                // check if a header is empty
                var headerChecker = function(val){if(val == " "){return "Actions";}else{return val;}}
                 headers += '<li>\
                              <a selcol="true" ellipsis="false" data="'+headerLocation+'" data-value="'+i+'" class="small" tabindex="-1"  onclick="responsiveTables(\''+headerLocation+'\'\ ,\' '+i+'\'\)">\
                                &nbsp;'+headerChecker($(this).html())+'\
                              </a>\
                            </li>';
                columnCounter += 1;
            };
            });
             // wrap up made li's with a custom ul
            return '<div class="button-group responsiveTablesDropDown">\
                      <button type="button" class="btn btn-default btn-sm dropdown-toggle" data-toggle="dropdown">|||</button>\
                          <ul style="top:inherit" class="dropdown-menu res-items-group">\
                          '+ headers +'\
                          </ul>\
                    </div>';
        }
        // check if dropdown is empty
        if($(".res-items-group").length<=0){
            $(".res-table").wrap('<div class="res-wrapper"></div>'); 
            for(var i=0;i<noOfRequests;i++){
                // flash headers Variable first
                headers = "";
                // generate a drop down
                $(".res-table:eq("+i+") ").before(dropdownGenerator(i))
            }
            // click on all dropdown for initializating purposes
            $(".res-items-group li a").trigger("click");
            // trigger only the columns requested in initial-cols attribute
            for (var i = 0; i < initialColsLength; i++) {
                var tableLocation = i
                var toInitialize = $(".res-table:eq("+i+")").attr("initial-cols").split("-").map(Number);   
                var toInitializeLength = toInitialize.length;
                for (var v = 0; v < toInitializeLength; v++) {
                    // click each one of requested initial-cols
                    $(".res-items-group:eq("+tableLocation+") li:eq("+toInitialize[v]+") a").trigger("click")
                };
                
            }
            console.log(initialCols)
            // wrap entire table with a div for width purposes
            
            // fit the width of visible columns based on percentage
            $('.res-table thead tr th:not(.res-invisible)').each(function () {
            $(this).css('width',90/columnCounter+"%")    
            });   
        }
    }
});
function responsiveTables(headerLocation,gridLocation){
// Get ready variables
    // get status of colsel(Selected Column) 
    var status = $('.responsiveTablesDropDown:eq('+gridLocation+') a[data="'+headerLocation+'"]').attr('selcol'),
    header = $(".res-table:eq("+gridLocation+") .res-headers th:eq("+headerLocation+") , .res-table .res-headers td:eq("+headerLocation+")");
 // Do hide/show

 // check if a column select TO SHOW
 if(status == 'false'){
     // show selected header
     header.removeClass('res-invisible');
     // show selected column (**Note that columns and header has different show/hide line of code)
     $(".res-table:eq("+gridLocation+") tbody tr").each(function() {
       // find all related td and show them
       $(this).children(':eq('+headerLocation+')').removeClass('res-invisible');
       // change status of NOT SELECTED to SELECTED
       $('.responsiveTablesDropDown:eq('+gridLocation+') a[data="'+headerLocation+'"]').attr('selcol','true')
      })
     // columnCounter is checking how many columns currently exist.
    columnCounter += 1;

 // check if a column select TO HIDE
 }else if(status == 'true'){ 
    header.addClass('res-invisible');
    $(".res-table:eq("+gridLocation+") tbody tr").each(function() {
       $(this).children(':eq('+headerLocation+')').addClass('res-invisible');
       $('.responsiveTablesDropDown:eq('+gridLocation+') a[data="'+headerLocation+'"]').attr('selcol','false') 
        })
    columnCounter -=1;
 };
    // fit width of headers.
    $('.res-table:eq('+gridLocation+') thead tr th:not(.res-invisible)').each(function () {
        $(this).css('width',100/columnCounter+"%")
           
    });
}

