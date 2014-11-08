require 'rails_helper'

describe PaymentMethod do
  it { should validate_presence_of :account_uri }
  it { should validate_presence_of :student_id }
  it { should belong_to :student }
  it { should have_many :payments }
end
