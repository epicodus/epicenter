$(function() {
  $('.class-stats').hide();

  $('.day-attendance-header').click(function() {
    $('.class-stats').hide();
    $('.day-stats').show();
    $('.class-attendance-header').removeClass("active");
    $('.day-attendance-header').addClass("active");
  });

  $('.class-attendance-header').click(function() {
    $('.day-stats').hide();
    $('.class-stats').show();
    $('.class-attendance-header').addClass("active");
    $('.day-attendance-header').removeClass("active");
  });
});
