require 'rails_helper'

describe Grade do
  it { should validate_presence_of :score }
  it { should belong_to :submission }
  it { should belong_to :requirement }
end
