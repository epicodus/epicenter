$(function() {
  $('.datepicker').datepicker({
    format: "yyyy-mm-dd",
    multidate: true,
    todayHighlight: true,
    daysOfWeekDisabled: '0,5,6'
  });

  $(".datepicker").on("changeDate", function(event) {
    $("#cohort_class_days").val($(".datepicker").datepicker('getFormattedDate'));
  });
});
