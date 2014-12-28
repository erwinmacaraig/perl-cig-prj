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

    if(rejectedDocsFlag == 1){
        $("li.active span.circleBg").addClass("rejectedBg");
        $("span.circleBg").find("i.documents-rejected").removeClass("documents-approved");

    } else {
        $("li.active span.circleBg span.circleBg").removeClass("rejectedBg");
        $("span.circleBg").find("i.documents-rejected").addClass("documents-approved");

        if (numberOfPendingDocs == 0) {
            $("body").find("i.documents-complete").removeClass("documents-incomplete");
        } else {
            $("body").find("i.documents-complete").addClass("documents-incomplete");
        }

    }

    var storedTask = localStorage.getItem("data");
    var taskID = $(".taskID").val();
    
    if (storedTask == taskID){
        
        $("body").find("i.memdetails-visited").removeClass("tab-not-visited");
        $("body").find("i.regdetails-visited").removeClass("tab-not-visited");
    
    } else {
        
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

    jQuery('kkselect.fcToggleGroup').each(function() {
        var s = jQuery(this);
        var name = s.attr('name');
        var ele_id = 'toggleG' + name;
        var toggleOptions = '';
        jQuery(s).children('option').each(function()    {
            var o = jQuery(this);
            var val = o.val();
            var txt = o.text();
            var tclass = '';
            if(val != '')   {
                if(jQuery(s).val() == val)  { tclass = 'active'; } 
                toggleOptions = toggleOptions + '<a id ="' + ele_id + '_' + val + '" class = "' + tclass +'" title = "' + txt + '" href = "#" data-val = "' + val + '">' + txt + '</a>';
            }
        });
        jQuery(s).after('<div class = "toggle-type" id = "' + ele_id + '">' + toggleOptions + '</div>');
        jQuery(s).hide();
        jQuery('#' + ele_id).on("click", "a", function(e)   {
            val = jQuery(this).attr('data-val');
            jQuery(s).val(val);
            jQuery(s).trigger('change');
            e.preventDefault();
        });
        jQuery(s).on('change', function(e)   {
            jQuery('#' + ele_id).children('a').removeClass('active');
            var newval = jQuery(s).val();
            jQuery('#' + ele_id + '_' + newval).addClass('active');
        });

    });
    
    checkIfDocsAllApproved();

});
$(window).bind("load", function() {
    $('#l_strISOCountry').insertAfter($("#l_strISOCountry_chosen"));
    $('#l_strISOCountryOfBirth').insertAfter($("#l_strISOCountryOfBirth_chosen"));
    $('#l_strISONationality').insertAfter($("#l_strISONationality_chosen"));
    $('#l_intLocalLanguage').insertAfter($("#l_intLocalLanguage_chosen"));
    $('#l_intNatCustomLU5').insertAfter($("#l_intNatCustomLU5_chosen"));
    $('#l_intGender').insertAfter($("#toggleGd_intGender"));
    $('#l_strContactISOCountry').insertAfter($("#l_strContactISOCountry_chosen")); 
});
