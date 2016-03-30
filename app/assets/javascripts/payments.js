$(function() {
  $('#offline-payment-checkbox').click(function() {
    if ($('#offline-payment-checkbox:checked').length > 0) {
      $('#payment-method-options').hide();
      $('#payment_payment_method_id').val('');
    } else {
      $('#payment-method-options').show();
    };
  });
});
