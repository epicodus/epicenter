require 'rails_helper'

describe Review do
  it { should belong_to :submission }
  it { should have_many :grades }
  it { should belong_to :user }
  it { should validate_presence_of :note }
end
