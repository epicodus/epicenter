$(function() {
  $('form#new_bank_account').submit(function(event) {
    event.preventDefault();

    var formData = {
      routing_number: $("input#routing_number").val(),
      account_number: $("input#bank_account_number").val(),
      name: $("input#name").val(),
      country: $("input#country").val()
    };
    Stripe.bankAccount.createToken(formData, stripeResponseHandler);
  });
});

var stripeResponseHandler = function(status, response) {
  if (status === 200) {

    $("input#bank_account_number").val('*********');
    $("input#routing_number").val('*********');
    var token = response.id;
    $('input#bank_account_stripe_token').val(token);
    $('form#new_bank_account').unbind('submit').submit();
    $('#account-submit-button').val('loading...').attr('disabled', 'disabled');
  } else {
    $('div.alert-error').remove();
    $('form#new_bank_account').prepend(
      '<div class="alert alert-error">' +
        '<h3>Please correct these problems:</h3>' +
        '<ul>' +
        '</ul>' +
      '</div>'
    );
    var errorMapping = {
      "Routing number must have 9 digits": "Invalid routing number."
    }
    var errorMessage = errorMapping[response.error.message];
    $('.alert-error ul').append('<li>' + errorMessage + '</li>');
  }
};
