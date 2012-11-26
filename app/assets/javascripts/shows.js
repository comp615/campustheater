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

// Add tech ops to the list when they change something and the student is blank
function watchTechOps() {
	$("#tech_ops").empty();
	$("#show_positions input[name*=name]").each(function() {
		if($(this).val() == "" && $(this).siblings("[name*=_destroy]").val() != 1 && $(this).siblings("[name*=position_id]").val() != "") {
			$el = $("<li />");
			$el.html("<span>" + $(this).siblings("[name*=assistant]").val() + " " + $(this).siblings("[name*=position_id]").children(":selected").text() + "</span>");
			$("#tech_ops").append($el);
		}
	});
}

function removeSingleAudition(e) {
	e.preventDefault();
	var aud_id = $(this).closest("tr").data("audition-id");
	send_destroy([aud_id]);
}

function removeBlockAudition(e) {
	e.preventDefault();
	var aud_ids = $(this).closest(".audition-group").find("tr").map(function() { return $(this).data("audition-id"); });
	send_destroy($.makeArray(aud_ids));
}

function send_destroy(ids) {
	var url = $("form.auditions").attr("action");
	$.ajax({
		url: url,
		data: {destroy_ids: ids},
		type: "PUT",
		success: function(data) {
			eval(data);
		}
	})
}

// If they manually change the name after autocompleting...remove the person_id
function protectAutocomplete() {
	$(this).siblings("[name*=person_id]").val("");
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

	$("#show_positions").on("change", "input, select", watchTechOps);
	$("#show_positions").on("click", ".remove", watchTechOps);
	$("form").on("change","[name*=name]",protectAutocomplete);

	$("#show_poster").on("change", handleFileChange);

	// Click all the add links to convert them to fields
	// TODO: Just render them in the first place
	$("a.add-link").click();
	watchTechOps();

	// Manage showing/hiding of the audition groups
	$("#aud_enabled_wrapper").toggle( $(this).is(":checked") );
	$("#submit").on('click', function() { $("form.edit_show")[0].submit() });
	$("#show_auditions_enabled").on('change',function() { $("#aud_enabled_wrapper").toggle( $(this).is(":checked") )});

	// Make the audition form submit the correct form
	$(".auditions input[type=submit]").on("click",function(e) { e.preventDefault(); e.stopImmediatePropagation(); $(this).closest("form").submit()});
	$("#audition_slots").on("click", "a.remove", removeSingleAudition);
	$("#audition_slots").on("click", ".block-remove .btn", removeBlockAudition);


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