describe Company do
  it { should validate_presence_of :name }
  it { should validate_presence_of :contact_phone }
  it { should validate_presence_of :contact_email }
end
