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
})