// JS for the AJAX-heavy showtime guest list.

$(function(){

  // Variables common to many functions

  var show_id     = $('#ajax-calls-global-data').attr('show_id');
  var showtime_id = $('#ajax-calls-global-data').attr('showtime_id');
  var ajax_url    = '/shows/'+show_id+'/showtimes/'+showtime_id+'/attendees.json';
  var pending_walkin_updates = 0;



  // All page data refreshes every few seconds

  function refresh_all_counts(){
    console.log("Refreshing all attendance data.");

    // Mark totals and ALL reservation sections as pending
    $('.totals-box .saving').show();
    $('.reservation-group .saving').show();

    $.ajax({
      method: 'GET',
      url: ajax_url,
      success: function(data){
        if (data.success) {
          apply_new_counts(data);

          if (pending_walkin_updates == 0) { $('.totals-box .saving').hide(); }
          $('.reservation-group').not(':has(.pending-save)').find('.saving').hide();
          console.log("All attendance data updated.");

          setTimeout(refresh_all_counts, 5000); // Check again in 15 seconds
        } else {
          alert_error(); // Malformed response
        }
      },
      error: function(){ alert_error(); }
    });
  }

  function apply_new_counts(data){
    // Update counts in the totals box
    update_and_highlight_total('.count-confirmed-reserved', data.confirmed_reserved);
    update_and_highlight_total('.count-confirmed-admitted', data.confirmed_admitted);
    update_and_highlight_total('.count-waitlist-reserved', data.waitlist_reserved);
    update_and_highlight_total('.count-waitlist-admitted', data.waitlist_admitted);
    update_and_highlight_total('.count-walkins-admitted', data.walkins_admitted);
    update_and_highlight_total('.count-total-reserved', data.total_reserved);
    update_and_highlight_total('.count-total-admitted', data.total_admitted);

    var num_seats = parseInt($('.count-seats').text());
    if (data.total_admitted > num_seats) {
      $('.count-total-admitted').addClass('text-danger');
    } else {
      $('.count-total-admitted').removeClass('text-danger');
    }

    // Update per-reservation admittance status
    $('.reservation-group').each(function(i, this_group){
      var res_id = $(this_group).attr('reservation_id');
      if (! res_id) {
        console.error("Reservation group has no id!");
      }
      var remote_count = data.reservation_counts[res_id];
      update_and_highlight_reservation(res_id, remote_count);
    });
  }

  function update_and_highlight_total(selector, remote_count){
    var container = $(selector);
    var local_count = parseInt(container.text());
    var remote_count = parseInt(remote_count);

    if (local_count != remote_count){
      container
        .text(remote_count)
        .css({'background-color': '#00ff00'})
        .animate({'background-color': '#f5f5f5'}, 1000);
    }
  }

  function update_and_highlight_reservation(res_id, remote_count){

    // It's possible to have 2 groups with the same res_id (one confirmed
    // and one in waitlist), so we start by RE-querying for groups
    var groups = $('.reservation-group[reservation_id="'+res_id+'"]');
    var members = groups.find('.reservation-member');
    var remote_count = parseInt(remote_count) || 0;
    var local_count = members.filter('.checked').length;

    // console.log('Reservation '+res_id+' should have '+remote_count+' checked.');

    // Is the local count outdated?
    if (local_count != remote_count) {
      console.log('Updating reservation '+res_id+' # checked from '+local_count+' to '+remote_count+'.');

      // Clear out all checked items
      members.removeClass('.checked');
      // Then re-check the right number
      for(i = 0; i < remote_count; i ++){
        member = members[i];
        if (member) {
          $(member).addClass('checked');
        } else {
          alert_reservation_size_exceeded(res_id, members.first().text().trim());
        }
      }

      // Finally highlight the group(s) to indicate a change
      groups
        .css({'background-color': '#00ff00'})
        .animate({'background-color': '#fff'}, 1000);
    }
  }

  var reservation_size_exceeded_alerted = false;

  function alert_reservation_size_exceeded(res_id, lastname){
    if (reservation_size_exceeded_alerted) { return; }
    alert('ERROR: The number of people admitted for the "'+lastname+'" reservation (id '+res_id+') is greater than the reservation size, meaning you may not be able to admit all other confirmed guests. You can still use this page, but watch the totals. You will only be alerted ONCE about this.');
    reservation_size_exceeded_alerted = true;
  }

  var num_seats_exceeded_alerted = false;

  function alert_num_seats_exceeded(){
    if (num_seats_exceeded_alerted) { return; }
    alert('ERROR: More people have been admitted than there are seats available. See the totals box for the breakdown. You will only be alerted ONCE about this.');
    refresh_all_counts(); // Update counts so this user sees the latest totals
    num_seats_exceeded_alerted = true;
  }

  function alert_error(){
    alert('ERROR: Unable to get updated data from the server; your totals may be out of date. Please refresh the page.');
  }



  // When user checks or unchecks a name, or adds / removes walkins

  $('.reservation-member').click(function(e){
    e.preventDefault();

    var member = $(this);
    var group = member.parents('.reservation-group');
    var res_id = group.attr('reservation_id');
    var num_checked = group.find('.checked').length;
    var list = (member.parents('.confirmed-list').length > 0 ? 'confirmed' : 'waitlist');

    if (member.is('.checked')) {
      console.log('MINUS one '+list+' guest from reservation '+res_id+'.');
      var method = 'DELETE';
      decrement_count(list);
      decrement_count('total');
    } else {
      console.log('PLUS one '+list+' guest to reservation '+res_id+'.');
      var method = 'POST';
      increment_count(list);
      increment_count('total');
    }

    member.toggleClass('checked');
    member.addClass('pending-save');
    group.find('.saving').show(); // visible until all pending saves are complete

    // Send the request to create or destroy attendee for this reservation.
    // We don't track the old or new reservation total (because this client
    // might not have the latest info on it), we just say "Plus one" or "Minus one".
    $.ajax({
      method: method,
      url: ajax_url,
      data: {
        reservation_id: res_id,
        was_on_waitlist: (list == 'waitlist')
      },
      success: function(data){
        if (data.success) {
          member.removeClass('pending-save');
          // Remove .saving icon when ALL .pending-saves are complete
          group.not(':has(.pending-save)').find('.saving').hide();

          if (data.reservation_size_exceeded) {
            alert_reservation_size_exceeded(res_id, member.text().trim());
          }

          if (data.num_seats_exceeded) {
            alert_num_seats_exceeded();
          }
        } else {
          alert_error();
        }
      },
      error: function(){ alert_error(); }
    });
  });

  $('.add-walkin, .remove-walkin').click(function(){
    $('.totals-box .saving').show();
    pending_walkin_updates += 1;

    if ($(this).is('.add-walkin')) {
      console.log('PLUS one walk-in guest.');
      increment_count('walkins');
      increment_count('total');
      var method = 'POST';
    } else {
      console.log('MINUS one walk-in guest.');
      decrement_count('walkins');
      decrement_count('total');
      var method = 'DELETE';
    }

    $.ajax({
      method: method,
      url: ajax_url,
      data: {},
      success: function(){
        pending_walkin_updates -= 1;
        if (pending_walkin_updates == 0) { $('.totals-box .saving').hide(); }
      },
      error: function(){ alert_error(); }
    });
  });

  function increment_count(list){
    var element = $('.count-'+list+'-admitted');
    var current_total = parseInt(element.text());
    element.text(current_total + 1);
  }

  function decrement_count(list){
    var element = $('.count-'+list+'-admitted');
    var current_total = parseInt(element.text());
    element.text(current_total - 1);
  }



  // Fetch the initial totals (on page load, they're just question marks)

  refresh_all_counts();

});
