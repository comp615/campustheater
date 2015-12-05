$(document).ready(function() {

	// There will be no enter key submissions here
	$("form").bind("keypress", function(e) {
        if (e.keyCode == 13) return false;
  });

  // When the form is submited alter the path to go to the right place (selected show)
  $("form").on("submit", function(e) {
	  var url = $(this).attr("action").replace("id",$(this).find("select").val());
	  $(this).attr("action",url);
  });

  // Fill in student names on house managers list
  $(".select-house-manager:not(.ui-autocomplete-input)").each(function (i) {
    $(this).autocomplete({
        source: "/search/lookup?type=people",
        minLength: 2,
        select: function( event, ui ) {
          $(this).val(ui.item.fname + " " + ui.item.lname);
          $(this).parents().find(".person_id").val(ui.item.id);
          return false;
        }
      })
      .data( "ui-autocomplete" )._renderItem = function( ul, item ) {
        var text = item.fname + " " + item.lname;
        if(item.college)
          text += " (" + item.college + " " + item.year + ")";
        return $( "<li></li>" )
          .data( "item.autocomplete", item )
          .append( "<a>" + text + "</a>" )
          .appendTo( ul );
      };
  });

});
