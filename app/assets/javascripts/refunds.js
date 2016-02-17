$(function() {
  $('#refund-button').click(function() {
    if ($('#refund-input').val().split('.')[1].length !== 2) {
      alert('Please enter a refund amount that includes 2 decimal places.');
      return false;
    }
  });
});
