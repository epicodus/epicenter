describe Score do
  it { should validate_presence_of :value }
  it { should validate_presence_of :description }
  it { should have_many :grades }
end
