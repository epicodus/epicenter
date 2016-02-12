describe Plan do
  it { should have_many :students }
  it { should validate_presence_of :name }
  it { should validate_presence_of :upfront_amount }
  it { should validate_presence_of :total_amount }
end
