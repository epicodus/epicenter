describe Rating do
  it { should belong_to :internship }
  it { should belong_to :student }
  it { should validate_uniqueness_of(:internship_id).scoped_to(:student_id) }

  describe '#no_more_than_five_lowest validation' do
    let(:student) { FactoryGirl.create(:student) }

    before do
      FactoryGirl.create_list(:rating, 3, student: student, interest: 3)
    end

    it 'marks an internship as low priority if a student has <= 5 low priority internships' do
      low_rating = FactoryGirl.build(:rating, student: student, interest: 3)
      expect(low_rating.save).to be true
    end

    it 'does not create a "Low" rating when a student already has 5 "Low" ratings' do
      FactoryGirl.create_list(:rating, 2, student: student, interest: 3)
      low_rating = Rating.new(student: student, interest: 3, internship_id: 1)
      expect(low_rating.save).to be false
    end
  end

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

    it 'returns nil if a student is not logged in' do
      expect(Rating.for(internship, nil)).to be_nil
    end
  end
end
