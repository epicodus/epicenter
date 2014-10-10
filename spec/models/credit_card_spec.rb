require 'rails_helper'

describe CreditCard do
  it { should belong_to :user }
  it { should validate_presence_of :credit_card_uri }
  it { should validate_presence_of :user_id }
end
