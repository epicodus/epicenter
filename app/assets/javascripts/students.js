$(function() {
  $('div').find('div.' + $('#student-nav li:first').attr('class')).show();  // shows the content of the first tab
  $('div').find('div.' + $('#student-nav li:first').attr('class')).siblings('.student-div').hide();  // hides the content of all the other tabs
  $('#student-nav li:first').addClass("active");  // sets the first tabs class to 'active'

  $('#student-nav li').each(function() {
    $(this).click(function() {
      var matchingDiv = $('div').find('div.' + $(this).attr('class'));  // finds the div with the matching class
      matchingDiv.show();  // shows the div that was clicked
      matchingDiv.siblings('.student-div').hide();  // hides all other divs
      $(this).addClass('active');  // adds 'active' class to clicked div
      $(this).siblings().removeClass('active');  // removes 'active' class from anyother div
    });
  });
});
