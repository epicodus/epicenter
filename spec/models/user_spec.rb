require 'rails_helper'

describe User do
  it { should validate_presence_of :name }
  it { should validate_presence_of :plan_id }
  it { should have_one :bank_account }
  it { should have_many :payments }
  it { should belong_to :plan }
end

