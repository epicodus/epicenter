$(function() {
  $('.attendance-adjust').change(function() {
    $(this).closest('form').trigger('submit');
  });
});
