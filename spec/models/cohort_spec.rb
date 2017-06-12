describe Cohort do
  it { should have_many :courses }
  it { should belong_to :office }
  it { should belong_to :track }
  it { should belong_to :admin }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:office) }

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

  describe 'creating a cohort when classes already exist' do
    let(:office) { FactoryGirl.create(:portland_office) }
    let!(:track) { FactoryGirl.create(:track) }
    let!(:admin) { FactoryGirl.create(:admin, current_course: nil) }
    let!(:intro) { FactoryGirl.create(:level0_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 0)) }
    let!(:level1) { FactoryGirl.create(:level1_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 1)) }
    let!(:js) { FactoryGirl.create(:level2_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 2)) }
    let!(:level3) { FactoryGirl.create(:level3_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 3)) }
    let!(:internship) { FactoryGirl.create(:level4_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 4)) }

    it 'creates a cohort when classes already exist' do
      cohort = Cohort.create(track: intro.track, admin: intro.admin, office: intro.office, start_date: intro.start_date)
      expect(cohort.description).to eq "#{intro.start_date.strftime('%Y-%m')} #{intro.track.description} #{intro.office.name}"
      expect(cohort.office).to eq intro.office
      expect(cohort.track).to eq intro.track
      expect(cohort.admin).to eq intro.admin
      expect(cohort.start_date).to eq intro.start_date
      expect(cohort.courses).to include(intro)
      expect(cohort.courses).to include(level1)
      expect(cohort.courses).to include(js)
      expect(cohort.courses).to include(level3)
      expect(cohort.courses).to include(internship)
    end
  end

  describe 'creating a cohort when classes do not yet exist' do
    let(:office) { FactoryGirl.create(:portland_office) }
    let(:track) { FactoryGirl.create(:track) }
    let(:admin) { FactoryGirl.create(:admin, current_course: nil) }

    it 'creates a cohort when classes do not yet exist' do
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "2017-03 #{track.description} #{office.name}"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses.count).to eq 5
      expect(cohort.courses.level(0).first.start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses.level(1).first.start_date).to eq Date.parse('2017-04-17')
      expect(cohort.courses.level(2).first.start_date).to eq Date.parse('2017-05-22')
      expect(cohort.courses.level(3).first.start_date).to eq Date.parse('2017-06-26')
      expect(cohort.courses.level(4).first.start_date).to eq Date.parse('2017-07-31')
    end
  end

  describe 'creating a cohort when some but not all classes already exist' do
    let(:office) { FactoryGirl.create(:portland_office) }
    let(:track) { FactoryGirl.create(:track) }
    let(:admin) { FactoryGirl.create(:admin, current_course: nil) }
    let!(:intro) { FactoryGirl.create(:level0_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 0)) }

    it 'creates a cohort when some but not all classes already exist' do
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "2017-03 #{track.description} #{office.name}"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses.count).to eq 5
      expect(cohort.courses.level(0).first).to eq intro
      expect(cohort.courses.level(1).first.start_date).to eq Date.parse('2017-04-17')
      expect(cohort.courses.level(2).first.start_date).to eq Date.parse('2017-05-22')
      expect(cohort.courses.level(3).first.start_date).to eq Date.parse('2017-06-26')
      expect(cohort.courses.level(4).first.start_date).to eq Date.parse('2017-07-31')
    end
  end
end
