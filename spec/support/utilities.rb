def sign_in(user)
  visit new_student_session_path
  fill_in 'Email', with: user.email
  fill_in 'Password', with: user.password
  click_button 'Sign in'
end

def create_balanced_bank_account
  Balanced::BankAccount.new(
    :account_number => '9900000002',
    :account_type => 'checking',
    :name => 'Johann Bernoulli',
    :routing_number => '021000021'
  ).save
end

# def create_stripe_bank_account
#   Stripe::BankAccount.new(
#     :account_number => '000123456789',
#     :account_type => 'bank_account',
#     :name => 'Johann Bernoulli',
#     :routing_number => '110000000'
#   ).save
# end

def create_balanced_credit_card
  Balanced::Card.new(
    :number => '4111111111111111',
    :expiration_month => '12',
    :expiration_year => '2020',
    :cvv => '123'
  ).save
end

# def create_stripe_credit_card
#   Stripe::Card.new(
#     :number => '4242424242424242',
#     :expiration_month => '12',
#     :expiration_year => '2020',
#     :cvv => '123'
#   ).save
# end

def create_invalid_balanced_credit_card
  Balanced::Card.new(
    :number => '4444444444444448',
    :expiration_month => '12',
    :expiration_year => '2020',
    :cvv => '123'
  ).save
end

# def create_invalid_stripe_credit_card
#   Stripe::Card.new(
#     :number => '4444444444444448',
#     :expiration_month => '12',
#     :expiration_year => '2020',
#     :cvv => '123'
#   ).save
# end
