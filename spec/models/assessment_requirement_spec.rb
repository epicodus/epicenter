require 'rails_helper'

RSpec.describe AssessmentRequirement, :type => :model do
  it { should validate_presence_of :content }
  it { should belong_to :assessment }
end
