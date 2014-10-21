def sign_in(user)
  visit new_user_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_button 'Sign in'
end

def create_balanced_bank_account
  balanced_bank_account = Balanced::BankAccount.new(
    :account_number => '9900000002',
    :account_type => 'checking',
    :name => 'Johann Bernoulli',
    :routing_number => '021000021'
  ).save
  balanced_bank_account
end

def create_balanced_credit_card
  balanced_credit_card = Balanced::Card.new(
    :number => '4111111111111111',
    :expiration_month => '12',
    :expiration_year => '2020',
    :cvv => '123'
  ).save
  balanced_credit_card
end

def create_invalid_balanced_credit_card
  balanced_credit_card = Balanced::Card.new(
    :number => '4444444444444448',
    :expiration_month => '12',
    :expiration_year => '2020',
    :cvv => '123'
  ).save
  balanced_credit_card
end

def correctly_verify_bank_account(user)
  fill_in 'First deposit amount', with: '1'
  fill_in 'Second deposit amount', with: '1'
  click_on 'Confirm account & start payments'
end
