$(function() {
  $('#student_probation_teacher').change(function() {
    var prompt = this.checked ? 'Are you sure you want to put this student on Academic Warning (TEACHER)?' : 'Remove student from Academic Warning (TEACHER)?'
    var confirmed = confirm(prompt);
    if (confirmed) {
      this.form.submit();
    } else {
      $(this).prop("checked", !$(this).prop("checked"));
    }
  });

  $('#student_probation_advisor').change(function() {
    var prompt = this.checked ? 'Are you sure you want to put this student on Academic Warning (ADVISOR)?' : 'Remove student from Academic Warning (ADVISOR)?'
    var confirmed = confirm(prompt);
    if (confirmed) {
      this.form.submit();
    } else {
      $(this).prop("checked", !$(this).prop("checked"));
    }
  });

  $('#edit-checkins-count').click(function() {
    $('#complete-checkin-form').hide();
    $('#modify-checkin-form').removeClass('hidden');
  });
});
