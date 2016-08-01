feature 'adding another course for a student' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:other_course) { FactoryGirl.create(:course, description: 'Other course') }
  let!(:other_student) { FactoryGirl.create(:student, sign_in_count: 1) }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

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
  let(:student) { FactoryGirl.create(:student) }
  let!(:other_course) { FactoryGirl.create(:course, description: 'Other course') }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'as an admin' do
    student.update(course: other_course)
    visit student_courses_path(student)
    within "#student-course-#{other_course.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{other_course.description} has been removed"
  end
end
