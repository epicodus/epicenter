describe Office do
  it { should have_many :courses }
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:time_zone) }
end
