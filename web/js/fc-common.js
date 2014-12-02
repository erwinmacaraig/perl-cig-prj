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

$(document).ready(function(){
  findInitialAccordionPanel();
  $("#accordion").on("hidden.bs.collapse", toggleChevron);
  $("#accordion").on("show.bs.collapse", toggleChevron);

  //temporary workaround for the navs to keep it overlapping on the drilldown menu
  //if ($("span.level-name").html() == "Person") {
  	//$("body").find("header nav ul li a").css("padding-left","9px");
  	//$("body").find("header nav ul li a").css("padding-right","9px");
  //}


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

    //here we remove the col-md-10 class used on the generic forms
    //to flush the button to the right. this is a temporary fix.
    //$("table.products-table").next("fieldset").find("div.txtright").removeClass("col-md-10");
    
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

    $("form#personInitRequest").submit(function(e){
        if($(this).find("input[type=checkbox]:checked").length == 0){
            e.preventDefault();
            $("div#init_error").slideDown();
        }
    });


    function getUrlparameter (strParam) {
      
      var strPageUrl = window.location.search.substring(1);

      var strUrlVars = strPageUrl.split('&');

      for (var i = 0; i < strUrlVars.length; i++) {
        
        var strParamName = strUrlVars[i].split('=');

        if (strParamName[0] ==strParam ) {
          return strParamName[1];
        }
      }

    }

    var param = getUrlparameter("a");

    console.log(param);

    if (param == "E_HOME" || param == "C_HOME") {
      
      $("header nav ul li a[href*='E_HOME']").addClass("active");
      $("header nav ul li a[href*='C_HOME']").addClass("active");
    
    } 

    else if (param == "LOGIN") {
      
      $("header nav ul li a[href*='E_HOME']").addClass("active");
    
    }

    else if (param == "E_L") {
      
      $("header nav ul li a[href*='E_L']").addClass("active");
    
    }

    else if (param == "C_L" || param == "C_DTA") {
     
      $("header nav ul li.subnav a:contains(Clubs)").addClass("active")

    }

    else if (param == "VENUE_L" || param == "VENUE_DTA") {
      
      $("header nav ul li.subnav a:contains(Venues)").addClass("active");
    
    }

    else if (param == "INITSRCH_P" || param == "PF_" || param == "DUPL_L" || param == "PRA_T" || param == "PRA_R" || param == "PREGFB_T" || param == "TXN_PAY_INV") {
     
      $("header nav ul li.subnav a:contains(People)").addClass("active")

    }

    else if (param == "WF_" || param == "PENDPR_") {
     
      $("header nav ul li.subnav a:contains(Work Tasks)").addClass("active")

    }

    else if (param == "REP_SETUP") {
      
      $("header nav ul li a[href*='REP_SETUP']").addClass("active");
    
    } else {

      $("header nav ul li a[href*='E_HOME']").addClass("active");

    }

})
