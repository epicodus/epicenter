require 'rails_helper'

describe Grade do
  it { should validate_presence_of :score_id }
  it { should belong_to :review }
  it { should belong_to :requirement }
  it { should belong_to :score }
end
