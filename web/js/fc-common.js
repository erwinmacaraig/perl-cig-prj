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

    $("form#personInitRequest").submit(function(e){
        if($(this).find("input[type=checkbox]:checked").length == 0){
            e.preventDefault();
            $("div#init_error").slideDown();
        }
    });

})
