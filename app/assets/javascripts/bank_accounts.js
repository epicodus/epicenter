$(function() {
  $('form#new_bank_account').submit(function(event) {
    event.preventDefault();
    var formData = {
      routing_number: $("input#routing_number").val(),
      account_number: $("input#bank_account_number").val(),
      account_holder_name: $("input#account_holder_name").val(),
      account_holder_type: $("#account_holder_type").val().toLowerCase(),
      country: $("input#country").val(),
      currency: $("input#currency").val()
    };
    Stripe.bankAccount.createToken(formData, stripeBankAccountResponseHandler);
  });
});

var stripeBankAccountResponseHandler = function(status, response) {
  if (status === 200) {
    $("input#bank_account_number").val('************');
    $("input#routing_number").val('*********');
    $("input#country").val();
    $("input#currency").val();
    var token = response.id;
    $('input#bank_account_stripe_token').val(token);
    $('form#new_bank_account').unbind('submit').submit();
    $('#account-submit-button').val('loading...').attr('disabled', 'disabled');
  } else {
    $('div.alert-danger').remove();
    $('form#new_bank_account').prepend(
      '<div class="alert alert-danger">' +
        '<h3>Please correct these problems:</h3>' +
        '<ul>' +
        '</ul>' +
      '</div>'
    );
    var errorMapping = {
      "You cannot use a live bank account number when making transfers or debits in test mode": "Invalid bank account number.",
      "Must only use a test bank account number when making transfers or debits in test mode": "Invalid bank account number.",
      "Routing number must have 9 digits": "Invalid routing number.",
      "A bank account with that routing number and account number already exists for this customer.": "Please enter a new account."
    };
    var errorMessage = errorMapping[response.error.message] || response.error.message;
    $('.alert-danger ul').append('<li>' + errorMessage + '</li>');
  }
};
