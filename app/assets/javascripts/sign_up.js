$(function() {
  $('#pair_email').change(function() {
    if ($(this).val() !== '') {
      $('#solo-sign-in-button').attr('disabled', true);
    } else {
      $('#solo-sign-in-button').attr('disabled', false);
    }
  });
});
