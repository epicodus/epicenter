$(function() {
  $('.sortable-code-reviews').sortable({
  });

  $('form.update-multiple-code-reviews').submit(function() {
    var count = 1;
    $('input.code-review-number').each(function() {
      $(this).val(count++);
    });
  });
});
