describe Course do
  it { should belong_to(:admin).optional }
  it { should belong_to :office }
  it { should belong_to :language }
  it { should belong_to(:track).optional }
  it { should have_many :students }
  it { should have_and_belong_to_many(:cohorts) }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many(:internships).through(:course_internships) }
  it { should have_many(:interview_assignments) }
  it { should have_many(:internship_assignments) }
  it { should validate_presence_of(:office_id) }

  describe "validations" do
    it "validates the presence of start_date" do
      course = FactoryBot.build(:course, class_days: nil)
      expect(course.start_date).to eq nil
    end

    it "validates the presence of end_date" do
      course = FactoryBot.build(:course, class_days: nil)
      expect(course.end_date).to eq nil
    end

    it "validates the presence of start_time" do
      course = FactoryBot.build(:course, start_time: nil)
      expect(course).to_not be_valid
    end

    it "validates the presence of end_time" do
      course = FactoryBot.build(:course, end_time: nil)
      expect(course).to_not be_valid
    end
  end

  describe 'default scope' do
    it 'orders by start_date ascending' do
      future_course = FactoryBot.create(:future_course)
      past_course = FactoryBot.create(:past_course)
      expect(Course.all).to eq [past_course, future_course]
    end
  end

  describe '#teacher' do
    it 'returns the teacher name if the course has an assigned teacher' do
      admin = FactoryBot.create(:admin)
      course = FactoryBot.create(:course, admin: admin)
      expect(course.teacher).to eq admin.name
    end

    it "does not return the teacher name if the course doesn't have an assigned teacher" do
      course = FactoryBot.create(:course)
      expect(course.teacher).to eq 'Unknown teacher'
    end
  end

  describe '#teacher_and_description' do
    it 'returns the teacher name and course description and track if exists' do
      admin = FactoryBot.create(:admin)
      track = FactoryBot.create(:track)
      course = FactoryBot.create(:course, admin: admin, track: track)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher}) [#{track.description} track]"
    end

    it 'does not include track if does not exist' do
      admin = FactoryBot.create(:admin)
      course = FactoryBot.create(:course, admin: admin)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher})"
    end

    it 'does not include track if internship course' do
      admin = FactoryBot.create(:admin)
      track = FactoryBot.create(:track)
      course = FactoryBot.create(:internship_course, admin: admin, track: track)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher})"
    end

    it 'does not include track if part-time course' do
      admin = FactoryBot.create(:admin)
      track = FactoryBot.create(:track)
      course = FactoryBot.create(:part_time_course, admin: admin, track: track)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher})"
    end
  end

  describe '#description_and_office' do
    it 'returns the course description and the office name' do
      admin = FactoryBot.create(:admin)
      course = FactoryBot.create(:course, admin: admin)
      expect(course.description_and_office).to eq "#{course.description} (#{course.office.name})"
    end
  end

  describe '#other_course_students' do
    it 'returns all other students for a course except the selected student' do
      course = FactoryBot.create(:course)
      student_1 = FactoryBot.create(:student, course: course)
      student_2 = FactoryBot.create(:student, course: course)
      student_3 = FactoryBot.create(:student, course: course)
      expect(course.other_course_students(student_3)).to include(student_1, student_2)
      expect(course.other_course_students(student_3)).not_to include(student_3)
    end
  end

  describe '#in_session?' do
    it 'returns true if the course is in session' do
      course = FactoryBot.create(:course)
      expect(course.in_session?).to eq true
    end

    it 'returns false if the course is not in session' do
      future_course = FactoryBot.create(:course, class_days: [Time.zone.now.beginning_of_week + 1.week, Time.zone.now.end_of_week + 1.week - 2.days])
      expect(future_course.in_session?).to eq false
    end
  end

  describe '#is_class_day?' do
    let(:course) { FactoryBot.create(:course) }

    it 'returns true if today is class day for this course' do
      travel_to course.start_date + 3.days do
        expect(course.is_class_day?).to eq true
      end
    end
    it 'returns false if today is not class day for this course' do
      travel_to course.start_date + 6.days do
        expect(course.is_class_day?).to eq false
      end
    end
  end

  describe "#other_students" do
    let(:course) { FactoryBot.create(:course) }
    let(:student) { FactoryBot.create(:student, course: course) }
    let(:other_student) { FactoryBot.create(:student) }

    it 'returns students that are not enrolled in a course' do
      expect(course.other_students).to eq [other_student]
    end
  end

  describe "calculates class days automatically if not provided" do
    let(:office) { FactoryBot.create(:portland_office) }
    let(:full_time_track) { FactoryBot.create(:track) }
    let(:part_time_track) { FactoryBot.create(:part_time_track) }
    let(:admin) { FactoryBot.create(:admin) }

    it 'calculates class days for a regular full-time class' do
      course = Course.create({ language: full_time_track.languages.first, start_date: Date.parse('2017-03-13'), office: office, track: full_time_track, start_time: '8:00 AM', end_time: '5:00 PM' })
      expect(course.start_date).to eq(Date.parse('2017-03-13'))
      expect(course.end_date).to eq(Date.parse('2017-04-13'))
      expect(course.class_days.count).to eq(24)
    end

    it 'calculates class days for an internship class' do
      course = Course.create({ language: full_time_track.languages.last, start_date: Date.parse('2017-03-13'), office: office, track: full_time_track, start_time: '8:00 AM', end_time: '5:00 PM' })
      expect(course.start_date).to eq(Date.parse('2017-03-13'))
      expect(course.end_date).to eq(Date.parse('2017-04-28'))
      expect(course.class_days.count).to eq(35)
    end

    it 'calculates class days for a part-time class' do
      course = Course.create({ language: part_time_track.languages.first, start_date: Date.parse('2017-03-13'), office: office, track: part_time_track, start_time: '6:00 PM', end_time: '9:00 PM' })
      expect(course.start_date).to eq(Date.parse('2017-03-13'))
      expect(course.end_date).to eq(Date.parse('2017-06-21'))
      expect(course.class_days.count).to eq(29) # 1 holiday
    end
  end

  describe "sets start and end dates from class_days" do
    let(:course) { FactoryBot.create(:course) }

    it "returns a valid start date when set_start_and_end_dates is successful" do
      expect(course.start_date).to eq course.class_days.first
    end

    it "returns a valid end date when set_start_and_end_dates is successful" do
      expect(course.end_date).to eq course.class_days.last
    end
  end

  describe '#number_of_days_since_start' do
    let(:course) { FactoryBot.create(:course) }

    it 'counts number of days since start of class' do
      travel_to course.start_date + 6.days do
        expect(course.number_of_days_since_start).to eq 5
      end
    end

    it 'does not count weekends' do
      travel_to course.start_date + 13.days do
        expect(course.number_of_days_since_start).to eq 10
      end
    end

    it 'does not count days after the class has ended' do
      travel_to course.end_date + 60.days do
        expect(course.number_of_days_since_start).to eq 25
      end
    end
  end

  describe '#class_dates_until' do
    let(:course) { FactoryBot.create(:course) }

    it 'returns a collection of date objects for the class days up to a given date' do
      day_one = course.start_date
      day_two = day_one + 1.day
      travel_to day_two do
        expect(course.class_dates_until(day_two)).to eq [day_one, day_two]
      end
    end
  end

  describe '#total_class_days' do
    it 'counts the days of class minus weekends' do
      course = FactoryBot.create(:course, class_days: (Time.zone.now.to_date..(Time.zone.now.to_date + 2.weeks - 1.day)).select { |day| day if !day.saturday? && !day.sunday? })
      expect(course.total_class_days).to eq 10
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the course' do
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      course = FactoryBot.create(:course, class_days: (monday..next_friday).select { |day| day if !day.saturday? && !day.sunday? })
      travel_to friday do
        expect(course.number_of_days_left).to eq 5
      end
    end
  end

  describe '#progress_percent' do
    it 'returns the percent of how many days have passed' do
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      course = FactoryBot.create(:course, class_days: (monday..next_friday).select { |day| day if !day.saturday? && !day.sunday? })
      travel_to friday do
        expect(course.progress_percent).to eq 50.0
      end
    end
  end

  context 'after_destroy' do
    let(:course) { FactoryBot.create(:course) }

    it 'reassigns all admins that have this as their current course to a different course' do
      another_course = FactoryBot.create(:course)
      admin = FactoryBot.create(:admin, current_course: course)
      course.destroy
      admin.reload
      expect(admin.current_course).to eq another_course
    end
  end

  describe '#current_and_future_courses' do
    it 'returns all current and future courses' do
      FactoryBot.create(:past_course)
      current_course = FactoryBot.create(:course)
      future_course = FactoryBot.create(:future_course)
      expect(Course.current_and_future_courses).to eq [current_course, future_course]
    end
  end

  describe '#future_courses' do
    it 'returns all future courses' do
      FactoryBot.create(:past_course)
      FactoryBot.create(:course)
      future_course = FactoryBot.create(:future_course)
      expect(Course.future_courses).to eq [future_course]
    end
  end

  describe '#previous_courses' do
    it 'returns all current and future courses' do
      past_course = FactoryBot.create(:past_course)
      FactoryBot.create(:course)
      expect(Course.previous_courses).to eq [past_course]
    end
  end

  describe '#fulltime_courses' do
    it 'returns all courses that are full-time courses' do
      ft_course = FactoryBot.create(:course)
      pt_course = FactoryBot.create(:part_time_course)
      expect(Course.fulltime_courses).to eq [ft_course]
    end
  end

  describe '#parttime_courses' do
    it 'returns all courses that are part-time courses' do
      ft_course = FactoryBot.create(:course)
      pt_course = FactoryBot.create(:part_time_course)
      expect(Course.parttime_courses).to eq [pt_course]
    end
  end

  describe '#internship_courses' do
    it 'returns all courses that are internship courses' do
      internship_course = FactoryBot.create(:internship_course)
      FactoryBot.create(:course)
      expect(Course.internship_courses).to eq [internship_course]
    end
  end

  describe '#non_internship_courses' do
    it 'returns all courses that are not internship courses' do
      FactoryBot.create(:internship_course)
      course = FactoryBot.create(:course)
      expect(Course.non_internship_courses).to eq [course]
    end
  end

  describe '#non_online_courses' do
    it 'returns all courses that are not online courses' do
      FactoryBot.create(:part_time_course, description: '2019-04 Evening ONLINE')
      course = FactoryBot.create(:course)
      expect(Course.non_online_courses).to eq [course]
    end
  end

  describe '#active_internship_courses' do
    it 'returns all courses that are internship courses and active' do
      internship_course = FactoryBot.create(:internship_course, active: true)
      FactoryBot.create(:course)
      expect(Course.active_internship_courses).to eq [internship_course]
    end
  end

  describe '#inactive_internship_courses' do
    it 'returns all courses that are internship courses and inactive' do
      internship_course = FactoryBot.create(:internship_course, active: false)
      FactoryBot.create(:course)
      expect(Course.inactive_internship_courses).to eq [internship_course]
    end
  end

  describe '#active_courses' do
    it 'returns all courses that are active' do
      active_course = FactoryBot.create(:course, active: true)
      FactoryBot.create(:course, active: false)
      expect(Course.active_courses).to eq [active_course]
    end
  end

  describe '#inactive_courses' do
    it 'returns all courses that are inactive' do
      inactive_course = FactoryBot.create(:course, active: false)
      FactoryBot.create(:course, active: true)
      expect(Course.inactive_courses).to eq [inactive_course]
    end
  end

  describe '#full_internship_courses' do
    it 'returns all courses that are full' do
      full_course = FactoryBot.create(:course, full: true)
      FactoryBot.create(:course, full: false)
      expect(Course.full_internship_courses).to eq [full_course]
    end
  end

  describe '#available_internship_courses' do
    it 'returns all courses that are not full' do
      available_course = FactoryBot.create(:course, full: false)
      FactoryBot.create(:course, full: true)
      expect(Course.available_internship_courses).to eq [available_course]
    end
  end

  describe '#courses_for' do
    it 'returns all courses for a certain office' do
      portland_course = FactoryBot.create(:portland_course)
      FactoryBot.create(:course)
      expect(Course.courses_for(portland_course.office)).to eq [portland_course]
    end
  end

  describe '.level' do
    it 'returns all courses with given language level' do
      intro_course = FactoryBot.create(:course)
      rails_course = FactoryBot.create(:level_3_just_finished_course)
      expect(Course.level(3)).to eq [rails_course]
    end
  end

  describe '#total_internship_students_requested' do
    it 'returns the total number of students requested for an internship course' do
      internship_course = FactoryBot.create(:internship_course)
      company_1 = FactoryBot.create(:company)
      company_2 = FactoryBot.create(:company)
      FactoryBot.create(:internship, company: company_1, courses: [internship_course])
      FactoryBot.create(:internship, company: company_2, courses: [internship_course])
      expect(internship_course.total_internship_students_requested).to eq 4
    end
  end

  describe '#total_class_days_until' do
    it 'returns the total number of students requested for an internship course' do
      monday = Time.zone.now.to_date.beginning_of_week
      tuesday = Time.zone.now.to_date.beginning_of_week + 1.day
      wednesday = Time.zone.now.to_date.beginning_of_week + 2.day
      course_1 = FactoryBot.create(:past_course, class_days: [monday])
      course_2 = FactoryBot.create(:course, class_days: [tuesday])
      course_3 = FactoryBot.create(:future_course, class_days: [wednesday])
      student = FactoryBot.create(:student, courses: [course_1, course_2, course_3])
      expect(student.courses.total_class_days_until(Time.zone.now.to_date.end_of_week)).to eq [wednesday, tuesday, monday]
    end
  end

  describe '#export_students_emails' do
    it 'exports to students.txt file names & email addresses for students in course' do
      student = FactoryBot.create(:student)
      filename = Rails.root.join('tmp','students.txt')
      student.course.export_students_emails(filename)
      expect(File.read(filename)).to include student.email
    end
  end

  describe '#set_parttime' do
    it 'sets parttime flag for evening course' do
      course = FactoryBot.create(:part_time_course)
      expect(course.parttime).to eq true
    end

    it 'does not set parttime flag for intro course' do
      course = FactoryBot.create(:course)
      expect(course.parttime).to eq false
    end
  end

  describe '#set_internship_course' do
    it 'sets internship_course flag for internship course' do
      course = FactoryBot.create(:internship_course)
      expect(course.internship_course).to eq true
    end

    it 'does not set internship_course flag for intro course' do
      course = FactoryBot.create(:course)
      expect(course.internship_course).to eq false
    end
  end

  describe '#set_description' do
    it 'sets description for course to date and language' do
      course = FactoryBot.create(:portland_ruby_course)
      expect(course.description).to eq "#{course.start_date.strftime('%Y-%m')} #{course.language.name}"
    end

    it 'sets description for fulltime intro course to date, language, and level 1 course name' do
      course = FactoryBot.create(:portland_course, track: FactoryBot.create(:track))
      expect(course.description).to eq "#{course.start_date.strftime('%Y-%m')} #{course.language.name} #{course.track.languages.find_by(level: 1).name}"
    end

    it 'sets description for parttime course in location other than portland to date, language, location' do
      course = FactoryBot.create(:seattle_part_time_course)
      expect(course.description).to eq "#{course.start_date.strftime('%Y-%m')} #{course.language.name} #{course.office.name.upcase}"
    end

    it 'allows manual setting of description on creation' do
      course = FactoryBot.build(:course)
      course.description = 'an awesome course'
      course.save
      expect(course.description).to eq 'an awesome course'
    end
  end

  describe 'create course class_days automatically based on start_date' do
    it 'creates course days for non-internship course during period without any holidays' do
      course = FactoryBot.create(:course, class_days: [], start_date: Date.parse('2017-03-13'))
      expect(course.start_date).to eq Date.parse('2017-03-13')
      expect(course.end_date).to eq Date.parse('2017-04-13')
      expect(course.class_days.count).to eq 24
    end

    it 'creates course days for non-internship course during period with holidays' do
      course = FactoryBot.create(:course, class_days: [], start_date: Date.parse('2017-05-22'))
      expect(course.start_date).to eq Date.parse('2017-05-22')
      expect(course.end_date).to eq Date.parse('2017-06-22')
      expect(course.class_days.count).to eq 23
    end

    it 'creates course days for non-internship course during period with holiday week' do
      course = FactoryBot.create(:course, class_days: [], start_date: Date.parse('2017-11-13'))
      expect(course.start_date).to eq Date.parse('2017-11-13')
      expect(course.end_date).to eq Date.parse('2017-12-21')
      expect(course.class_days.count).to eq 24
    end

    it 'creates course days for internship course during period without holidays' do
      course = FactoryBot.create(:internship_course, class_days: [], start_date: Date.parse('2017-03-13'))
      expect(course.start_date).to eq Date.parse('2017-03-13')
      expect(course.end_date).to eq Date.parse('2017-04-28')
      expect(course.class_days.count).to eq 35
    end

    it 'creates course days for internship course during period with holiday weeks' do
      course = FactoryBot.create(:internship_course, class_days: [], start_date: Date.parse('2017-11-13'))
      expect(course.start_date).to eq Date.parse('2017-11-13')
      expect(course.end_date).to eq Date.parse('2017-12-29')
      expect(course.class_days.count).to eq 35
    end
  end
end
