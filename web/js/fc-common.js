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

  if ($("span.level-name").html() == "Person") {
  	$("body").find("header nav ul li a").css("padding-left","9px");
  	$("body").find("header nav ul li a").css("padding-right","9px");
  }


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
                }

                break;
            case "domestic":
                if(!$(this).hasClass("active")){
                    $(this).addClass("active");
                    $("div#transfer_type_option a#international").removeClass("active");

                    $("div#itc_selection").slideToggle("fast");
                    $("div#peoplelookup_form").slideToggle("fast");
                }
              break;
        }

    });

    //here we remove the col-md-10 class used on the generic forms
    //to flush the button to the right. this is a temporary fix.
    $("table.products-table").next("fieldset").find("div.txtright").removeClass("col-md-10");
    
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

     
})
