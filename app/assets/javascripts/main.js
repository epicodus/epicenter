$(function() {
  $('form#new_subscription').submit(function(event) {
    event.preventDefault();

    var formData = {
      routing_number: $("input#routing_number").val(),
      account_number:$("input#bank_account_number").val(),
      name:$("input#name").val()
    };

    balanced.bankAccount.create(formData, handleResponse);
  });
});

var handleResponse = function(response) {
  if (response.status_code === 201) {
    var uri = response.bank_accounts[0].href;
    $("input#subscription_account_uri").val(uri);

    $("input#bank_account_number").val('*********');
    $("input#routing_number").val('*********');

    $('form#new_subscription').unbind('submit').submit();
    $('#account-submit-button').val('loading...').attr('disabled', 'disabled');
  } else {
    $('div.alert-error').remove();
    $('form#new_subscription').prepend(
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
