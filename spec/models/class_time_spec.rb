describe ClassTime do
  it { should have_and_belong_to_many :courses }

  it { should validate_presence_of :wday }
  it { should validate_presence_of :start_time }
  it { should validate_presence_of :end_time }
end
