$(function() {
  $('.custom-datepicker').datepicker({
    format: "yyyy-mm-dd",
    multidate: true,
    todayHighlight: true,
    daysOfWeekDisabled: '0,6'
  });

  $(".custom-datepicker").on("changeDate", function() {
    $("#course_class_days").val($(".custom-datepicker").datepicker('getFormattedDate'));
  });
});
