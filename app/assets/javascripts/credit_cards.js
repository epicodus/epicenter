$(function() {
  $('form#new_credit_card').submit(function(event) {
    event.preventDefault();

    var formData = {
      name: $('input#name').val(),
      number: $('input#card_number').val(),
      expiration_month: $('input#expiration_month').val(),
      expiration_year: $('input#expiration_year').val(),
      cvv: $('input#cvv_code').val(),
      address: {
        postal_code: $('input#zip_code').val()
      }
    };
    Stripe.card.createToken(formData, handleResponseCreditCard);
  });
});

var handleResponseCreditCard = function(status, response) {
  if (status === 200) {
    // var uri = response.card.href;
    // $("input#credit_card_account_uri").val(uri);

    $("input#card_number").val('****************');
    $("input#cvv_code").val('***');
    $("input#expiration_month").val('**');
    $("input#expiration_year").val('****');

    var token = response.id;
    $('form#new_credit_card').append($('<input type="hidden" name="stripeToken" />').val(token));
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

    response.errors.forEach(function(error) {
      $('.alert-error ul').append('<li>' + error.description + '</li>');
    });
  }
};
