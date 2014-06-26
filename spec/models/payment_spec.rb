require 'rails_helper'

describe Payment do
  it { should belong_to :subscription }
  it { should validate_presence_of :amount }
  it { should validate_presence_of :subscription_id }
end
