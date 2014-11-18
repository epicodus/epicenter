def sign_in(user)
  visit new_student_session_path
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

def balanced_callback_debit_failed_json(payment_uri)
  {"events"=>
   [{"links"=>{},
     "occurred_at"=>"2014-11-17T23:43:17.456676Z",
     "uri"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
     "entity"=>
      {"debits"=>
        [{"status"=>"failed",
          "description"=>nil,
          "links"=>{"customer"=>nil, "source"=>"CC2snUSXCoAQaPtL3BnnWnYs", "dispute"=>nil, "order"=>nil, "card_hold"=>"HL3b3T4TPIyhDF0uTggaJmXC"},
          "amount"=>500,
          "created_at"=>"2014-11-17T23:43:15.893613Z",
          "updated_at"=>"2014-11-17T23:43:17.456676Z",
          "failure_reason"=>nil,
          "currency"=>"USD",
          "transaction_number"=>"WHSY-KZO-02ID",
          "href"=>payment_uri,
          "meta"=>{},
          "failure_reason_code"=>nil,
          "appears_on_statement_as"=>"BAL*Epicodus tuition",
          "id"=>"WD3b6phETOvHyNaZtQ5a7zUs"}],
       "links"=>
        {"debits.customer"=>"/customers/{debits.customer}",
         "debits.dispute"=>"/disputes/{debits.dispute}",
         "debits.card_hold"=>"/holds/{debits.card_hold}",
         "debits.events"=>"/debits/{debits.id}/events",
         "debits.order"=>"/orders/{debits.order}",
         "debits.refunds"=>"/debits/{debits.id}/refunds",
         "debits.source"=>"/resources/{debits.source}"}},
     "href"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
     "type"=>"debit.failed",
     "id"=>"EV69b2c37c6eb311e48c66060a33130f9b"}],
  "links"=>{},
  "action"=>"create",
  "controller"=>"balanced_events",
  "balanced_event"=>
   {"events"=>
     [{"links"=>{},
       "occurred_at"=>"2014-11-17T23:43:17.456676Z",
       "uri"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
       "entity"=>
        {"debits"=>
          [{"status"=>"failed",
            "description"=>nil,
            "links"=>{"customer"=>nil, "source"=>"CC2snUSXCoAQaPtL3BnnWnYs", "dispute"=>nil, "order"=>nil, "card_hold"=>"HL3b3T4TPIyhDF0uTggaJmXC"},
            "amount"=>500,
            "created_at"=>"2014-11-17T23:43:15.893613Z",
            "updated_at"=>"2014-11-17T23:43:17.456676Z",
            "failure_reason"=>nil,
            "currency"=>"USD",
            "transaction_number"=>"WHSY-KZO-02ID",
            "href"=>payment_uri,
            "meta"=>{},
            "failure_reason_code"=>nil,
            "appears_on_statement_as"=>"BAL*Epicodus tuition",
            "id"=>"WD3b6phETOvHyNaZtQ5a7zUs"}],
         "links"=>
          {"debits.customer"=>"/customers/{debits.customer}",
           "debits.dispute"=>"/disputes/{debits.dispute}",
           "debits.card_hold"=>"/holds/{debits.card_hold}",
           "debits.events"=>"/debits/{debits.id}/events",
           "debits.order"=>"/orders/{debits.order}",
           "debits.refunds"=>"/debits/{debits.id}/refunds",
           "debits.source"=>"/resources/{debits.source}"}},
       "href"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
       "type"=>"debit.failed",
       "id"=>"EV69b2c37c6eb311e48c66060a33130f9b"}],
    "links"=>{}}}
end

def balanced_callback_debit_succeeded_json(payment_uri)
  {"events"=>
    [{"links"=>{},
      "occurred_at"=>"2014-11-17T23:43:17.456676Z",
      "uri"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
      "entity"=>
       {"debits"=>
         [{"status"=>"succeeded",
           "description"=>nil,
           "links"=>{"customer"=>nil, "source"=>"CC2snUSXCoAQaPtL3BnnWnYs", "dispute"=>nil, "order"=>nil, "card_hold"=>"HL3b3T4TPIyhDF0uTggaJmXC"},
           "amount"=>500,
           "created_at"=>"2014-11-17T23:43:15.893613Z",
           "updated_at"=>"2014-11-17T23:43:17.456676Z",
           "failure_reason"=>nil,
           "currency"=>"USD",
           "transaction_number"=>"WHSY-KZO-02ID",
           "href"=>payment_uri,
           "meta"=>{},
           "failure_reason_code"=>nil,
           "appears_on_statement_as"=>"BAL*Epicodus tuition",
           "id"=>"WD3b6phETOvHyNaZtQ5a7zUs"}],
        "links"=>
         {"debits.customer"=>"/customers/{debits.customer}",
          "debits.dispute"=>"/disputes/{debits.dispute}",
          "debits.card_hold"=>"/holds/{debits.card_hold}",
          "debits.events"=>"/debits/{debits.id}/events",
          "debits.order"=>"/orders/{debits.order}",
          "debits.refunds"=>"/debits/{debits.id}/refunds",
          "debits.source"=>"/resources/{debits.source}"}},
      "href"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
      "type"=>"debit.succeeded",
      "id"=>"EV69b2c37c6eb311e48c66060a33130f9b"}],
 "links"=>{},
 "action"=>"create",
 "controller"=>"balanced_events",
 "balanced_event"=>
  {"events"=>
    [{"links"=>{},
      "occurred_at"=>"2014-11-17T23:43:17.456676Z",
      "uri"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
      "entity"=>
       {"debits"=>
         [{"status"=>"succeeded",
           "description"=>nil,
           "links"=>{"customer"=>nil, "source"=>"CC2snUSXCoAQaPtL3BnnWnYs", "dispute"=>nil, "order"=>nil, "card_hold"=>"HL3b3T4TPIyhDF0uTggaJmXC"},
           "amount"=>500,
           "created_at"=>"2014-11-17T23:43:15.893613Z",
           "updated_at"=>"2014-11-17T23:43:17.456676Z",
           "failure_reason"=>nil,
           "currency"=>"USD",
           "transaction_number"=>"WHSY-KZO-02ID",
           "href"=>payment_uri,
           "meta"=>{},
           "failure_reason_code"=>nil,
           "appears_on_statement_as"=>"BAL*Epicodus tuition",
           "id"=>"WD3b6phETOvHyNaZtQ5a7zUs"}],
        "links"=>
         {"debits.customer"=>"/customers/{debits.customer}",
          "debits.dispute"=>"/disputes/{debits.dispute}",
          "debits.card_hold"=>"/holds/{debits.card_hold}",
          "debits.events"=>"/debits/{debits.id}/events",
          "debits.order"=>"/orders/{debits.order}",
          "debits.refunds"=>"/debits/{debits.id}/refunds",
          "debits.source"=>"/resources/{debits.source}"}},
      "href"=>"/events/EV69b2c37c6eb311e48c66060a33130f9b",
      "type"=>"debit.succeeded",
      "id"=>"EV69b2c37c6eb311e48c66060a33130f9b"}],
   "links"=>{}}}
end



