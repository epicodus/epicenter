feature 'adding another course for a student', :js do
  let(:student) { FactoryBot.create(:student, :with_course) }
  let!(:other_course) { FactoryBot.create(:portland_ruby_course, description: 'other course') }
  let(:admin) { student.course.admin }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page' do
    visit student_courses_path(student)
    select other_course.description, from: 'enrollment_course_id_' + other_course.office.short_name
    click_on 'Add course'
    expect(page).to have_content "#{student.name} enrolled in #{other_course.description_and_office}"
  end

  scenario 'as an admin on the individual student page' do
    another_office = FactoryBot.create(:seattle_course).office
    visit student_courses_path(student)
    click_on another_office.short_name
    find('select#enrollment_course_id_' + another_office.short_name)
    expect(page.all('select#enrollment_course_id_' + another_office.short_name).first.text.include? other_course.office.name).to eq false
  end

  scenario 'as an admin on the individual student page' do
    visit student_courses_path(student)
    click_on 'PREVIOUS'
    find('select#enrollment_course_id_previous')
    expect(page.all('select#enrollment_course_id_previous').first.text.include? other_course.office.name).to eq false
  end

  scenario 'shows current cohort selection modal when adding course from different FT cohort' do
    cohort = FactoryBot.create(:ft_cohort, description: "existing cohort")
    student.courses = cohort.courses
    new_cohort = FactoryBot.create(:ft_cohort, description: "new cohort")
    visit student_courses_path(student)
    select new_cohort.courses.first.description, from: 'enrollment_course_id_' + new_cohort.office.short_name
    click_on 'Add course'
    expect(page).to have_content "#{student.name} enrolled in #{new_cohort.courses.first.description_and_office}"
    expect(page).to have_content "Confirm updated current cohort for #{student.name}"
    expect(page).to have_content "Previous current cohort: #{cohort.description}"
    cohort_select_box = find(:css, '#current_cohort_id') 
    expect(cohort_select_box).to have_content cohort.description
    expect(cohort_select_box).to have_content new_cohort.description
  end

  scenario 'updates course list before showing modal' do
    cohort = FactoryBot.create(:ft_cohort, description: "existing cohort")
    student.courses = cohort.courses
    new_cohort = FactoryBot.create(:ft_cohort, description: "new cohort")
    visit student_courses_path(student)
    select new_cohort.courses.first.reload.description, from: 'enrollment_course_id_' + new_cohort.office.short_name
    click_on 'Add course'
    section = find(:css, '#courses-list')
    expect(section).to have_content new_cohort.courses.first.reload.description
  end

  scenario 'does not show current cohort selection modal when adding PT course' do
    cohort = FactoryBot.create(:ft_cohort, description: "existing cohort")
    student.courses = cohort.courses
    pt_cohort = FactoryBot.create(:pt_intro_cohort, description: 'PT cohort')
    visit student_courses_path(student)
    select pt_cohort.courses.first.reload.description, from: 'enrollment_course_id_' + pt_cohort.office.short_name
    click_on 'Add course'
    expect(page).to have_content "#{student.name} enrolled in #{pt_cohort.courses.first.description_and_office}"
    expect(page).to_not have_content "Confirm updated current cohort for #{student.name}"
  end
end

