$(function() {
  $('form#new_credit_card').submit(function(event) {
    event.preventDefault();

    var formData = {
      name: $('input#name').val(),
      number: $('input#card_number').val(),
      exp_month: $('input#expiration_month').val(),
      exp_year: $('input#expiration_year').val(),
      cvc: $('input#cvc_code').val(),
      address_zip: $('input#zip_code').val(),
    };
    Stripe.card.createToken(formData, stripeResponseHandler);
  });
});

var stripeResponseHandler = function(status, response) {
  if (status === 200) {
    $("input#card_number").val('****************');
    $("input#cvc_code").val('***');
    $("input#expiration_month").val('**');
    $("input#expiration_year").val('****');
    $("input#zip_code").val()
    var token = response.id;
    $('input#credit_card_stripe_token').val(token);
    $('form#new_credit_card').unbind('submit').submit();
    $('#card-submit-button').val('loading...').attr('disabled', 'disabled');
  } else {
    $('div.alert-error').remove();
    $('form#new_credit_card').prepend(
      '<div class="alert alert-error">' +
        '<h3>Please correct these problems:</h3>' +
        '<ul>' +
        '</ul>' +
      '</div>'
    );
    var errorMapping = {
      "Your card number is incorrect.": "Your card number is incorrect.",
      "The 'exp_month' parameter should be an integer (instead, is  ).": "Enter a valid integer value."
    };
    var errorMessage = errorMapping[response.error.message] || response.error.message;
    $('.alert-error ul').append('<li>' + errorMessage + '</li>');
  };
};
