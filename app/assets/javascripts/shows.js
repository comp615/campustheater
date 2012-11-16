// Two functions to deal with adding new fields for embedded relationships
function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest("li").hide();
  return false;
}

function add_fields(trigger_obj, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  var $content = $(content.replace(regexp, new_id));


  // Bind the new function for the elements we're adding
  var change_function = function() {
  	$content.find("a.remove").show();
  	add_fields($content, association, content);
  };

  // Bind the event to trigger just once for the elements we are adding, hide remove till they edit
  $content.one("change", "input,select", change_function);
  $content.find("a.remove").hide();

	// Manual hack for the first run
  if($(trigger_obj).is("a")) {
  	$(trigger_obj).parent().after($content);
  	if(association == "showtimes")
  		datify($(trigger_obj).parent().next());
  	$(trigger_obj).parent().remove();
  } else {
  	$(trigger_obj).after($content);
  }
  
  if(association == "showtimes")
  	datify($(trigger_obj).next());
  if(association == "show_positions" || association == "permissions")
  	hookupPersonAutoComplete();
}

function initialize_fields() {
	var links;
	links.each(function() {

	});
}

// Function to hookup the datepickers (auto-loaded on page load in another lib)
function datify(parent_el) {
	$(parent_el).find('input.date').each(function(){
		var $this = $(this);
		$this.datepicker({ 'dateFormat': 'm/d/yy' });

		if ($this.hasClass('start') || $this.hasClass('end')) {
			$this.on('changeDate change', doDatepair);
		}

	});

	$(parent_el).find('input.time').each(function() {
		var $this = $(this);
		var opts = { 'showDuration': true, 'timeFormat': 'g:ia', 'scrollDefaultNow': true };

		if ($this.hasClass('start') || $this.hasClass('end')) {
			opts.onSelect = doDatepair;
		}

		$this.timepicker(opts);
	});
}

function handleFileChange() {
	// This seems jank, but I guess it's how the plugin works for validations
	var $form = $('form.edit_show');
	var id = $form.attr("id");
	var validators = window.ClientSideValidations.forms[id].validators;
	if ($form.isValid(validators)) {
	    $form.data("remote", true);
	    $form.attr("data-remote", true);
	    $form.submit();
	} else {
		alert('Please fill out the missing fields to preview your poster');
	}
}

// Hookup the autocompletes on page load
$(document).ready(function() {
	// Add a holder for the required asterisks
	$("input.required, select.required, textarea.required").after("<span class='required' />");

	// Bind the live-preview updates
	$("form").on("change", "input, textarea, select", function() {
		$("[data-field=" + $(this).attr("id") + "]").text($(this).val());
	});

	$("input, textarea, select").each(function() {
		if($(this).val() != "")
			$("[data-field=" + $(this).attr("id") + "]").text($(this).val());
	});

	$("#show_poster").on("change", handleFileChange);

	// Click all the add links to convert them to fields
	// TODO: Just render them in the first place
	$("a.add-link").click();

	// Since the timepicker is nested in a label, we need to prevent
	// label clicks from doing anything if they are on the time select list
	$("form").on("click","label", function(e) { 
	  if($(e.target).is("li.ui-timepicker-selected")) {
	     e.preventDefault();
	   }
	});


	hookupPersonAutoComplete();
	$("#show_on_sale").datepicker({ 'dateFormat': 'm/d/yy' })
	
	$("#show_tix_enabled").on("change", updateTixFieldVisibility);
	updateTixFieldVisibility();
});

var updateTixFieldVisibility = function() {
	$(".tix_on").toggle($("#show_tix_enabled").is(":checked"));
	$(".tix_off").toggle(!$("#show_tix_enabled").is(":checked"));
}

//Function used to render an indiviudal entry in the auto complete
var renderItem = function( ul, item ) {
	var text = item.fname + " " + item.lname;
	if(item.college)
		text += " (" + item.college + " " + item.year + ")";
	return $( "<li></li>" )
		.data( "item.autocomplete", item )
		.append( "<a>" + text + "</a>" )
		.appendTo( ul );
};

// Indemnipotent (or whatever) so we can re-run to hookup newly created objects
var hookupPersonAutoComplete = function() {
	$( ".person:not(.ui-autocomplete-input)" ).each(function (i) {
     $(this).autocomplete({
				source: "/search/lookup?type=people",
				minLength: 2,
				select: function( event, ui ) {
					$(this).val(ui.item.fname + " " + ui.item.lname);
					$(this).parent().find(".person_id").val(ui.item.id);
					return false;
				}
			}).data( "autocomplete" )._renderItem = renderItem;
	});
}