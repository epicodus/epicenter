describe Cohort do
  it { should have_many :courses }
  it { should belong_to :office }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:start_date) }
end
