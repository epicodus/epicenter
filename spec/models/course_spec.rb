describe Course do
  it { should belong_to(:admin).optional }
  it { should belong_to :office }
  it { should belong_to :language }
  it { should belong_to(:cohort) }
  it { should belong_to(:track).optional }
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many(:internships).through(:course_internships) }
  it { should have_many(:interview_assignments) }
  it { should have_many(:internship_assignments) }
  it { should validate_presence_of(:office_id) }
  it { should validate_presence_of(:start_date) }
  it { should validate_presence_of(:end_date) }

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

  context 'scopes' do
    describe 'default scope' do
      it 'orders by start_date ascending' do
        future_course = FactoryBot.create(:future_course)
        past_course = FactoryBot.create(:past_course)
        expect(Course.all).to eq [past_course, future_course]
      end
    end

    describe 'course scopes' do
      let!(:ft_course) { FactoryBot.create(:course) }
      let!(:pt_intro_course) { FactoryBot.create(:part_time_course, track: FactoryBot.create(:part_time_track)) }
      let!(:pt_full_stack_course) { FactoryBot.create(:part_time_course, track: FactoryBot.create(:part_time_c_react_track)) }
      let!(:pt_js_react_course) { FactoryBot.create(:part_time_course, track: FactoryBot.create(:track, description: 'Part-Time JS/React')) }

      it '#fulltime_courses' do
        expect(Course.fulltime_courses).to eq [ft_course]
      end

      it '#parttime_intro_courses' do
        expect(Course.parttime_intro_courses).to eq [pt_intro_course]
      end

      it '#parttime_full_stack_courses' do
        expect(Course.parttime_full_stack_courses).to eq [pt_full_stack_course]
      end

      it '#parttime_intro_courses' do
        expect(Course.parttime_js_react_courses).to eq [pt_js_react_course]
      end

      it '#cirr_parttime_courses' do
        expect(Course.cirr_parttime_courses).to eq [pt_intro_course, pt_js_react_course]
      end

      it '#cirr_fulltime_courses' do
        expect(Course.cirr_fulltime_courses).to eq [ft_course, pt_full_stack_course]
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

    describe '.level' do
      it 'returns all courses with given language level' do
        intro_course = FactoryBot.create(:course)
        rails_course = FactoryBot.create(:level_3_just_finished_course)
        expect(Course.level(3)).to eq [rails_course]
      end
    end
  end

  describe '#current_and_previous_courses' do
    it 'returns all current and previous courses' do
      previous_course = FactoryBot.create(:past_course)
      current_course = FactoryBot.create(:course)
      future_course = FactoryBot.create(:future_course)
      expect(Course.current_and_previous_courses).to eq [previous_course, current_course]
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

  describe '#courses_for' do
    it 'returns all courses for a certain office' do
      portland_course = FactoryBot.create(:portland_course)
      FactoryBot.create(:seattle_course)
      expect(Course.courses_for(portland_course.office)).to eq [portland_course]
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
      course.admin.destroy
      expect(course.reload.teacher).to eq 'Unknown teacher'
    end
  end

  describe '#teacher_and_description' do
    it 'returns the teacher name and course description and track' do
      admin = FactoryBot.create(:admin)
      track = FactoryBot.create(:track)
      course = FactoryBot.create(:course, admin: admin, track: track)
      expect(course.teacher_and_description).to eq "#{course.office.name} - #{course.description} (#{course.teacher}) [#{track.description} track]"
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

  describe '#courses_all_locations' do
    it 'returns all courses with same description' do
      course = FactoryBot.create(:course)
      course2 = FactoryBot.create(:course, start_date: course.start_date, end_date: course.end_date)
      expect(course.courses_all_locations).to include(course, course2)
    end
  end

  describe '#students_all_locations' do
    it 'returns all students in courses with same description' do
      course = FactoryBot.create(:course)
      course2 = FactoryBot.create(:course, start_date: course.start_date, end_date: course.end_date)
      student_1 = FactoryBot.create(:student, course: course)
      student_2 = FactoryBot.create(:student, course: course2)
      expect(course.students_all_locations).to include(student_1, student_2)
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

  describe '#export_students_emails' do
    it 'exports to students.txt file names & email addresses for students in course' do
      student = FactoryBot.create(:student, :with_course)
      filename = Rails.root.join('tmp','students.txt')
      student.course.export_students_emails(filename)
      expect(File.read(filename)).to include student.email
    end
  end

  describe '.move_submissions' do
    it 'moves submissions for a student from one course to another' do
      course_1 = FactoryBot.create(:course)
      course_2 = FactoryBot.create(:course)
      student = FactoryBot.create(:student, courses: [course_1])
      cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
      cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
      submission = FactoryBot.create(:submission, student: student, code_review: cr_1)
      Course.move_submissions(student: student, source_course: course_1, destination_course: course_2)
      expect(cr_1.submission_for(student)).to eq nil
      expect(cr_2.submission_for(student)).to eq submission
    end

    it 'does not move submission if no code review with that title found' do
      course_1 = FactoryBot.create(:course)
      course_2 = FactoryBot.create(:course)
      student = FactoryBot.create(:student, courses: [course_1])
      cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
      cr_2 = FactoryBot.create(:code_review, course: course_2, title: "different title")
      submission = FactoryBot.create(:submission, student: student, code_review: cr_1)
      Course.move_submissions(student: student, source_course: course_1, destination_course: course_2)
      expect(cr_1.submission_for(student)).to eq submission
      expect(cr_2.submission_for(student)).to eq nil
    end

    it 'does not try to move submission if no submission found' do
      course_1 = FactoryBot.create(:course)
      course_2 = FactoryBot.create(:course)
      student = FactoryBot.create(:student, courses: [course_1])
      cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
      cr_2 = FactoryBot.create(:code_review, course: course_1, title: "other code review")
      cr_3 = FactoryBot.create(:code_review, course: course_2, title: "same title")
      submission = FactoryBot.create(:submission, student: student, code_review: cr_2)
      Course.move_submissions(student: student, source_course: course_1, destination_course: course_2)
      expect(submission.reload.code_review).to eq cr_2
    end
  end

  context 'building course' do

    context 'from layout file' do

      describe 'sets parttime flag' do
        it 'true for pt course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: true)
          course = FactoryBot.create(:part_time_course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.parttime).to eq true
        end

        it 'false for ft course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.parttime).to eq false
        end
      end

      describe 'sets internship_course flag' do
        it 'true for internship course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(internship: true)
          course = FactoryBot.create(:internship_course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.internship_course).to eq true
        end

        it 'false for non-internship course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(internship: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.internship_course).to_not eq true
        end
      end

      describe 'sets class times', :dont_stub_class_times do
        it 'for ft course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.class_times.count).to eq 5
          expect(course.class_times.first.wday).to eq 1
          expect(course.class_times.first.start_time).to eq '8:00'
          expect(course.class_times.first.end_time).to eq '17:00'
          expect(course.class_times.last.wday).to eq 5
          expect(course.class_times.last.start_time).to eq '8:00'
          expect(course.class_times.last.end_time).to eq '17:00'
        end

        it 'for pt course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: true)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.class_times.count).to eq 4
          expect(course.class_times.first.wday).to eq 0
          expect(course.class_times.first.start_time).to eq '9:00'
          expect(course.class_times.first.end_time).to eq '17:00'
          expect(course.class_times.last.wday).to eq 3
          expect(course.class_times.last.start_time).to eq '18:00'
          expect(course.class_times.last.end_time).to eq '21:00'
        end
      end

      describe 'calculates course start and end times', :dont_stub_class_times do
        it '#start_time_today' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          travel_to Date.today + 12.hours do
            expect(course.start_time_today).to eq Time.zone.now.in_time_zone(course.office.time_zone).beginning_of_day + 8.hours
          end
        end

        it '#end_time_today' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          travel_to course.start_date + 12.hours do
            expect(course.end_time_today).to eq Time.zone.now.in_time_zone(course.office.time_zone).beginning_of_day + 17.hours
          end
        end

        it '#start_time_on_day' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          travel_to course.start_date + 5.days do
            expect(course.start_time_on_day(course.start_date)).to eq DateTime.parse('2017-03-13 08:00 EDT')
          end
        end

        it '#end_time_on_day' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: false)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          travel_to course.start_date + 5.days do
            expect(course.end_time_on_day(course.start_date)).to eq DateTime.parse('2017-03-13 17:00 EDT')
          end
        end
      end

      describe "calculates class days, start_date, end_date" do
        it 'for course during period without any holidays' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 15)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2017-03-13')
          expect(course.end_date).to eq Date.parse('2017-03-31')
          expect(course.class_days.count).to eq 15
        end

        it 'for course during period with holidays' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 15)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-05-22'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2017-05-22')
          expect(course.end_date).to eq Date.parse('2017-06-09')
          expect(course.class_days.count).to eq 14
        end

        it 'for course during period with holiday week' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 15)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-11-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2017-11-13')
          expect(course.end_date).to eq Date.parse('2017-12-08')
          expect(course.class_days.count).to eq 15
        end

        it 'for internship course during period without holidays' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 35, internship: true)
          course = FactoryBot.create(:internship_course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2017-03-13')
          expect(course.end_date).to eq Date.parse('2017-04-28')
          expect(course.class_days.count).to eq 35
        end

        it 'for internship course during period with holiday weeks' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 35, internship: true)
          course = FactoryBot.create(:internship_course, start_date: Date.parse('2017-11-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2017-11-13')
          expect(course.end_date).to eq Date.parse('2018-01-12')
          expect(course.class_days.count).to eq 34
        end

        it 'for part-time full-track course with holiday' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 23, part_time: true)
          course = FactoryBot.create(:intro_part_time_c_react_course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2021-01-04')
          expect(course.end_date).to eq Date.parse('2021-02-10')
          expect(course.class_days.count).to eq 22 # 22 due to time period including 1 holiday
          expect(course.class_days.last.wednesday?).to eq true
        end

        it 'for course starting on a tuesday due to holiday' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_days: 15)
          course = FactoryBot.create(:course, start_date: Date.parse('2023-01-02'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.start_date).to eq Date.parse('2023-01-03') # monday is a holiday
          expect(course.end_date).to eq Date.parse('2023-01-20') # friday
          expect(course.class_days.count).to eq 13 # due to time period including 2 holidays
        end
      end

      describe 'sets description' do
        it 'sets description for course to date and language' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper
          course = FactoryBot.create(:course, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.description).to eq "#{course.start_date.strftime('%Y-%m')} #{course.language.name}"
        end

        it 'sets description for internship course to date and language and track' do
          track = FactoryBot.create(:track)
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(internship: true)
          course = FactoryBot.create(:course, track: track, start_date: Date.parse('2021-01-04'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.description).to eq "#{course.start_date.strftime('%Y-%m')} #{course.language.name} (#{track.description})"
        end
      end

      describe 'builds code reviews' do
        it 'when no code reviews' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 0)
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 0
        end

        it 'for full-time course with 1 code review with 1 objective' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 1
          expect(course.code_reviews.first.objectives.count).to eq 1
          expect(course.code_reviews.first.visible_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone) + 8.hours
          expect(course.code_reviews.first.due_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone) + 17.hours
        end

        it 'for full-time course with 2 code reviews with 1 and 2 objectives' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 2)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 2
          expect(course.code_reviews.first.objectives.count).to eq 1
          expect(course.code_reviews.last.objectives.count).to eq 2
          expect(course.code_reviews.first.visible_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone).beginning_of_day + 8.hours
          expect(course.code_reviews.first.due_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone).beginning_of_day + 17.hours
          expect(course.code_reviews.last.visible_date).to eq Date.parse('2017-03-24').in_time_zone(course.office.time_zone).beginning_of_day + 8.hours
          expect(course.code_reviews.last.due_date).to eq Date.parse('2017-03-24').in_time_zone(course.office.time_zone).beginning_of_day + 17.hours
        end

        it 'for part-time course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(part_time: true, number_of_code_reviews: 1)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:part_time_course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 1
          expect(course.code_reviews.first.objectives.count).to eq 1
          expect(course.code_reviews.first.visible_date).to eq Date.parse('2017-03-16').in_time_zone(course.office.time_zone).beginning_of_day + 8.hours
          expect(course.code_reviews.first.due_date).to eq Date.parse('2017-03-19').in_time_zone(course.office.time_zone).beginning_of_day + 8.hours
        end

        it 'for reflection' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1, journal: true)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.first.journal).to eq true
        end

        it 'for code review where submissions not required' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1, submissions_not_required: true)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.first.submissions_not_required).to eq true
        end

        it 'for code review that should always be visible to students' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1, always_visible: true)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.first.visible_date).to eq nil
          expect(course.code_reviews.first.due_date).to eq nil
        end

        it 'overriding general course visible and due date settings' do
          code_review_params = course_layout_params_helper(part_time: true, number_of_code_reviews: 1)
          code_review_params['code_reviews']['details'].first['visible_day_of_week'] = 'friday'
          code_review_params['code_reviews']['details'].first['visible_time'] = '9:00'
          code_review_params['code_reviews']['details'].first['due_days_later'] = 0
          code_review_params['code_reviews']['details'].first['due_time'] = '17:00'
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return code_review_params
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:part_time_course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 1
          expect(course.code_reviews.first.objectives.count).to eq 1
          expect(course.code_reviews.first.visible_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone).beginning_of_day + 9.hours
          expect(course.code_reviews.first.due_date).to eq Date.parse('2017-03-17').in_time_zone(course.office.time_zone).beginning_of_day + 17.hours
        end

        it 'overriding general course submissions_not_required and always_visible settings' do
          code_review_params = course_layout_params_helper(number_of_code_reviews: 1, submissions_not_required: false)
          code_review_params['code_reviews']['details'].first['submissions_not_required'] = true
          code_review_params['code_reviews']['details'].first['always_visible'] = true
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return code_review_params
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.first.submissions_not_required).to eq true
          expect(course.code_reviews.first.visible_date).to eq nil
          expect(course.code_reviews.first.due_date).to eq nil
        end

        it 'adding code reviews to existing course' do
          course = FactoryBot.create(:course)
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course.update(layout_file_path: 'example_course_layout_path')
          expect(course.code_reviews.count).to eq 1
        end

        it 'adding only additional code reviews to existing course' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 1
          course.update(layout_file_path: nil)
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 2)
          course.update(layout_file_path: 'example_course_layout_path')
          expect(course.code_reviews.count).to eq 2
        end

        it 'does not add code reviews if layout file path not changed' do
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 1)
          allow(Github).to receive(:get_content).with('example_code_review').and_return({:content=>"---\n"})
          course = FactoryBot.create(:course, start_date: Date.parse('2017-03-13'), layout_file_path: 'example_course_layout_path', class_days: [])
          expect(course.code_reviews.count).to eq 1
          allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return course_layout_params_helper(number_of_code_reviews: 2)
          course.update(layout_file_path: 'example_course_layout_path')
          expect(course.code_reviews.count).to eq 1
        end
      end
    end

    context 'manually without layout file' do
      describe "sets start and end dates from class_days" do
        let(:course) { FactoryBot.create(:course) }

        it "returns a valid start date when set_start_and_end_dates is successful" do
          expect(course.start_date).to eq course.class_days.first
        end

        it "returns a valid end date when set_start_and_end_dates is successful" do
          expect(course.end_date).to eq course.class_days.last
        end
      end
    end

    it 'allows manual setting of description on creation' do
      course = FactoryBot.build(:course)
      course.description = 'an awesome course'
      course.save
      expect(course.description).to eq 'an awesome course'
    end
  end

  context 'when class days changed' do
    it 'updates start and end dates' do
      course = FactoryBot.create(:course)
      new_start_date = course.class_days.sort.first - 1.week
      new_end_date = course.class_days.sort.last + 1.week
      course.class_days << new_start_date
      course.class_days << new_end_date
      course.save
      course.reload
      expect(course.start_date).to eq new_start_date
      expect(course.end_date).to eq new_end_date
    end

    it 'updates description' do
      course = FactoryBot.create(:course, class_days: [Date.parse('2021-01-03')])
      course.class_days << Date.parse('2020-12-10')
      course.save
      course.reload
      expect(course.description).to eq '2020-12 Intro'
    end
  end
