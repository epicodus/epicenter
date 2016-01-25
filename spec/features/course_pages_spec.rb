feature 'creating a course' do
  scenario 'not logged in' do
    visit new_course_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit new_course_path
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to course#new page', js: true do
      visit root_path
      click_on admin.current_course.description
      click_on 'Add a course'
      expect(page).to have_content 'New course'
    end
    scenario 'with invalid input' do
      visit new_course_path
      click_on 'Create Course'
      expect(page).to have_content "can't be blank"
    end

    scenario 'from scratch', js: true do
      travel_to Date.parse('November 16, 2015') do
        visit new_course_path
        fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
        fill_in 'Start time', with: '8:00 AM'
        fill_in 'End time', with: '5:00 PM'
        find('td', text: 16).click
        find('td', text: 19).click
        click_on 'Create Course'
        expect(page).to have_content 'Class has been created'
        expect(page).to have_content 'Code Reviews'
      end
    end

    scenario 'cloned from another course' do
      previous_course = FactoryGirl.create(:course, description: 'Ruby/Rails - Fall 2014')
      code_review = FactoryGirl.create(:code_review, course: previous_course)
      visit new_course_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      fill_in 'Start time', with: '8:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find(:xpath, "//input[@id='course_class_days']").set "2015-09-06,2015-09-07,2015-09-08"
      select previous_course.description, from: 'Import code reviews from previous course'
      click_on 'Create Course'
      expect(page).to have_content 'Class has been created'
      expect(page).to have_content code_review.title
    end
  end
end

feature 'editing a course' do
  let(:course) { FactoryGirl.create(:course) }

  scenario 'not logged in' do
    visit edit_course_path(course)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit edit_course_path(course)
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin, current_course: course) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to course#edit page', js: true do
      visit root_path
      click_on "Edit #{course.description}"
      expect(page).to have_content "Edit #{course.description}"
    end

    scenario 'with invalid input' do
      visit edit_course_path(course)
      fill_in 'Description', with: ''
      click_on 'Update Course'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with valid input' do
      visit edit_course_path(course)
      fill_in 'Description', with: 'PHP/Drupal - Summer 2015'
      fill_in 'Start time', with: '8:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find(:xpath, "//input[@id='course_class_days']").set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Update Course'
      expect(page).to have_content "PHP/Drupal - Summer 2015 has been updated"
      expect(page).to have_content 'Code Reviews'
    end
  end
end

feature 'deleting a course' do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'admin clicks delete button' do
    visit edit_course_path(course)
    click_on 'Delete'
    expect(page).to have_content "#{course.description} has been deleted"
  end
end

feature 'adding another course for a student' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:other_course) { FactoryGirl.create(:course, description: 'Other course') }
  let!(:other_student) { FactoryGirl.create(:student, sign_in_count: 1) }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'as an admin on the individual student page' do
    visit student_path(student)
    find('#student-nav li.student-courses').click
    select other_course.description, from: 'student_course_id'
    click_on 'Add course'
    expect(page).to have_content other_course.description
  end

  scenario 'as an admin on the student roster page' do
    visit course_students_path(student.course)
    select other_student.name, from: 'enrollment_student_id'
    click_on 'Add student'
    expect(page).to have_content "#{other_student.name} has been added to this course"
  end
end

feature 'deleting a course for a student' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:other_course) { FactoryGirl.create(:course, description: 'Other course') }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }

  scenario 'as an admin' do
    student.update(course: other_course)
    visit student_path(student)
    find('#student-nav li.student-courses').click
    within "#student-course-#{other_course.id}" do
      click_on 'Withdraw'
    end
    expect(page).to have_content "#{other_course.description} has been removed"
  end
end

feature 'viewing courses as a student' do
  let(:student) { FactoryGirl.create(:student) }
  before { login_as(student, scope: :student) }

  scenario 'via profile page' do
    visit student_path(student)
    find('#student-nav li.student-courses').click
    expect(page).to have_content "Current course"
  end

end
