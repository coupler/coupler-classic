//function updateJobCount() {
  //$.get("/jobs/count", function(data) {
    //if (data == "0") {
      //$('#job-count').html("")
    //} else {
      //$('#job-count').html("("+data+")")
    //}
  //});
//}
$(function() {
  $('.timeago').timeago();
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
  //setInterval(updateJobCount, 30000);
});
