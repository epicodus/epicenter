$(function() {
  $('.ticket-note').hide();
  $('.ticket').click(function() {
    $('#' + $(this).attr('id') + '-note').toggle();
  });
});
