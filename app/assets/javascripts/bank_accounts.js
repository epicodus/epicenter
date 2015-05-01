$(function() {
  $('form#new_bank_account').submit(function(event) {
    event.preventDefault();

    var formData = {
      routing_number: $("input#routing_number").val(),
      account_number: $("input#bank_account_number").val(),
      name: $("input#name").val()
    };

    Stripe.bankAccount.createToken(formData, stripeResponseHandler);
  });
});

var stripeResponseHandler = function(status, response) {
  if (status === 200) {
    // var uri = response.bank_account.href;
    // $("input#bank_account_account_uri").val(uri);

    $("input#bank_account_number").val('*********');
    $("input#routing_number").val('*********');
    var token = response.id;
    $('form#new_bank_account').append($('<input type="hidden" name="stripeToken" />').val(token));
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

    response.errors.forEach(function(error) {
      $('.alert-error ul').append('<li>' + error.message + '</li>');
    });
  }
};
