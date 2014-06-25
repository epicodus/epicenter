$(function() {
  var handleResponse = function(response) {
    if (response.status_code === 201) {
      var $form = $('form#new_subscription');
      var uri = response.bank_accounts[0].href;

      $("input#subscription_account_uri").val(uri);
      $("input#bank_account_number").val('*********');
      $("input#routing_number").val('*********');
      $form.unbind('submit').submit();

      $('#account-submit-button').val('loading...').attr('disabled', 'disabled')

    } else {
      return;
    }
  }

  var submitAccountInfo = function(event) {
    event.preventDefault();

    var $name = $("input#name"),
    $bankAccountNumber = $("input#bank_account_number"),
    $routingNumber = $("input#routing_number");

    var formHasErrors = false;

    if (!$name.val()) {
      addErrorToField($name);
      formHasErrors = true;
    }

    if (!$bankAccountNumber.val()) {
      addErrorToField($bankAccountNumber);
      formHasErrors = true;
    }

    if (!balanced.bankAccount.isRoutingNumberValid($routingNumber.val())) {
      addErrorToField($routingNumber);
      formHasErrors = true;
    }

    if (!formHasErrors) {
      var payload = {
        name: $name.val(),
        routing_number: $routingNumber.val(),
        account_number: $bankAccountNumber.val()
      };
      balanced.bankAccount.create(payload, handleResponse);
    }
  };

  var addErrorToField = function ($field) {
    $field.parent('div').addClass('error');
  };

  $('form#new_subscription').submit(submitAccountInfo);
});
