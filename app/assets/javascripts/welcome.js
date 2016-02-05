$(function() {
  $('#welcome-links').hide();

  $('#welcome-continue').click(function() {
    $('#welcome-continue').hide();
    $('#welcome-links').show();
  });
});
