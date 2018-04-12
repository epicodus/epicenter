$(function() {
  $('.sortable-list').sortable({
  });

  $('.update-multiple').submit(function() {
    var count = 1;
    $(this).first('form').find('input.sortable-number').each(function() {
      $(this).val(count++);
    });
  });

  $(".mark-all-objectives").click(function() {
    var list = document.getElementsByClassName('objectives-scores');
    for (var i = 0; i < list.length; i++) {
      valueToSet = parseInt($(this).attr('id').split('_').pop())
      list[i].value=valueToSet;
    }
  });
});
