feature 'creating a course' do

  scenario 'not logged in' do
    visit new_course_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryBot.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit new_course_path
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to course#new page', js: true do
      visit root_path
      click_on 'Courses'
      click_on 'New'
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
        select admin.current_course.language.name, from: 'Language'
        select admin.current_course.office.name, from: 'Office'
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
      previous_course = FactoryBot.create(:portland_ruby_course)
      code_review = FactoryBot.create(:code_review, course: previous_course)
      visit new_course_path
      select admin.current_course.language.name, from: 'Language'
      select admin.current_course.office.name, from: 'Office'
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
  let(:student) { FactoryBot.create(:student) }

  scenario 'as a student logged in' do
    login_as(student, scope: :student)
    visit student_courses_path(student)
    expect(page).to have_content 'Your courses'
    expect(page).to have_content student.course.description
  end

  scenario 'as a student logged in, with a withdrawn course' do
    future_course = FactoryBot.create(:future_course)
    Enrollment.create(student: student, course: future_course)
    Enrollment.find_by(student: student, course: future_course).destroy
    login_as(student, scope: :student)
    visit student_courses_path(student)
    expect(page).to_not have_content 'Withdrawn:'
  end

  scenario 'as a guest' do
    visit student_courses_path(student)
    expect(page).to have_content 'You need to sign in.'
  end
end

feature 'editing a course' do
  let(:course) { FactoryBot.create(:internship_course) }

  scenario 'not logged in' do
    visit edit_course_path(course)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryBot.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit edit_course_path(course)
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: course) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to course#edit page' do
      visit root_path
      click_on 'Edit'
      expect(page).to have_content "Edit #{course.description}"
    end

    scenario 'with invalid input' do
      visit edit_course_path(course)
      fill_in 'Start time', with: ''
      click_on 'Update Course'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with valid input' do
      visit edit_course_path(course)
      select admin.current_course.language.name, from: 'Language'
      select admin.current_course.office.name, from: 'Office'
      fill_in 'Start time', with: '8:00 AM'
      fill_in 'End time', with: '5:00 PM'
      find('#course_class_days', visible: false).set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Update Course'
      expect(page).to have_content "has been updated"
      expect(page).to have_content 'Code reviews'
    end

    scenario 'from the internships index page' do
      visit internships_path(active: true)
      click_on 'Mark as inactive'
      expect(page).to have_content "#{course.description} has been updated"
    end

    scenario 'from the internships index page' do
      visit internships_path(active: true)
      click_on 'Mark as full'
      expect(page).to have_content "#{course.description} has been updated"
    end
  end
end

feature 'visiting the course index page' do
  let(:admin) { FactoryBot.create(:admin) }
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }

  scenario 'as an admin' do
    login_as(admin, scope: :admin)
    visit root_path
    click_on 'Courses'
    expect(page).to have_content 'Courses'
  end

  scenario 'as a student' do
    login_as(student, scope: :student)
    visit courses_path
    expect(page).to have_content 'You are not authorized'
  end
end

feature 'selecting a new course manually' do
  let!(:admin) { FactoryBot.create(:admin) }

  scenario 'as an admin' do
    course2 = FactoryBot.create(:internship_course)
    login_as(admin, scope: :admin)
    visit root_path
    click_on 'Courses'
    click_on course2.description
    click_on 'Select'
    expect(page).to have_content "You have switched to #{course2.description}"
  end
end

feature "shows warning if on probation" do
  context "when not on probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:user_with_all_documents_signed)
      login_as(student, scope: :student)
      visit root_path
      click_on 'Courses'
      expect(page).to_not have_content "Academic probation"
    end
  end

  context "when on probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:user_with_all_documents_signed, probation: true)
      login_as(student, scope: :student)
      visit root_path
      click_on 'Courses'
      expect(page).to have_content "Academic probation"
    end
  end
end
