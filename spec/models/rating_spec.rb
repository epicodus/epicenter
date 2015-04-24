describe Rating do
  it { should belong_to :internship }
  it { should belong_to :student }
  it { should validate_uniqueness_of(:internship_id).scoped_to(:student_id) }

  describe 'for' do
    let(:student) { FactoryGirl.create(:student) }
    let(:internship) { FactoryGirl.create(:internship, cohort: student.cohort) }

    it "returns the student's rating of the internship if it exists" do
      rating = FactoryGirl.create(:rating, student: student, internship: internship)
      expect(Rating.for(internship, student)).to eq rating
    end

    it 'returns a new instance of Rating if the student has not rated internship' do
      expect(Rating.for(internship, student)).to be_instance_of(Rating)
    end
  end
end
