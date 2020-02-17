$(function() {
  $('.custom-datepicker').datepicker({
    format: "yyyy-mm-dd",
    multidate: true,
    todayHighlight: true
  });

  $(".custom-datepicker").on("changeDate", function() {
    $("#course_class_days").val($(".custom-datepicker").datepicker('getFormattedDate'));
  });
});
