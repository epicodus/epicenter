feature 'adding another course for a student' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:other_course) { FactoryGirl.create(:portland_ruby_course) }
  let!(:other_student) { FactoryGirl.create(:student, sign_in_count: 1) }
  let(:admin) { FactoryGirl.create(:admin) }

  before do
    allow_any_instance_of(Student).to receive(:update_close_io)
    login_as(admin, scope: :admin)
  end

  scenario 'as an admin on the individual student page' do
    visit student_courses_path(student)
    select other_course.description, from: 'student_course_id'
    click_on 'Add course'
    expect(page).to have_content other_course.description
  end

  scenario 'as an admin on the student roster page' do
    visit course_path(student.course)
    select other_student.name, from: 'enrollment_student_id'
    click_on 'Add student'
    expect(page).to have_content "#{other_student.name} has been added to #{student.course.description}"
  end
end

feature 'deleting a course for a student' do
  let(:course1) { FactoryGirl.create(:course) }
  let(:course2) { FactoryGirl.create(:internship_course) }
  let(:student) { FactoryGirl.create(:student, courses: [course1, course2]) }
  let(:admin) { FactoryGirl.create(:admin) }

  before do
    allow_any_instance_of(Student).to receive(:update_close_io)
    login_as(admin, scope: :admin)
  end

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
