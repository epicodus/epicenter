$(function() {
  $('.sortable-list').sortable({
  });

  $('.update-multiple').submit(function() {
    var count = 1;
    $(this).first('form').find('input.sortable-number').each(function() {
      $(this).val(count++);
    });
  });
});
