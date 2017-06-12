describe Cohort do
  it { should have_many :courses }
  it { should belong_to :office }
  it { should belong_to :track }
  it { should belong_to :admin }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:start_date) }

  describe '.create_from_course_ids' do
    let(:course) { FactoryGirl.create(:course) }
    let(:future_course) { FactoryGirl.create(:future_course) }

    it 'creates cohort for specific track' do
      track = FactoryGirl.create(:track)
      cohort_data = { start_month: "2017-01", office: course.office.name, track: track.description, courses: [course.id, future_course.id] }
      Cohort.create_from_course_ids(cohort_data)
      cohort = Cohort.first
      expect(cohort.description).to eq "2017-01 #{track.description} #{course.office.name}"
      expect(cohort.office).to eq course.office
      expect(cohort.start_date).to eq course.start_date
      expect(cohort.end_date).to eq future_course.end_date
      expect(cohort.track).to eq track
    end

    it 'creates cohort not for specific track' do
      cohort_data = { start_month: "2017-01", office: course.office.name, track: "ALL", courses: [course.id, future_course.id] }
      Cohort.create_from_course_ids(cohort_data)
      cohort = Cohort.first
      expect(cohort.description).to eq "2017-01 ALL #{course.office.name}"
      expect(cohort.office).to eq course.office
      expect(cohort.start_date).to eq course.start_date
      expect(cohort.end_date).to eq future_course.end_date
    end
  end
end
