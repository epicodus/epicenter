require 'rails_helper'

RSpec.describe Requirement, :type => :model do
  it { should validate_presence_of :content }
  it { should belong_to :assessment }
  it { should have_many :grades }
end
