// Hookup the autocompletes on page load
$(document).ready(function() {
	$(".reservation_block").on("click", cycleStrikethrough);
});

var cycleStrikethrough = function() {
	var count = $(this).children().length;
	var current = $(this).children(".checked").length;
	if(count == current) {
		$(this).children().removeClass("checked");
	}	else {
		$(this).children(":lt(" + (current + 1) + ")").addClass("checked");
	}
}