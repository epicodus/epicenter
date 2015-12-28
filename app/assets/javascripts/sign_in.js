$(function() {
  $('.pair-sign-in').hide();
  $('.solo').hide();
  $('.pairing').click(function() {
    $('.pair-sign-in').show('blind');
    $('.solo').show();
    $('.solo-group').hide();
  });

  $('.solo').click(function() {
    $('.pair-sign-in').hide();
    $('.solo').hide();
    $('.solo-group').show();
  });
});
