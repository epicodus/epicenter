describe Internship do
  it { should belong_to :cohort }
  it { should belong_to :company }
  it { should have_many :ratings }
  it { should have_many(:students).through(:ratings) }
  it { should validate_presence_of :cohort_id }
  it { should validate_presence_of :company_id }
  it { should validate_presence_of :description }
  it { should validate_presence_of :ideal_intern }
  it { should validate_uniqueness_of(:company_id).scoped_to(:cohort_id) }
end
