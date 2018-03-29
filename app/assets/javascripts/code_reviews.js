$(function() {
  $('.sortable-list').sortable({
  });

  $('.update-multiple').submit(function() {
    var count = 1;
    $(this).first('form').find('input.sortable-number').each(function() {
      $(this).val(count++);
    });
  });

  $("#all_green").click(function() {
    var list = document.getElementsByClassName('objectives-scores');
    for (var i = 0; i < list.length; i++) {
      list[i].value=3;
    }
  });
  $("#all_yellow").click(function() {
    var list = document.getElementsByClassName('objectives-scores');
    for (var i = 0; i < list.length; i++) {
      list[i].value=2;
    }
  });
  $("#all_red").click(function() {
    var list = document.getElementsByClassName('objectives-scores');
    for (var i = 0; i < list.length; i++) {
      list[i].value=1;
    }
  });
});
