describe Language do
  it { should have_and_belong_to_many :tracks }
  it { should have_many :courses }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:level) }
end
