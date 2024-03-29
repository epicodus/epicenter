include ActionView::Helpers::NumberHelper

feature "admin viewing an individual student's attendance" do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:student, :with_course) }
  let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }
  before { login_as(admin, scope: :admin) }

  scenario "an admin can view attendance records for an individual student" do
    visit course_student_path(student.course, student)
    expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
  end

  scenario "an admin can navigate through to the attendance record amendment page for a particular record" do
    travel_to student.course.start_date do
      visit course_student_path(student.course, student)
      first('.edit-attendance').click_link 'Edit'
      expect(page).to have_xpath("//input[@value='#{attendance_record.date}']")
    end
  end
end

feature 'viewing attendance records index page' do
  let(:course) { FactoryBot.create(:past_course) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [course])}
  let(:cohort) { course.cohort }
  let(:admin) { course.admin }
  let(:pair) { FactoryBot.create(:student, :with_all_documents_signed, courses: [course]) }
  let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: course.start_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id]) }

  before do
    course.update(class_days: [course.class_days.first, course.class_days.second])
  end

  context 'as an admin' do
    scenario 'shows daily attendance records' do
      login_as(admin, scope: :admin)
      visit student_attendance_records_path(student)
      expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
    end

    scenario 'shows absences for cohort' do
      non_cohort_course = FactoryBot.create(:past_course)
      student.courses << non_cohort_course
      cohort.courses << course
      login_as(admin, scope: :admin)
      visit student_attendance_records_path(student)
      expect(page).to have_content "Absent #{non_cohort_course.class_days.count + course.number_of_days_since_start - 1} out of #{student.allowed_absences} allowed absences in the program"
    end
  end

  context 'as a student' do
    scenario 'shows daily attendance records' do
      login_as(student, scope: :student)
      visit student_attendance_records_path(student)
      expect(page).to have_content attendance_record.date.strftime("%B %d, %Y")
    end

    scenario 'shows absences for course' do
      login_as(admin, scope: :admin)
      visit student_attendance_records_path(student)
      expect(page).to have_content "Absent #{course.number_of_days_since_start - 1} out of #{student.allowed_absences} allowed absences in the program"
    end

    scenario 'shows absences for all courses' do
      non_cohort_course = FactoryBot.create(:past_course)
      student.courses << non_cohort_course
      cohort.courses << course
      login_as(admin, scope: :admin)
      visit student_attendance_records_path(student)
      expect(page).to have_content "Absent #{non_cohort_course.class_days.count + course.number_of_days_since_start - 1} out of #{student.allowed_absences} allowed absences in the program"
    end

    scenario 'without absences shows message' do
      FactoryBot.create(:attendance_record, student: student, date: course.end_date, tardy: false, left_early: false, pairings_attributes: [pair_id: pair.id])
      login_as(admin, scope: :admin)
      visit student_attendance_records_path(student)
      expect(page).to have_content "No absences in the program!"
    end
  end

  scenario 'as a guest' do
    visit student_attendance_records_path(student)
    expect(page).to have_content 'You need to sign in'
  end
end
