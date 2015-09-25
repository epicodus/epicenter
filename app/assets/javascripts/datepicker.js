$(function() {
  $('.datepicker').datepicker({
    format: "yyyy-mm-dd",
    multidate: true,
    todayHighlight: true,
    daysOfWeekDisabled: '0,6'
  });
});
