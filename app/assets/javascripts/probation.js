$(function() {
  $('#student_probation').change(function() {
    var prompt = this.checked ? 'Are you sure you want to put this student on academic probation?' : 'Remove student from academic probation?'
    var confirmed = confirm(prompt);
    if (confirmed) {
      this.form.submit();
    } else {
      $(this).prop("checked", !$(this).prop("checked"));
    }
  });
});
