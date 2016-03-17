describe InternshipTrack do
  it { should belong_to :internship }
  it { should belong_to :track }
  it { should validate_presence_of :internship }
  it { should validate_presence_of :track }
end
