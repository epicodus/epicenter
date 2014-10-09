require 'rails_helper'

describe Assessment do
  it { should validate_presence_of :title }
  it { should validate_presence_of :section }
  it { should validate_presence_of :url }
  it { should have_many :requirements }
  it { should have_many :submissions }
end
