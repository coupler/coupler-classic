/*
function updateJobCount() {
  $.get("/jobs/count", function(data) {
    if (data == "0") {
      $('#job-count').html("")
    } else {
      $('#job-count').html("("+data+")")
    }
  });
}
*/
function updateNotifications() {
  $.get("/notifications/unseen.json", function(data, textStatus, jqXHR) {
    var n = $('#notifications');
    if (data.length == 0) {
      n.find('ul').html('');
      n.hide();
    } else {
      var ids = [];
      $.each(data, function() {
        var id = 'notification-'+this.id;
        ids.push(id);
        n.find('ul:not(:has(#'+id+'))').append('<li id="'+id+'"><a href="'+this.url+'">'+this.message+'</a></li>');
      });
      n.find('ul li:not(#'+ids.join(',#')+')').remove();
      $('#notifications').show();
    }
  }, 'json');
}
$(function() {
  $('.timeago').timeago();
  /*
  var accordion = $('#sidebar .accordion').accordion({
    collapsible: true, icons: false,
    navigation: true, autoHeight: false,
    navigationFilter: function() {
      var href = this.href;
      var cur  = location.href;
      return(href == cur.substring(0, href.length));
    }
  });
  accordion.find('button').each(function() {
    var obj = $(this);
    var arr = obj.attr('class').split("-");
    var icon, href;
    switch (arr[0]) {
    case 'more':
      icon = 'ui-icon-circle-arrow-e';
      href = '/'+arr[1];
      break;
    case 'new':
      icon = 'ui-icon-circle-plus';
      href = '/'+arr[1]+'s/new';
      break;
    }
    obj.button({ icons: { primary: icon } }).click(function() {
      window.location.href = href;
    });
  });
  */
  //setInterval(updateNotifications, 10000);
  //updateNotifications();
});
