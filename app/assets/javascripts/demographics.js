$(function() {
  if ($('#demographic_info_after_graduation').val() !== 'Other (please explain)') {
    $('#after_graduation_explanation').hide();
  }
  if ($('#demographic_info_after_graduation').val() !== "Look for a full-time job that requires the skills I'll learn at Epicodus" && $('#demographic_info_after_graduation').val() !== "Look for a part-time job that requires the skills I'll learn at Epicodus") {
    $('#time_off').hide();
  }

  $('#demographic_info_after_graduation').change(function() {
    if ($(this).val() === 'Other (please explain)') {
      $('#after_graduation_explanation').show();
      $('#demographic_info_after_graduation_explanation').focus();
    } else {
      $('#after_graduation_explanation').hide();
    }
    if ($(this).val() === "Look for a full-time job that requires the skills I'll learn at Epicodus" || $(this).val() === "Look for a part-time job that requires the skills I'll learn at Epicodus") {
      $('#time_off').show();
    } else {
      $('#time_off').hide();
    }
  });

  // enforces numbers only; adds dashes in correct places
  $('#demographic_info_ssn').keyup(function(event) {
    var selection = window.getSelection().toString();
    if (selection !== '' || $.inArray( event.keyCode, [38,40,37,39,8] ) !== -1) {
      return; // ignore arrow keys and backspace
    }
    var val = this.value.replace(/\D/g, '');
    var newVal = '';
    if(val.length > 4) {
      this.value = val;
    }
    if((val.length > 3) && (val.length < 6)) {
      newVal += val.substr(0, 3) + '-';
      val = val.substr(3);
    }
    if (val.length > 5) {
      newVal += val.substr(0, 3) + '-';
      newVal += val.substr(3, 2) + '-';
      val = val.substr(5);
    }
    newVal += val;
    if(newVal.length === 3 || newVal.length === 6) {
      newVal += '-';
    }
    this.value = newVal.substring(0, 11);
  });
});
