describe Rating do
  it { should belong_to :internship }
  it { should belong_to :student }
  it { should validate_presence_of :number }

  describe "validations" do
    subject { FactoryGirl.build(:rating) }
    it { should validate_uniqueness_of(:internship_id).scoped_to(:student_id) }
  end

  describe 'for' do
    let(:student) { FactoryGirl.create(:student) }
    let(:internship) { FactoryGirl.create(:internship, courses: [student.course]) }

    it "returns the student's rating of the internship if it exists" do
      rating = FactoryGirl.create(:rating, student: student, internship: internship)
      expect(Rating.for(internship, student)).to eq rating
    end

    it 'returns a new instance of Rating if the student has not rated internship' do
      expect(Rating.for(internship, student)).to be_instance_of(Rating)
    end

    it 'returns nil if a student is not logged in' do
      expect(Rating.for(internship, nil)).to be_nil
    end
  end
end
