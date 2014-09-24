require 'rails_helper'

RSpec.describe Submission, :type => :model do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :grades }
end
