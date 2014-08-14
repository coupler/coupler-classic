$(function() {
  $('#transform-dialog').dialog({
      autoOpen: false, title: "Transform", modal: true
  });
  $('#transform-button').click(function() {
    $('#transform-dialog').dialog('open');
  });
  $('#transform-cancel-button').click(function() {
    $('#transform-dialog').dialog('close');
  });
});
