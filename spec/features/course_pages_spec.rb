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
        select admin.name, from: 'Teacher'
        fill_in 'Start time', with: '8:00 AM'
        fill_in 'End time', with: '5:00 PM'
        find('td', text: 16).click
        find('td', text: 19).click
        click_on 'Create Course'
        expect(page).to have_content 'Course has been created'
        expect(page).to have_content 'Code reviews'
      end
    end

    scenario 'cloned from another course' do
      previous_course = FactoryGirl.create(:course, description: 'Ruby/Rails - Fall 2014')
      code_review = FactoryGirl.create(:code_review, course: previous_course)
      visit new_course_path
      fill_in 'Description', with: 'Ruby/Rails - Summer 2015'
      select admin.name, from: 'Teacher'
      fill_in 'Start time', with: '8:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find('#course_class_days', visible: false).set "2015-09-06,2015-09-07,2015-09-08"
      select previous_course.description, from: 'Import code reviews from previous course'
      click_on 'Create Course'
      expect(page).to have_content 'Course has been created'
      expect(page).to have_content code_review.title
    end
  end
end

feature 'viewing courses' do
  let(:student) { FactoryGirl.create(:student) }

  scenario 'as a student logged in' do
    login_as(student, scope: :student)
    visit student_courses_path(student)
    expect(page).to have_content 'Your courses'
  end

  scenario 'as a guest' do
    visit student_courses_path(student)
    expect(page).to have_content 'You need to sign in.'
  end
end

feature 'editing a course' do
  let(:course) { FactoryGirl.create(:internship_course) }

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

    scenario 'navigation to course#edit page' do
      visit root_path
      click_on 'Edit'
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
      find('#course_class_days', visible: false).set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Update Course'
      expect(page).to have_content "PHP/Drupal - Summer 2015 has been updated"
      expect(page).to have_content 'Code reviews'
    end

    scenario 'from the internships index page' do
      visit internships_path
      click_on 'Mark as inactive'
      expect(page).to have_content "#{course.description} has been updated"
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

feature 'visiting the previous courses page' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }

  scenario 'as an admin' do
    login_as(admin, scope: :admin)
    visit root_path
    click_on admin.current_course.description
    click_on 'Previous courses'
    expect(page).to have_content 'Previous courses'
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit courses_path
    expect(page).to have_content 'You are not authorized'
  end
end
