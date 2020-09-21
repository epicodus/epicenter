$(function() {
  $('#student_probation_teacher').change(function() {
    var prompt = this.checked ? 'Are you sure you want to put this student on academic probation (TEACHER)?' : 'Remove student from academic probation (TEACHER)?'
    var confirmed = confirm(prompt);
    if (confirmed) {
      this.form.submit();
    } else {
      $(this).prop("checked", !$(this).prop("checked"));
    }
  });

  $('#student_probation_advisor').change(function() {
    var prompt = this.checked ? 'Are you sure you want to put this student on academic probation (ADVISOR)?' : 'Remove student from academic probation (ADVISOR)?'
    var confirmed = confirm(prompt);
    if (confirmed) {
      this.form.submit();
    } else {
      $(this).prop("checked", !$(this).prop("checked"));
    }
  });
});
