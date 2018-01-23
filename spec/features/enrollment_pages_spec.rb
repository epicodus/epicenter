feature 'adding another course for a student' do
  let(:student) { FactoryBot.create(:student) }
  let!(:other_course) { FactoryBot.create(:portland_ruby_course) }
  let!(:other_student) { FactoryBot.create(:student, sign_in_count: 1) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page' do
    visit student_courses_path(student)
    select other_course.description, from: 'enrollment_course_id'
    click_on 'Add course'
    expect(page).to have_content "#{student.name} enrolled in #{other_course.description}."
  end

  scenario 'as an admin on the student roster page' do
    visit course_path(student.course)
    select other_student.name, from: 'enrollment_student_id'
    click_on 'Add student'
    expect(page).to have_content "#{other_student.name} enrolled in #{student.course.description}"
  end
end

feature 'deleting a student' do
  let(:course1) { FactoryBot.create(:course) }
  let(:course2) { FactoryBot.create(:internship_course) }
  let(:student) { FactoryBot.create(:student, courses: [course1, course2]) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin deleting a student with enrollments' do
    visit student_courses_path(student)
    click_on 'Drop All'
    expect(page).to have_content "#{student.name} has been archived!"
  end

  scenario 'as an admin deleting a student without enrollments' do
    student.courses = []
    visit student_courses_path(student)
    click_on 'Archive student'
    expect(page).to have_content "#{student.name} has been archived!"
  end
end

feature 'deleting a course for a student' do
  let(:course1) { FactoryBot.create(:course) }
  let(:course2) { FactoryBot.create(:internship_course) }
  let(:student) { FactoryBot.create(:student, courses: [course1, course2]) }
  let(:admin) { FactoryBot.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin deleting a course that is not the last course for that student' do
    visit student_courses_path(student)
    within "#student-course-#{course2.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course2.description} has been removed"
    expect(page).to have_content "#{course1.description}"
  end

  scenario 'as an admin deleting the last course for that student' do
    visit student_courses_path(student)
    within "#student-course-#{course2.id}" do
      click_on 'Withdraw'
    end
    within "#student-course-#{course1.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{course1.description} has been removed. #{student.name} has been archived!"
  end

  scenario 'as an admin permanently deleting a course from the withdrawn courses list' do
    student.enrollments.find_by(course: course2).destroy
    visit student_courses_path(student)
    click_on 'destroy'
    expect(page).to have_content "Enrollment permanently removed"
  end
end
