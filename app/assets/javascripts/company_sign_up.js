$(function() {
  $('.multiselect-dropdown').multiselect({
    buttonClass: 'btn btn-info',
    maxHeight: 500,
    includeSelectAllOption: true,
    buttonWidth: '150px'
  });

  $('#company-sign-up-button').click(function() {
    if ($('input[type=checkbox]:checked').length === 0 && $('#course-multiselect-warning').length !== 1) {
      $('#course-multiselect').append(
        '<span class="text-primary" id="course-multiselect-warning">* Please select a course</span>'
      );
    }
  });
});
