describe Language do
  it { should have_many :courses }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:level) }
end
