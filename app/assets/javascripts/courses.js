$(function() {
  $('#course_internship_course').click(function() {
    if ($(this).is(':checked')) {
      $('#course_active').val(true);
    } else {
      $('#course_active').val(null);
    }
  });

  $('.show-assign-courses').first().addClass('active');
  $('.assign-courses-to-student').first().show();
  $('.show-assign-courses').click(function() {
    var office = $(this).find('a').text();
    $(this).siblings().removeClass('active');
    $(this).addClass('active');
    $('.assign-courses-to-student').hide();
    $('#assign-courses-previous').hide();
    $('#assign-courses-current-and-future-' + office).show();
  });
  $('#show-assign-courses-previous').click(function() {
    $(this).siblings().removeClass('active');
    $(this).addClass('active');
    $('.assign-courses-to-student').hide();
    $('#assign-courses-previous').show();
  });
});
