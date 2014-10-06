require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should have_one :plan }
end

