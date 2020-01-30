$(function() {
  $('.review-note-edit-button').click(function() {
    $(this).closest('.review-note-display').toggleClass('hide');
    $(this).closest('.review-note').children('.review-note-edit').toggleClass('hide');
  });
});
