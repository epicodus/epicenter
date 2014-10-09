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

def correctly_verify_bank_account(user)
  fill_in 'First deposit amount', with: '1'
  fill_in 'Second deposit amount', with: '1'
  click_on 'Confirm account & start payments'
end
