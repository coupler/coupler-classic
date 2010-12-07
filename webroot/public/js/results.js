var contentWidth, previousPosition;

function getRecord(div, index, which) {
  var data = {index: index};
  if (typeof(which) != "object") {
    data['which'] = which;
  }
  div.load(detailsUrl, data, groupFetched);
}

function startCallback(e, ui) {
  previousPosition = ui.position;
}

function dragCallback(e, ui) {
  var handle = $(this);
  var column = handle.parent();
  var originalWidth = column.width();
  var container = column.parent();
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

  var selector = column.hasClass('column-name') ? '.column-name' : '.column-value';
  container.find(selector).width(newWidth);

  previousPosition = ui.position;
}

function groupFetched(responseText, textStatus, xhr) {
  var div = $(this);
  div.find('.resize-handle').draggable({
    axis: 'x',
    start: startCallback,
    drag: dragCallback,
  });
  div.find('.record-nav').click(function() {
    var button = $(this);
    var klass = button.attr('class')
    var which = klass.match(/which-(\d)/);
    var num = klass.match(/record-(\d+)/);
    if (num) {
      getRecord(div, num[1], which ? which[1] : null);
    }
  });
}
