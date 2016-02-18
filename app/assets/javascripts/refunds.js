$(function() {
  $('.refund-button').click(function() {
    var refundInput = $(this).parents('.input-group').find('.refund-input');
    if (refundInput.val().split('.')[1].length !== 2) {
      alert('Please enter a refund amount that includes 2 decimal places.');
      return false;
    }
  });
});
