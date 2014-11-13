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


  $('#international').click(function(){
      $('#international').addClass('active');
      $('#domestic').removeClass('active');
  });
  $('#domestic').click(function(){
      $('#domestic').addClass('active');
      $('#international').removeClass('active');
  });

})