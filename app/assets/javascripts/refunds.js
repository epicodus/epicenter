$(function() {
  $('.payment-button').click(function() {
    var paymentInput = $(this).parents('.input-group').find('.payment-input');
    if (paymentInput.val().split('.')[1].length !== 2) {
      alert('Please enter an amount that includes 2 decimal places.');
      return false;
    }
  });
});
