$(function() {
  $('#offline-payment-checkbox').click(function() {
    if ($('#offline-payment-checkbox:checked').length > 0) {
      $('#payment-method-options').hide();
      $('#payment_payment_method_id').val('');
    } else {
      $('#payment-method-options').show();
    }
  });

  $('#payment_category').change(function() {
    show_or_hide_payment_warning();
  });

  $('.payment-input').keyup(function() {
    show_or_hide_payment_warning();
  });
});

var show_or_hide_payment_warning = function() {
  if ( $('#payment_category').val() === 'tuition' && parseInt($('#payment_amount').val()) > 0 ) {
    $('#payment-warning').show();
  } else {
    $('#payment-warning').hide();
  }
};
