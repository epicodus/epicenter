require 'rails_helper'

describe Cohort do
  it { should have_many :users }
  it { should validate_presence_of :start_date }
  it { should validate_presence_of :end_date }
  it { should validate_presence_of :description }
end
