var currencyRegex = /^\d{1,4}(\.\d{2})?$/;

$(function() {
  $('.payment-refund-button').click(function() {
    var id = $(this).attr('id').split('-')[1];
    var inputRefundAmount = $('#refund-' + id + '-input').val();
    var inputBasisAmount = $('#refund-basis-' + id + '-input').val();
    if (!currencyRegex.test(inputRefundAmount) || !currencyRegex.test(inputBasisAmount)) {
      alert('Please enter valid amounts.');
      return false;
    }
  });

  $('.payment-button').click(function() {
    var inputAmount = $(this).parents('.input-group').find('.payment-input').val();
    if (!currencyRegex.test(inputAmount)) {
      alert('Please enter a valid amount.');
      return false;
    }
  });

  $('.show-refund-form-button').click(function() {
    $(this).parent().find('.refund-form').removeClass('hidden');
    $(this).hide();
  });
});
