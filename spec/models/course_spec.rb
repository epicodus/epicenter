describe Course do
  it { should belong_to :admin }
  it { should have_many :students }
  it { should have_many(:attendance_records).through(:students) }
  it { should have_many :code_reviews }
  it { should have_many(:internships).through(:course_internships) }

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
      expect(course.teacher_and_description).to eq "#{course.description} (#{course.teacher})"
    end
  end

  describe '#other_course_students' do
    it 'returns all other students for a course except the selected student' do
      course = FactoryGirl.create(:course)
      student_1 = FactoryGirl.create(:student, course: course)
      student_2 = FactoryGirl.create(:student, course: course)
      student_3 = FactoryGirl.create(:student, course: course)
      expect(course.other_course_students(student_3)).to eq [student_1, student_2]
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
    it 'returns all courses that are internship courses' do
      internship_course = FactoryGirl.create(:internship_course, active: true)
      FactoryGirl.create(:course)
      expect(Course.active_internship_courses).to eq [internship_course]
    end
  end

  describe '#inactive_internship_courses' do
    it 'returns all courses that are internship courses' do
      internship_course = FactoryGirl.create(:internship_course, active: false)
      FactoryGirl.create(:course)
      expect(Course.inactive_internship_courses).to eq [internship_course]
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

  describe '#realize_tuition_in_less_accounting', :vcr, :stripe_mock, :stub_mailgun, :stub_less_accounting do
    it 'realizes the tuition for a course when it has concluded' do
      student = FactoryGirl.create :user_with_credit_card, email: 'test@test.com'
      payment = FactoryGirl.create(:payment_with_credit_card, student: student)
      student.course.realize_tuition_in_less_accounting
      payment_amount = (student.course.credit_cost * (student.plan.total_amount / student.plan.credits)) / 100
      expect(RestClient::Request).to have_received(:execute).with(
        url: "https://epicodus.lessaccounting.com/payments.json?api_key=#{ENV['LESS_ACCOUNTING_API_KEY']}&payment[title]=#{student.name}&payment[amount]=#{payment_amount}&payment[date]=#{Date.today.strftime('%Y-%m-%d')}&payment[bank_account_id]=120215&payment[expense_category_id]=1496063&payment[payment_type]=expense%20refund",
        method: :post,
        user: ENV['LESS_ACCOUNTING_EMAIL'],
        password: ENV['LESS_ACCOUNTING_PASSWORD']
      )
    end
  end
end
