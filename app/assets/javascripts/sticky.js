$(document).ready(function() {
  $('#sticky-note-content').on('click', function() {
    $(this).hide();
    $('#sticky-note-form').removeClass('hidden');
  });
});
