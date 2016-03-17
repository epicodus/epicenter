describe Track do
  it { should have_many(:internships).through(:internship_tracks) }
end
