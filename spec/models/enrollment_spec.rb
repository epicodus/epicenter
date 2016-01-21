describe Enrollment do
  it { should validate_presence_of :course }
  it { should validate_presence_of :student }
end
