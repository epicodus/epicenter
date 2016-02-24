$(function() {
  $('.payment-refund-button').click(function() {
    var inputAmount = $(this).parents('.input-group').find('.payment-refund-input');
    if (inputAmount.val().split('.')[1].length !== 2) {
      alert('Please enter an amount that includes 2 decimal places.');
      return false;
    }
  });
});
