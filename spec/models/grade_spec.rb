require 'rails_helper'

RSpec.describe Grade, :type => :model do
  it { should validate_presence_of :score }
  it { should belong_to :submission }
  it { should belong_to :requirement }
  it { should belong_to :user }
end
