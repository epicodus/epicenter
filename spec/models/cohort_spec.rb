describe Cohort do
  it { should have_and_belong_to_many :courses }
  it { should belong_to :office }
  it { should belong_to :track }
  it { should belong_to :admin }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:office) }

  it 'should validate uniqueness of cohort based on start_date, office_id, track_id' do
    cohort = FactoryBot.create(:cohort)
    expect { FactoryBot.create(:cohort, start_date: cohort.start_date, track: cohort.track, office: cohort.office) }.to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Start date has already been taken')
  end

  it 'should allow cohort creation as long as start_date, office_id, or track_id are different' do
    cohort = FactoryBot.create(:cohort)
    cohort2 = FactoryBot.create(:cohort, start_date: cohort.start_date, track: cohort.track, office: FactoryBot.create(:portland_office))
    expect(Cohort.find(cohort2.id)).to be_present

  end

  describe '#cohorts_for' do
    it 'returns all cohorts for a certain office' do
      portland_cohort = FactoryBot.create(:cohort, office: FactoryBot.create(:portland_office))
      seattle_cohort = FactoryBot.create(:cohort, office: FactoryBot.create(:seattle_office))
      expect(Cohort.cohorts_for(portland_cohort.office)).to eq [portland_cohort]
    end
  end

  describe 'past, current, future cohorts' do
    let(:current_cohort) { FactoryBot.create(:cohort, start_date: Time.zone.now.to_date) }
    let(:past_cohort) { FactoryBot.create(:cohort, start_date: Time.zone.now.to_date - 1.year) }
    let(:future_cohort) { FactoryBot.create(:cohort, start_date: Time.zone.now.to_date + 1.year) }

    it 'returns all current cohorts' do
      expect(Cohort.current_cohorts).to eq [current_cohort]
    end

    it 'returns all future cohorts' do
      expect(Cohort.future_cohorts).to eq [future_cohort]
    end

    it 'returns all previous cohorts' do
      expect(Cohort.previous_cohorts).to eq [past_cohort]
    end
  end

  describe 'creating a cohort when classes already exist' do
    let(:office) { FactoryBot.create(:portland_office) }
    let!(:track) { FactoryBot.create(:track) }
    let!(:admin) { FactoryBot.create(:admin) }
    let!(:intro) { FactoryBot.create(:level0_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 0)) }
    let!(:level1) { FactoryBot.create(:level1_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 1)) }
    let!(:js) { FactoryBot.create(:level2_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 2)) }
    let!(:level3) { FactoryBot.create(:level3_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 3)) }
    let!(:internship) { FactoryBot.create(:level4_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 4)) }

    it 'creates a cohort when classes already exist' do
      cohort = Cohort.create(track: intro.track, admin: intro.admin, office: intro.office, start_date: intro.start_date)
      expect(cohort.description).to eq "#{intro.start_date.strftime('%Y-%m')} #{intro.office.short_name} #{intro.track.description} (#{intro.start_date.strftime('%b %-d')} - #{internship.end_date.strftime('%b %-d')})"
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
    let(:office) { FactoryBot.create(:portland_office) }
    let(:track) { FactoryBot.create(:track) }
    let(:admin) { FactoryBot.create(:admin) }

    it 'creates a cohort when classes do not yet exist' do
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "2017-03 #{office.short_name} #{track.description} (Mar 13 - Sep 15)"
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
    let(:office) { FactoryBot.create(:portland_office) }
    let(:track) { FactoryBot.create(:track) }
    let(:admin) { FactoryBot.create(:admin) }
    let!(:intro) { FactoryBot.create(:level0_course, office: office, track: track, admin: admin, language: track.languages.find_by(level: 0)) }

    it 'creates a cohort when some but not all classes already exist' do
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "2017-03 #{office.short_name} #{track.description} (Mar 13 - Sep 15)"
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

  describe 'creating a part-time cohort' do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:track) { FactoryBot.create(:part_time_track) }
    let(:admin) { FactoryBot.create(:admin) }

    it 'creates a part-time cohort and course' do
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2017-03-13'))
      expect(cohort.description).to eq "PT: 2017-03 #{office.short_name} #{track.description} (Mar 13 - Jun 21)"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2017-03-13')
      expect(cohort.courses.count).to eq 1
      expect(cohort.courses.first.language).to eq track.languages.first
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
      cohort = Cohort.create(start_date: Date.today, office: office, track: track, admin: admin)
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

  describe '.calculate_cohort_start_date' do
    it 'calculates cohort start date correctly for course with 2016-01-04 start date' do
      course = FactoryBot.create(:portland_course, class_days: [Date.parse('2016-01-04')])
      expect(Cohort.calculate_cohort_start_date(course)).to eq '2016-01-04'
    end

    it 'calculates cohort start date correctly for course with start_date later than 2016-01-04' do
      cohort = FactoryBot.create(:portland_cohort, start_date: Time.now.to_date)
      expect(Cohort.calculate_cohort_start_date(cohort.courses.first)).to eq cohort.courses.reorder(:start_date).first.start_date.to_s
    end
  end
end
