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
});
