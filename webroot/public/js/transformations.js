function previewTransformation() {
  $('#transformation-preview').html('');
  $('#spinner').show();
  $('#transformation-result').fadeIn('fast');
  $.post(previewUrl, $('form').serialize(), function(data, status, xhr) {
    $('#spinner').hide();
    $('#transformation-preview').html(data);
  }, 'html');
}
$.fn.disableInputs = function() {
  this.find(':input').attr('disabled', true);
  return this;
}
$.fn.enableInputs = function() {
  this.find(':input').removeAttr('disabled');
  return this;
}
$(function() {
  $('#source_field_id').combobox().change(function() {
    var source_field_id = $(this).val();
    $('input[name=transformation\\[source_field_id\\]]').val(source_field_id);

    var field = fields[source_field_id];
    $('#source-field-name').html(field.name);
    $('#field-type').html(field.type);
    $('#field-db-type').html(field.db_type);
    $('#field-info').fadeIn('fast');
    $('#result-field-same').val(source_field_id);

    /* populate transformer select box */
    var sel = $('#transformer_id').html('<option></option>');
    var empty = true;
    $.each(transformers, function(id, transformer) {
      if ($.inArray(field.type, transformer.allowed_types) >= 0) {
        $('<option></option>')
          .attr('value', id)
          .html(transformer.name)
          .appendTo(sel);
        empty = false;
      }
    });
    if (empty) {
      $('#transformer-attributes').enableInputs().show();
      $('#result-field-selection').enableInputs().fadeIn('fast');
    }
    else {
      $('#transformer-select').enableInputs().show();
    }
    $('#transformer').fadeIn('fast');
  });
  $('#transformer_id').combobox().change(function() {
    var transformer_id = $(this).val();
    $('input[name=transformation\\[transformer_id\\]]').val(transformer_id);

    var transformer = transformers[transformer_id];
    $('#transformer-name').html(transformer.name);
    $('#transformer-result-type').html(transformer.result_type);
    $('#transformer-info').fadeIn('fast');
    $('#result-field-selection').enableInputs().fadeIn('fast');
  });
  $('#create-transformer').button().click(function(e) {
    $('input[name=transformation\\[transformer_id\\]]').val('');
    $('#transformer-select').disableInputs().fadeOut('fast', function() {
      $('#transformer-attributes').enableInputs().fadeIn('fast');
      $('#result-field-selection').enableInputs().fadeIn('fast');
    });
    e.preventDefault();
  });
  $('input[name=transformation\\[result_field_id\\]]').change(function() {
    var val = $(this).val();
    if (val) {
      $('#result-field-attributes').disableInputs().hide();
      previewTransformation();
    }
    else {
      $('#result-field-attributes').enableInputs().fadeIn('fast');
      if ($('#result-field-name').val()) {
        previewTransformation();
      }
      else {
        $('#transformation-result').hide();
      }
    }
  });
  $('#result-field-name').change(function() {
    previewTransformation();
  });
  $('#transformer-code').change(function() {
    if ($('#transformation-result').is(':visible')) {
      previewTransformation();
    }
  });
});
