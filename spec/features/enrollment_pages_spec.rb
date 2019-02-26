feature 'adding another course for a student' do
  let(:student) { FactoryBot.create(:student) }
  let!(:other_course) { FactoryBot.create(:portland_ruby_course) }
  let!(:other_student) { FactoryBot.create(:student, sign_in_count: 1) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page' do
    visit student_courses_path(student)
    select other_course.description, from: 'enrollment_course_id_' + other_course.office.short_name
    click_on 'Add course'
    expect(page).to have_content "#{student.name} enrolled in #{other_course.description}."
  end

  scenario 'as an admin on the individual student page', js: true do
    another_office = FactoryBot.create(:seattle_course).office
    visit student_courses_path(student)
    click_on another_office.short_name
    find('select#enrollment_course_id_' + another_office.short_name)
    expect(page.all('select#enrollment_course_id_' + another_office.short_name).first.text.include? other_course.office.name).to eq false
  end

  scenario 'as an admin on the individual student page', js: true do
    visit student_courses_path(student)
    click_on 'PREVIOUS'
    find('select#enrollment_course_id_previous')
    expect(page.all('select#enrollment_course_id_previous').first.text.include? other_course.office.name).to eq false
  end

  scenario 'as an admin on the student roster page' do
    visit course_path(student.course)
    select other_student.name, from: 'enrollment_student_id'
    click_on 'Add student'
    expect(page).to have_content "#{other_student.name} enrolled in #{student.course.description}"
  end
end

feature 'adding full cohort for a student' do
  let!(:cohort) { FactoryBot.create(:full_cohort) }
  let(:office) { cohort.office }
  let(:admin) { cohort.admin }
  let(:student) { FactoryBot.create(:student_without_courses, office: cohort.office) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page', js: true do
    travel_to cohort.start_date do
      visit student_courses_path(student)
      click_on office.short_name
      select cohort.description, from: 'enrollment_cohort_id_' + office.short_name
      click_on 'Add cohort'
      expect(page).to have_content "#{student.name} enrolled in all current and future courses in #{cohort.description}."
    end
  end
end

feature 'withdrawing a student from all courses' do
  let(:course1) { FactoryBot.create(:course) }
  let(:course2) { FactoryBot.create(:internship_course) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin drop all for a student with payments and no attendance records' do
    student = FactoryBot.create(:student_with_upfront_payment)
    visit student_courses_path(student)
    click_on 'Drop All'
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end

  scenario 'as an admin drop all for a student with attendance records and no payments' do
    student = FactoryBot.create(:student_with_upfront_payment)
    FactoryBot.create(:attendance_record, student: student)
    visit student_courses_path(student)
    click_on 'Drop All'
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end

  scenario 'as an admin drop all for a student with enrollments but no payments and no attendance records' do
    student = FactoryBot.create(:student)
    visit student_courses_path(student)
    click_on 'Drop All'
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end
end

feature 'deleting a course for a student' do
  let(:course1) { FactoryBot.create(:course) }
  let(:course2) { FactoryBot.create(:midway_internship_course) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin deleting a course that is not the last course for that student' do
    student = FactoryBot.create(:student, courses: [course1, course2])
    visit student_courses_path(student)
    within "#student-course-#{course2.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course2.description} has been removed"
    expect(page).to have_content "#{course1.description}"
  end

  scenario 'as an admin deleting the last course for student without payments or attendance records' do
    student = FactoryBot.create(:student, courses: [course1])
    visit student_courses_path(student)
    within "#student-course-#{course1.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course1.description} has been removed"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin deleting the last course for student with payments' do
    student = FactoryBot.create(:student_with_upfront_payment)
    course = student.course
    visit student_courses_path(student)
    within "#student-course-#{course.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course.description} has been removed"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin deleting the last course for student with attendance records' do
    student = FactoryBot.create(:student, courses: [course1])
    FactoryBot.create(:attendance_record, student: student)
    visit student_courses_path(student)
    within "#student-course-#{course1.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course1.description} has been removed"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin permanently deleting a course from the withdrawn courses list' do
    student = FactoryBot.create(:student, courses: [course1, course2])
    student.enrollments.find_by(course: course2).destroy
    visit student_courses_path(student)
    click_on 'destroy'
    expect(page).to have_content "Enrollment permanently removed"
  end
end