end

# helpers

def course_layout_params_helper(attributes = {})
  part_time = attributes[:part_time] || false
  internship = attributes[:internship] || false
  number_of_days = attributes[:number_of_days] || 15
  if part_time
    class_times = class_times_pt
    code_reviews = code_review_params_helper(number_of_code_reviews: attributes[:number_of_code_reviews] || 0, visible_day_of_week: 'thursday', due_days_later: 3, due_time: '8:00', submissions_not_required: attributes[:submissions_not_required], always_visible: attributes[:always_visible])
  else
    class_times = class_times_ft
    code_reviews = code_review_params_helper(number_of_code_reviews: attributes[:number_of_code_reviews] || 0, visible_day_of_week: 'friday', due_days_later: 0, due_time: '17:00', submissions_not_required: attributes[:submissions_not_required], always_visible: attributes[:always_visible], journal: attributes[:journal])
  end
  { 'part_time' => part_time, 'internship' => internship, 'number_of_days' => number_of_days, 'class_times' => class_times, 'code_reviews' => code_reviews }
end

def code_review_params_helper(attributes)
  code_review_params = { 'settings' => {}, 'details' => [] }
  code_review_params['settings']['visible_day_of_week'] = attributes[:visible_day_of_week]
  code_review_params['settings']['visible_time'] = '8:00'
  code_review_params['settings']['due_days_later'] = attributes[:due_days_later]
  code_review_params['settings']['due_time'] = attributes[:due_time]
  code_review_params['settings']['submissions_not_required'] = attributes[:submissions_not_required]
  code_review_params['settings']['always_visible'] = attributes[:always_visible]
  attributes[:number_of_code_reviews].times do |cr_num|
    objectives = []
    (cr_num+1).times do |obj_num|
      objectives << "Test objective #{obj_num+1}"
    end
    code_review_params['details'] << { 'title' => "Code Review #{cr_num+1}", 'visible_class_week' => cr_num+1, 'filename' => "example_code_review", 'journal' => attributes[:journal], 'objectives' => objectives }
  end
  code_review_params
end

def class_times_pt
  { 'Sunday' => '9:00-17:00', 'Monday' => '18:00-21:00', 'Tuesday' => '18:00-21:00', 'Wednesday' => '18:00-21:00' }
end

def class_times_ft
  { 'Monday' => '8:00-17:00', 'Tuesday' => '8:00-17:00', 'Wednesday' => '8:00-17:00', 'Thursday' => '8:00-17:00', 'Friday' => '8:00-17:00' }
end
