describe Track do
  it { should have_many(:internships).through(:internship_tracks) }
  it { should have_and_belong_to_many(:languages) }
  it { should have_many(:courses) }
  it { should have_many(:cohorts) }
end
