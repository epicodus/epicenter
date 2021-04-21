document.addEventListener('DOMContentLoaded', (event) => {
  document.getElementById('move-submissions-button').onclick = function() {
    this.classList.add('hide');
    document.getElementById('move-submissions-list').classList.remove('hide');
  }
});

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

  $('.objectives-scores').each(function() {
    colorObjectiveScores($(this));
  });

  $('.objectives-scores').change(function() {
    colorObjectiveScores($(this));
  });
});

var colorObjectiveScores = function(obj) {
  var colors = ['', 'red', 'yellow', 'green']
  obj.removeClass('red');
  obj.removeClass('yellow');
  obj.removeClass('green');
  var score = obj.val();
  var color = colors[score];
  obj.addClass(color);
};
