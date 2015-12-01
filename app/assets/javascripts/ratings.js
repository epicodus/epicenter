$(function() {
  $('.rating-text-area').keyup(function() {
    text_length = $(this).val().length;
    $(this).closest('li').find('p').html(text_length + ' characters');

    if ($(this).val().length < 10) {
      $(this).parent().addClass('has-error');
      $('#fixed-ratings-button').attr('disabled', true);
      $('#rating-button').attr('disabled', true);
    } else if ($(this).val().length > 9) {
      $(this).parent().removeClass('has-error');
      $('#fixed-ratings-button').attr('disabled', false);
      $('#rating-button').attr('disabled', false);
    }

    if (!$(this).val() && $(this).parent().hasClass('has-error')) {
      $(this).parent().removeClass('has-error');
      $('#fixed-ratings-button').attr('disabled', false);
      $('#rating-button').attr('disabled', false);
    }
  });

  $('input:radio[value=3]').change(function() {
    if ($('input:radio:checked[value=3]').length > 5) {
      $(this).attr('checked', false);
      $(this).parent().removeClass('active');
      $(this).tooltip('toggle');
    }
  });

  $('input:text, textarea').change(function() {
    $(this).closest('li').find($('input:radio')).attr('required', true)
  });

  $('input:radio').change(function() {
    $(this).closest('li').find($('input:text, textarea')).attr('required', true);
  });
});
