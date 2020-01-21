describe Cohort do
  it { should have_and_belong_to_many :courses }
  it { should belong_to :office }
  it { should belong_to :track }
  it { should belong_to :admin }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:office) }

  describe 'past, current, future cohorts' do
    let(:current_cohort) { FactoryBot.create(:intro_only_cohort, start_date: Time.zone.now.to_date) }
    let(:past_cohort) { FactoryBot.create(:intro_only_cohort, start_date: Time.zone.now.to_date - 1.year) }
    let(:future_cohort) { FactoryBot.create(:intro_only_cohort, start_date: Time.zone.now.to_date + 1.year) }

    it 'returns all current cohorts' do
      expect(Cohort.current_cohorts).to eq [current_cohort]
    end

    it 'returns all future cohorts' do
      expect(Cohort.future_cohorts).to eq [future_cohort]
    end

    it 'returns all previous cohorts' do
      expect(Cohort.previous_cohorts).to eq [past_cohort]
    end

    it 'returns all current and future cohorts' do
      expect(Cohort.current_and_future_cohorts).to eq [current_cohort, future_cohort]
    end
  end

  describe 'parttime and fulltime scopes' do
    let!(:fulltime_cohort) { FactoryBot.create(:intro_only_cohort) }
    let!(:parttime_cohort) { FactoryBot.create(:part_time_cohort) }

    it 'returns all fulltime cohorts' do
      expect(Cohort.fulltime_cohorts).to eq [fulltime_cohort]
    end

    it 'returns all parttime cohorts' do
      expect(Cohort.parttime_cohorts).to eq [parttime_cohort]
    end
  end

  describe 'creating a part-time intro cohort' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:track) { FactoryBot.create(:part_time_track) }

    it 'creates a part-time intro cohort and course' do
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-14'))
      expect(cohort.description).to eq "2017-03-14 to 2017-06-22 #{office.short_name} Part-Time Intro to Programming"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2017-03-14')
      expect(cohort.courses.count).to eq 1
      expect(cohort.courses.first.language).to eq track.languages.first
    end
  end

  describe 'creating a part-time js/react cohort' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:track) { FactoryBot.create(:part_time_js_react_track) }

    it 'creates a part-time js/react cohort and courses' do
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2020-01-07'))
      expect(cohort.description).to eq "2020-01-07 to 2020-05-24 #{office.short_name} Part-Time JS/React"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2020-01-07')
      expect(cohort.courses.count).to eq 2
      expect(cohort.courses.first.language).to eq track.languages.first
    end
  end

  describe 'creating a full-time cohort' do
    let(:admin) { FactoryBot.create(:admin) }
    let(:track) { FactoryBot.create(:track) }

    it 'creates a cohort with classes' do
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "2017-03-13 to 2017-09-15 #{office.short_name} #{track.description}"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses.count).to eq 5
      expect(cohort.courses[0].start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses[1].start_date).to eq Date.parse('2017-04-17')
      expect(cohort.courses[2].start_date).to eq Date.parse('2017-05-22')
      expect(cohort.courses[3].start_date).to eq Date.parse('2017-06-26')
      expect(cohort.courses[4].start_date).to eq Date.parse('2017-07-31')
      expect(cohort.courses[4].track).to eq track
    end

    it 'uses existing internship course when creating second cohort for same office & dates' do
      office = admin.current_course.office
      admin2 = FactoryBot.create(:admin, current_course: admin.current_course)
      track2 = FactoryBot.create(:track)
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      cohort2 = Cohort.create(track: track2, admin: admin2, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.courses.count).to eq 5
      expect(cohort2.courses.count).to eq 5
      expect(cohort.courses.last).to eq cohort2.courses.last
      expect(cohort.courses.last.track).to eq nil
    end
  end

  describe '#update_end_date' do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:track) { FactoryBot.create(:track) }
    let(:admin) { FactoryBot.create(:admin) }

    it 'sets cohort end date when adding courses at same time as cohort creation' do
      cohort = Cohort.create(start_date: Date.today, office: office, track: track, admin: admin)
      expect(cohort.end_date).to eq cohort.courses.last.end_date
    end

    it 'updates cohort end_date when adding more recent course to cohort' do
      cohort = Cohort.create(start_date: Date.today.beginning_of_week, office: office, track: track, admin: admin)
      future_course = FactoryBot.create(:future_course, class_days: [Date.today.monday + 30.weeks])
      cohort.courses << future_course
      expect(cohort.end_date).to eq future_course.end_date
    end

    it 'does not update cohort end_date when adding less recent course to cohort' do
      cohort = Cohort.create(start_date: Date.today, office: office, track: track, admin: admin)
      past_course = FactoryBot.create(:past_course, class_days: [Date.today.monday - 30.weeks])
      cohort.courses << past_course
      expect(cohort.end_date).to eq cohort.courses.order(:end_date).last.end_date
    end
  end

  describe 'get_nth_week_of_cohort' do
    let(:cohort) { FactoryBot.create(:cohort, start_date: Date.parse('2018-07-30')) }

    it 'ignores single day holidays' do
      expect(cohort.get_nth_week_of_cohort(5)).to eq Date.parse('2018-09-03')
    end

    it 'skips holiday weeks' do
      expect(cohort.get_nth_week_of_cohort(16)).to eq Date.parse('2018-11-26')
    end
  end
end
