$(function() {
  $('div').find('div.' + $('.student-nav li:first').attr('class')).show();
  $('div').find('div.' + $('.student-nav li:first').attr('class')).siblings('.student-div').hide();
  $('.student-nav li:first').addClass("active");

  $('.student-nav li').each(function() {
    $(this).click(function() {
      var matchingDiv = $('div').find('div.' + $(this).attr('class'));
      matchingDiv.show();
      matchingDiv.siblings('.student-div').hide();
      $(this).addClass('active');
      $(this).siblings().removeClass('active');
    });
  });
});
