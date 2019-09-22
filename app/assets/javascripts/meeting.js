$(function() {
  $('#teacher-meeting').change(function() {
    $('#teacher-meeting-explanation').toggleClass('hide');
    $('#teacher-meeting-skip-button').toggleClass('hide')
    $('#teacher-meeting-submit-button').toggleClass('hide')
    $('#teacher-meeting-explanation').focus();
  });
  $('#teacher-meeting-submit-button').click(function(e) {
    if ($('#teacher-meeting-explanation').val().length < 50) {
      e.preventDefault();
      alert('Please enter explanation (50 character minimum).')
    }
  });
});
