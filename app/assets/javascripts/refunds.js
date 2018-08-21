var positiveCurrencyRegex = /^\d{1,4}(\.\d{2})?$/;
var negativeOrPositiveCurrencyRegex = /^-?\d{1,4}(\.\d{2})?$/;

$(function() {
  $('.payment-refund-button').click(function() {
    var id = $(this).attr('id').split('-')[1];
    var inputRefundAmount = $('#refund-' + id + '-input').val();
    if (!positiveCurrencyRegex.test(inputRefundAmount)) {
      alert('Please enter a valid amount.');
      return false;
    }
  });

  $('.payment-button').click(function() {
    var inputAmount = $(this).parents('.input-group').find('.payment-input').val();
    if (!positiveCurrencyRegex.test(inputAmount)) {
      alert('Please enter a valid amount.');
      return false;
    }
  });

  $('#adjust-student-cost-button').click(function() {
    var inputAmount = $("#cost_adjustment_amount").val();
    if (!negativeOrPositiveCurrencyRegex.test(inputAmount)) {
      alert('Please enter a valid amount.');
      return false;
    }
  });

  $('.show-refund-form-button').click(function() {
    $(this).parent().find('.refund-form').removeClass('hidden');
    $(this).hide();
  });

  $('#show-student-tuition-adjustment').click(function() {
    $('#cost-adjustment-form').removeClass('hidden')
    $(this).hide();
  });
});
