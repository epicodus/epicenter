describe Note do
  it { should belong_to(:submission).optional }
  it { should belong_to(:student).optional }
  it { should validate_presence_of(:content) }
  it { should validate_length_of(:content).is_at_most(2000) }
end
