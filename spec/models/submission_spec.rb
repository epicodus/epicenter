require 'rails_helper'

describe Submission do
  it { should validate_presence_of :link }
  it { should belong_to :assessment }
  it { should have_many :reviews }
end