feature 'adding full cohort for a student', :js do
  let!(:cohort) { FactoryBot.create(:ft_cohort) }
  let(:office) { cohort.office }
  let(:admin) { cohort.admin }
  let(:student) { FactoryBot.create(:student, courses: []) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page' do
    travel_to cohort.start_date do
      visit student_courses_path(student)
      click_on office.short_name
      select cohort.description, from: 'enrollment_cohort_id_' + office.short_name
      click_on 'Add cohort'
      expect(page).to have_content "#{student.name} enrolled in all current and future courses in #{cohort.description}."
    end
  end

  scenario 'shows current cohort selection modal when adding different FT cohort' do
    existing_cohort = FactoryBot.create(:ft_cohort, description: "existing cohort")
    student.courses = existing_cohort.courses
    visit student_courses_path(student)
    select cohort.description, from: 'enrollment_cohort_id_' + office.short_name
    click_on 'Add cohort'
    expect(page).to have_content "#{student.name} enrolled in all current and future courses in #{cohort.description}."
    expect(page).to have_content "Confirm updated current cohort for #{student.name}"
    expect(page).to have_content "Previous current cohort: #{existing_cohort.description}"
    cohort_select_box = find(:css, '#current_cohort_id') 
    expect(cohort_select_box).to have_content existing_cohort.description
    expect(cohort_select_box).to have_content cohort.description
  end

  scenario 'does not show current cohort selection modal when adding PT cohort' do
    student.courses = cohort.courses
    pt_cohort = FactoryBot.create(:pt_intro_cohort, description: "PT cohort", office: office)
    visit student_courses_path(student)
    select pt_cohort.description, from: 'enrollment_cohort_id_' + office.short_name
    click_on 'Add cohort'
    expect(page).to have_content "#{student.name} enrolled in all current and future courses in #{pt_cohort.description}."
    expect(page).to_not have_content "Confirm updated current cohort for #{student.name}"
  end
end

feature 'withdrawing a student from all courses', :js do
  let(:admin) { FactoryBot.create(:admin, :with_course) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin drop all for a student with payments and no attendance records' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_upfront_payment, courses: [admin.courses.first])
    visit student_courses_path(student)
    click_on 'Drop All'
    accept_js_alert
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end

  scenario 'as an admin drop all for a student with attendance records and no payments' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_upfront_payment, courses: [admin.courses.first])
    FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
    visit student_courses_path(student)
    click_on 'Drop All'
    accept_js_alert
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end

  scenario 'as an admin drop all for a student with enrollments but no payments and no attendance records' do
    student = FactoryBot.create(:student, courses: [admin.courses.first])
    visit student_courses_path(student)
    click_on 'Drop All'
    accept_js_alert
    expect(page).to have_content "#{student.email} has been withdrawn from all courses."
  end
end

feature 'deleting a course for a student', :js do
  let(:course1) { FactoryBot.create(:course) }
  let(:course2) { FactoryBot.create(:midway_internship_course) }
  let(:admin) { course1.admin }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin deleting a course that is not the last course for that student' do
    student = FactoryBot.create(:student, courses: [course1, course2])
    visit student_courses_path(student)
    within "#student-course-#{course2.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{course2.description}"
    expect(page).to have_content "#{course1.description}"
  end

  scenario 'as an admin deleting the last course for student without payments or attendance records' do
    student = FactoryBot.create(:student, courses: [course1])
    visit student_courses_path(student)
    within "#student-course-#{course1.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{course1.description}"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin deleting the last course for student with payments' do
    student = FactoryBot.create(:student, :with_ft_cohort, :with_upfront_payment)
    student.courses.last.destroy
    course = student.course
    visit student_courses_path(student)
    within "#student-course-#{course.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{course.description}"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin deleting the last course for student with attendance records' do
    student = FactoryBot.create(:student, courses: [course1])
    FactoryBot.create(:attendance_record, student: student, date: student.course.start_date)
    visit student_courses_path(student)
    within "#student-course-#{course1.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{course1.description}"
    expect(page).to_not have_content "archived"
    expect(page).to_not have_content "expunged"
  end

  scenario 'as an admin permanently deleting a course from the withdrawn courses list' do
    student = FactoryBot.create(:student, courses: [course1, course2])
    student.enrollments.find_by(course: course2).destroy
    visit student_courses_path(student)
    click_on 'destroy'
    accept_js_alert
    expect(page).to have_content "Enrollment permanently removed"
  end

  scenario 'shows current cohort selection modal when removing FT course' do
    cohort_1 = FactoryBot.create(:ft_cohort, description: "cohort 1")
    cohort_2 = FactoryBot.create(:ft_cohort, description: "cohort 2")
    student = FactoryBot.create(:student, courses: cohort_1.courses + cohort_2.courses)
    visit student_courses_path(student)
    within "#student-course-#{cohort_1.courses.first.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{cohort_1.courses.first.description_and_office}"
    expect(page).to have_content "Confirm updated current cohort for #{student.name}"
    cohort_select_box = find(:css, '#current_cohort_id') 
    expect(cohort_select_box).to have_content cohort_1.description
    expect(cohort_select_box).to have_content cohort_2.description
  end
  
  scenario 'does not show current cohort selection modal when removing PT course' do
    cohort_1 = FactoryBot.create(:ft_cohort, description: "cohort 1")
    cohort_2 = FactoryBot.create(:ft_cohort, description: "cohort 2")
    pt_cohort = FactoryBot.create(:pt_intro_cohort, description: "PT cohort")
    student = FactoryBot.create(:student, courses: cohort_1.courses + cohort_2.courses + pt_cohort.courses)
    visit student_courses_path(student)
    within "#student-course-#{pt_cohort.courses.first.id}" do
      click_on 'Withdraw'
    end
    accept_js_alert
    expect(page).to have_content "#{student.name} has been withdrawn from #{pt_cohort.courses.first.description_and_office}"
    expect(page).to_not have_content "Confirm updated current cohort for #{student.name}"
  end
end
