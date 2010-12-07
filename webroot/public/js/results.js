var contentWidth, previousPosition;
function groupFetched(responseText, textStatus, xhr) {
  var obj = $(this);
  var handles = obj.find('.column-header .handle');
  handles.draggable({
    axis: 'x',
    start: function(e, ui) {
      previousPosition = ui.position;
    },
    drag: function(e, ui) {
      var handle = $(this);
      var header = handle.parent();
      var originalWidth = header.width();
      var container = header.parent();
      var diff = ui.position.left - previousPosition.left;
      var newWidth = originalWidth + diff;

      if (newWidth < 15) {
        // don't allow the column to be smaller than 15
        return false;
      }

      var newTotalWidth = container.width() + container.siblings('.result-group').width() + diff;
      if (newTotalWidth > contentWidth) {
        // TODO: make the column to the right smaller
        return false;
      }

      var selector = header.hasClass('column-name') ? '.column-name' : '.column-value';
      header.width(newWidth);
      header.siblings(selector).width(newWidth);

      previousPosition = ui.position;
    },
  });
}
