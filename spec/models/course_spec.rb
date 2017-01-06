describe Course do
  it { should belong_to :admin }
  it { should belong_to :office }
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many(:internships).through(:course_internships) }
  it { should have_many(:interview_assignments) }
  it { should have_many(:internship_assignments) }
  it { should validate_presence_of(:office_id) }

  describe "validations" do
    it "validates the presence of description" do
      course = FactoryGirl.build(:course, description: nil)
      expect(course).to_not be_valid
    end

    it "validates the presence of start_date" do
      course = FactoryGirl.build(:course, class_days: nil)
      expect(course.start_date).to eq nil
    end

    it "validates the presence of end_date" do
      course = FactoryGirl.build(:course, class_days: nil)
      expect(course.end_date).to eq nil
    end

    it "validates the presence of start_time" do
      course = FactoryGirl.build(:course, start_time: nil)
      expect(course).to_not be_valid
    end

    it "validates the presence of end_time" do
      course = FactoryGirl.build(:course, end_time: nil)
      expect(course).to_not be_valid
    end
  end

  describe '#teacher' do
    it 'returns the teacher name if the course has an assigned teacher' do
      admin = FactoryGirl.create(:admin)
      course = FactoryGirl.create(:course, admin: admin)
      expect(course.teacher).to eq admin.name
    end

    it "does not return the teacher name if the course doesn't have an assigned teacher" do
      course = FactoryGirl.create(:course)
      expect(course.teacher).to eq 'Unknown teacher'
    end
  end

  describe '#teacher_and_description' do
    it 'returns the teacher name and course description' do
      admin = FactoryGirl.create(:admin)
      course = FactoryGirl.create(:course, admin: admin)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher})"
    end
  end

  describe '#description_and_office' do
    it 'returns the course description and the office name' do
      admin = FactoryGirl.create(:admin)
      course = FactoryGirl.create(:course, admin: admin)
      expect(course.description_and_office).to eq "#{course.description} (#{course.office.name})"
    end
  end

  describe '#other_course_students' do
    it 'returns all other students for a course except the selected student' do
      course = FactoryGirl.create(:course)
      student_1 = FactoryGirl.create(:student, course: course)
      student_2 = FactoryGirl.create(:student, course: course)
      student_3 = FactoryGirl.create(:student, course: course)
      expect(course.other_course_students(student_3)).to include(student_1, student_2)
      expect(course.other_course_students(student_3)).not_to include(student_3)
    end
  end

  describe '#in_session?' do
    it 'returns true if the course is in session' do
      course = FactoryGirl.create(:course)
      expect(course.in_session?).to eq true
    end

    it 'returns false if the course is not in session' do
      future_course = FactoryGirl.create(:course, class_days: [Time.zone.now.beginning_of_week + 1.week, Time.zone.now.end_of_week + 1.week - 2.days])
      expect(future_course.in_session?).to eq false
    end
  end

  describe "#other_students" do
    let(:course) { FactoryGirl.create(:course) }
    let(:student) { FactoryGirl.create(:student, course: course) }
    let(:other_student) { FactoryGirl.create(:student) }

    it 'returns students that are not enrolled in a course' do
      expect(course.other_students).to eq [other_student]
    end
  end

  describe "sets start and end dates from class_days" do
    let(:course) { FactoryGirl.create(:course) }

    it "returns a valid start date when set_start_and_end_dates is successful" do
      expect(course.start_date).to eq course.class_days.first
    end

    it "returns a valid end date when set_start_and_end_dates is successful" do
      expect(course.end_date).to eq course.class_days.last
    end
  end

  describe '#number_of_days_since_start' do
    let(:course) { FactoryGirl.create(:course) }

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
    let(:course) { FactoryGirl.create(:course) }

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
      course = FactoryGirl.create(:course, class_days: (Time.zone.now.to_date..(Time.zone.now.to_date + 2.weeks - 1.day)).select { |day| day if !day.saturday? && !day.sunday? })
      expect(course.total_class_days).to eq 10
    end
  end

  describe '#number_of_days_left' do
    it 'returns the number of days left in the course' do
      monday = Time.zone.now.to_date.beginning_of_week
      friday = monday + 4.days
      next_friday = friday + 1.week

      course = FactoryGirl.create(:course, class_days: (monday..next_friday).select { |day| day if !day.saturday? && !day.sunday? })
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

      course = FactoryGirl.create(:course, class_days: (monday..next_friday).select { |day| day if !day.saturday? && !day.sunday? })
      travel_to friday do
        expect(course.progress_percent).to eq 50.0
      end
    end
  end

  context 'after_destroy' do
    let(:course) { FactoryGirl.create(:course) }

    it 'reassigns all admins that have this as their current course to a different course' do
      another_course = FactoryGirl.create(:course)
      admin = FactoryGirl.create(:admin, current_course: course)
      course.destroy
      admin.reload
      expect(admin.current_course).to eq another_course
    end
  end

  describe '#current_and_future_courses' do
    it 'returns all current and future courses' do
      FactoryGirl.create(:past_course)
      current_course = FactoryGirl.create(:course)
      future_course = FactoryGirl.create(:future_course)
      expect(Course.current_and_future_courses).to eq [current_course, future_course]
    end
  end

  describe '#future_courses' do
    it 'returns all future courses' do
      FactoryGirl.create(:past_course)
      FactoryGirl.create(:course)
      future_course = FactoryGirl.create(:future_course)
      expect(Course.future_courses).to eq [future_course]
    end
  end

  describe '#previous_courses' do
    it 'returns all current and future courses' do
      past_course = FactoryGirl.create(:past_course)
      FactoryGirl.create(:course)
      expect(Course.previous_courses).to eq [past_course]
    end
  end

  describe '#internship_courses' do
    it 'returns all courses that are internship courses' do
      internship_course = FactoryGirl.create(:internship_course)
      FactoryGirl.create(:course)
      expect(Course.internship_courses).to eq [internship_course]
    end
  end

  describe '#non_internship_courses' do
    it 'returns all courses that are internship courses' do
      FactoryGirl.create(:internship_course)
      course = FactoryGirl.create(:course)
      expect(Course.non_internship_courses).to eq [course]
    end
  end

  describe '#active_internship_courses' do
    it 'returns all courses that are internship courses and active' do
      internship_course = FactoryGirl.create(:internship_course, active: true)
      FactoryGirl.create(:course)
      expect(Course.active_internship_courses).to eq [internship_course]
    end
  end

  describe '#inactive_internship_courses' do
    it 'returns all courses that are internship courses and inactive' do
      internship_course = FactoryGirl.create(:internship_course, active: false)
      FactoryGirl.create(:course)
      expect(Course.inactive_internship_courses).to eq [internship_course]
    end
  end

  describe '#active_courses' do
    it 'returns all courses that are active' do
      active_course = FactoryGirl.create(:course, active: true)
      FactoryGirl.create(:course, active: false)
      expect(Course.active_courses).to eq [active_course]
    end
  end

  describe '#inactive_courses' do
    it 'returns all courses that are inactive' do
      inactive_course = FactoryGirl.create(:course, active: false)
      FactoryGirl.create(:course, active: true)
      expect(Course.inactive_courses).to eq [inactive_course]
    end
  end

  describe '#courses_for' do
    it 'returns all courses for a certain office' do
      portland_course = FactoryGirl.create(:portland_course)
      FactoryGirl.create(:course)
      expect(Course.courses_for(portland_course.office)).to eq [portland_course]
    end
  end

  describe '#total_internship_students_requested' do
    it 'returns the total number of students requested for an internship course' do
      internship_course = FactoryGirl.create(:internship_course)
      company_1 = FactoryGirl.create(:company)
      company_2 = FactoryGirl.create(:company)
      FactoryGirl.create(:internship, company: company_1, courses: [internship_course])
      FactoryGirl.create(:internship, company: company_2, courses: [internship_course])
      expect(internship_course.total_internship_students_requested).to eq 4
    end
  end

  describe '#total_class_days_until' do
    it 'returns the total number of students requested for an internship course' do
      monday = Time.zone.now.to_date.beginning_of_week
      tuesday = Time.zone.now.to_date.beginning_of_week + 1.day
      wednesday = Time.zone.now.to_date.beginning_of_week + 2.day
      course_1 = FactoryGirl.create(:past_course, class_days: [monday])
      course_2 = FactoryGirl.create(:course, class_days: [tuesday])
      course_3 = FactoryGirl.create(:future_course, class_days: [wednesday])
      student = FactoryGirl.create(:student, courses: [course_1, course_2, course_3])
      expect(student.courses.total_class_days_until(Time.zone.now.to_date.end_of_week)).to eq [wednesday, tuesday, monday]
    end
  end

  describe '#export_students_emails' do
    it 'exports to students.txt file email addresses for students in course' do
      student = FactoryGirl.create(:student)
      filename = Rails.root.join('tmp','students.txt')
      student.course.export_students_emails(filename)
      expect(File.read(filename)).to include student.email
    end
  end
end
