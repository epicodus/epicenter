$(function() {
  $('input.grade-submit').remove();
  $('input[type=radio]').click(function() {
      alert(this);
    $(this).closest('tr').find('form').submit();
  });
  return this;
});
