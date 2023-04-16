describe Cohort do
  it { should have_and_belong_to_many :courses }
  it { should have_many :payments }
  it { should belong_to :office }
  it { should belong_to :track }
  it { should belong_to :admin }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:office) }

  describe 'past, current, future cohorts' do
    let(:current_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Time.zone.now.to_date) }
    let(:past_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Time.zone.now.to_date - 1.year) }
    let(:future_cohort) { FactoryBot.create(:pt_intro_cohort, start_date: Time.zone.now.to_date + 1.year) }

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
    let!(:fulltime_cohort) { FactoryBot.create(:ft_cohort) }
    let!(:parttime_cohort) { FactoryBot.create(:pt_intro_cohort) }

    it 'returns all fulltime cohorts' do
      expect(Cohort.fulltime_cohorts).to eq [fulltime_cohort]
    end

    it 'returns all parttime cohorts' do
      expect(Cohort.parttime_cohorts).to eq [parttime_cohort]
    end
  end

  describe 'creating a part-time intro cohort from layout file' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    let(:track) { FactoryBot.create(:part_time_track) }

    it 'creates a part-time intro cohort and course from layout file' do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return cohort_layout_params_helper(track: 'Part-Time Intro to Programming', number_of_courses: 1)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: true, number_of_days: 23)
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_cohort_layout_path')
      expect(cohort.description).to eq "2021-01-04 to 2021-02-10 Part-Time Intro to Programming"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2021-01-04')
      expect(cohort.courses.count).to eq 1
      expect(cohort.courses.first.language).to eq track.languages.first
    end

    it 'creates a full-time intro cohort from layout file when starts on a tuesday due to holiday' do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return cohort_layout_params_helper(track: 'Part-Time Intro to Programming', number_of_courses: 1)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false, number_of_days: 15)
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2023-01-03'), layout_file_path: 'example_cohort_layout_path')
      expect(cohort.description).to eq "2023-01-03 to 2023-01-20 Part-Time Intro to Programming"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2023-01-03')
      expect(cohort.end_date).to eq Date.parse('2023-01-20')
      expect(cohort.courses.first.start_date).to eq cohort.start_date
      expect(cohort.courses.first.end_date).to eq cohort.end_date
      expect(cohort.courses.count).to eq 1
      expect(cohort.courses.first.language).to eq track.languages.first
      expect(cohort.courses.first.class_days.count).to eq 13 # due to 2 holidays
    end
  end

  describe 'creating a part-time full-stack cohort from layout file' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    let(:track) { FactoryBot.create(:part_time_c_react_track) }

    it 'creates a part-time c/react cohort and courses' do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return cohort_layout_params_helper(track: 'Part-Time C#/React', number_of_courses: 4)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_1').and_return course_layout_params_helper(part_time: true, number_of_days: 23)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_2').and_return course_layout_params_helper(part_time: true, number_of_days: 32)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_3').and_return course_layout_params_helper(part_time: true, number_of_days: 52)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_4').and_return course_layout_params_helper(part_time: true, number_of_days: 53)
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_cohort_layout_path')
      expect(cohort.description).to eq "2021-01-04 to 2021-10-10 Part-Time C#/React"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2021-01-04')
      expect(cohort.courses.count).to eq 4
      expect(cohort.courses.first.language).to eq track.languages.first
    end
  end

  describe 'creating a full-time cohort from layout file' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    let(:track) { FactoryBot.create(:track) }

    it 'creates a cohort with classes' do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return cohort_layout_params_helper(track: 'C#/React', number_of_courses: 5)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_1').and_return course_layout_params_helper(number_of_days: 15)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_2').and_return course_layout_params_helper(number_of_days: 20)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_3').and_return course_layout_params_helper(number_of_days: 35)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_4').and_return course_layout_params_helper(number_of_days: 30)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path_5').and_return course_layout_params_helper(number_of_days: 35, internship: true)
      office = admin.current_course.office
      cohort = Cohort.create(track: track, admin: admin, office: office, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_cohort_layout_path')
      expect(cohort.description).to eq "2021-01-04 to 2021-07-09 #{track.description}"
      expect(cohort.office).to eq office
      expect(cohort.track).to eq track
      expect(cohort.admin).to eq admin
      expect(cohort.start_date).to eq Date.parse('2021-01-04')
      expect(cohort.courses.count).to eq 5
      expect(cohort.courses[0].start_date).to eq Date.parse('2021-01-04')
      expect(cohort.courses[1].start_date).to eq Date.parse('2021-01-25')
      expect(cohort.courses[2].start_date).to eq Date.parse('2021-02-22')
      expect(cohort.courses[3].start_date).to eq Date.parse('2021-04-12')
      expect(cohort.courses[4].start_date).to eq Date.parse('2021-05-24')
      expect(cohort.courses[4].track).to eq track
    end
  end

  describe '#update_end_date' do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:track) { FactoryBot.create(:track) }
    let(:admin) { FactoryBot.create(:admin) }

    before do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return cohort_layout_params_helper(track: 'Part-Time Intro to Programming', number_of_courses: 1)
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: true, number_of_days: 23)
    end

    it 'sets cohort end date when adding courses at same time as cohort creation' do
      cohort = Cohort.create(start_date: Date.today, office: office, track: track, admin: admin, layout_file_path: 'example_cohort_layout_path')
      expect(cohort.end_date).to eq cohort.courses.last.end_date
    end

    it 'updates cohort end_date when adding more recent course to cohort' do
      cohort = Cohort.create(start_date: Date.today.beginning_of_week, office: office, track: track, admin: admin, layout_file_path: 'example_cohort_layout_path')
      future_course = FactoryBot.create(:future_course, class_days: [Date.today.monday + 30.weeks])
      cohort.courses << future_course
      expect(cohort.end_date).to eq future_course.end_date
    end

    it 'does not update cohort end_date when adding less recent course to cohort' do
      cohort = Cohort.create(start_date: Date.today, office: office, track: track, admin: admin, layout_file_path: 'example_cohort_layout_path')
      past_course = FactoryBot.create(:past_course, class_days: [Date.today.monday - 30.weeks])
      cohort.courses << past_course
      expect(cohort.end_date).to eq cohort.courses.order(:end_date).last.end_date
    end
  end
end

# helpers

def cohort_layout_params_helper(attributes = {})
  track = attributes[:track] || 'Part-Time Intro to Programming'
  number_of_courses = attributes[:number_of_courses] || 1
  course_layout_files = []
  number_of_courses.times do |i|
    if number_of_courses == 1
      course_layout_files << 'example_course_layout_path'
    else
      course_layout_files << "example_course_layout_path_#{i+1}"
    end
  end
  { 'track' => track, 'course_layout_files' => course_layout_files }
end

def course_layout_params_helper(attributes = {})
  part_time = attributes[:part_time] || false
  internship = attributes[:internship] || false
  number_of_days = attributes[:number_of_days] || 15
  class_times = part_time ? class_times_pt : class_times_ft
  { 'part_time' => part_time, 'internship' => internship, 'number_of_days' => number_of_days, 'class_times' => class_times, 'code_reviews' => [] }
end

def class_times_pt
  { 'Sunday' => '9:00-17:00', 'Monday' => '18:00-21:00', 'Tuesday' => '18:00-21:00', 'Wednesday' => '18:00-21:00' }
end

def class_times_ft
  { 'Monday' => '8:00-17:00', 'Tuesday' => '8:00-17:00', 'Wednesday' => '8:00-17:00', 'Thursday' => '8:00-17:00', 'Friday' => '8:00-17:00' }
end
