$(function() {
  $('#teacher-meeting').change(function() {
    $('#teacher-meeting-explanation').toggleClass('hide');
    $('#teacher-meeting-skip-button').toggleClass('hide')
    $('#teacher-meeting-submit-button').toggleClass('hide')
    $('#teacher-meeting-explanation').focus();
  });
});
