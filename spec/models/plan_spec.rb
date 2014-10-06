require 'rails_helper'

describe Plan do
  it { should have_many :users }
  it { should validate_presence_of :recurring_amt }
  it { should validate_presence_of :upfront_amt }
  it { should validate_numericality_of :upfront_amt }
  it { should validate_numericality_of :recurring_amt }
end
