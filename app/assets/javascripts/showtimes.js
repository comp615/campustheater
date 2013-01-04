// Hookup the autocompletes on page load
$(document).ready(function() {
	$(".reservation_block").on("click", cycleStrikethrough);
});

var cycleStrikethrough = function() {
	var count = $(this).children().length;
	var current = $(this).children(".checked").length;
	if(count == current) {
		current = 0;
		$(this).children().removeClass("checked");
	}	else {
		current += 1;
		$(this).children(":lt(" + (current) + ")").addClass("checked");
	}

	$.ajax({
		url: document.location.href + "/update_attendance",
		data: {
			reservation_id: $(this).data("id"),
			num_used: current
		}
	});

}