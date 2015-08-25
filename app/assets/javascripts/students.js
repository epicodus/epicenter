$(function() {
  $('.student-internships').hide();

  $('.student-internships-header').click(function() {
    $('.student-attendance').hide();
    $('.student-internships').show();
    $('.student-attendance-header').removeClass("active");
    $('.student-internships-header').addClass("active");
  });

  $('.student-attendance-header').click(function() {
    $('.student-internships').hide();
    $('.student-attendance').show();
    $('.student-attendance-header').addClass("active");
    $('.student-internships-header').removeClass("active");
  });
});
