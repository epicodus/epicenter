$(function() {

  var submitAccountInfo = function(event) {
    alert('form is being submitted')
    event.preventDefault();

    var $email = $("input#user_email"),
    $name = $("input#user_name"),
    $password = $("input#user_password"),
    $passwordConfirmation = $("input#user_password_confirmation"),
    $bankAccountNumber = $("input#bank_account_number"),
    $routingNumber = $("input#routing_number");

    var formHasErrors = false;

    if (!balanced.emailAddress.validate($email.val())) {
      addErrorToField($email);
      formHasErrors = true;
    }

    if (!$name.val()) {
      addErrorToField($name);
      formHasErrors = true;
    }

    if (!$password.val()) {
      addErrorToField($password);
      formHasErrors = true;
    }

    if (!$passwordConfirmation.val()) {
      addErrorToField($passwordConfirmation);
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
      alert('form does not have any errors')
      var payload = {
        name: $name.val(),
        routing_number: $routingNumber.val(),
        account_number: $bankAccountNumber.val()
      };
      console.log(payload)
      balanced.bankAccount.create(payload, handleResponse);
    }
  }

  function handleResponse(response) {
    alert('handling response!')
    if (response.status_code === 201) {
      var $form = $('form#new_user')
      var uri = response.bank_accounts[0].href

      $("input#bank_account_number").val('');
      $("input#routing_number").val('');

      $form.append('<input id="user_uri" name="user[uri]" type="hidden" value="' + uri + '">');
      alert('about to submit the form!!')
      $form.unbind('submit').submit();

    } else {
      return ;
    }
  }


  var addErrorToField = function ($field) {
    $field.parent('div').addClass('error');
  };

  $('form#new_user').submit(submitAccountInfo);
});


