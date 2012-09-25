var updateFields = function() {
	var mode = $("input[name=mode]:checked").val();
	if(!mode)
		return;
	$("form > div").hide();
	$("form > div." + mode).show(10);
}

$(document).ready(function() {  
  updateFields();
  $("form").on("change","input:radio",updateFields);
});


