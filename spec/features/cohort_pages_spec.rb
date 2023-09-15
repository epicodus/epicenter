feature 'visiting the cohort index page' do
  scenario 'not logged in' do
    visit cohorts_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit cohorts_path
    expect(page).to have_content 'not authorized'
  end

  scenario 'as an admin' do
    admin = FactoryBot.create(:admin, :with_course)
    admin.current_course.cohort.update(end_date: admin.current_course.end_date)
    login_as(admin, scope: :admin)
    visit cohorts_path
    expect(page).to have_content 'Cohorts'
  end
end

feature 'viewing cohort' do
  let(:cohort) { FactoryBot.create(:pt_intro_cohort) }
  let(:admin) { cohort.admin }

  scenario 'not logged in' do
    visit cohort_path(cohort)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit cohort_path(cohort)
    expect(page).to have_content 'not authorized'
  end

  scenario 'as an admin' do
    login_as(admin, scope: :admin)
    visit cohort_path(cohort)
    expect(page).to have_content 'Courses'
    expect(page).to have_content cohort.courses.first.description
  end

  scenario 'as an admin linking from course cohort link' do
    login_as(admin, scope: :admin)
    visit course_path(cohort.courses.first)
    click_link cohort.description
    expect(page).to have_content 'Courses'
    expect(page).to have_content cohort.courses.first.description
  end
end

feature 'creating a cohort' do
  scenario 'not logged in' do
    visit new_cohort_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as as a student' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit new_cohort_path
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }
    let!(:office) { FactoryBot.create(:portland_office) }
    let!(:track) { admin.current_course.track }

    before { login_as(admin, scope: :admin) }

    scenario 'navigation to cohort#new page' do
      visit root_path
      click_on 'Cohorts'
      click_on 'New'
      expect(page).to have_content 'New cohort'
    end

    scenario 'with invalid input' do
      visit new_cohort_path
      click_on 'Create Cohort'
      expect(page).to have_content "can't be blank"
    end

    scenario 'from layout file' do
      allow(Github).to receive(:get_layout_params).with('example_cohort_layout_path').and_return({ 'track' => 'Part-Time Intro to Programming', 'course_layout_files' => ['example_course_layout_path'] })
      allow(Github).to receive(:get_layout_params).with('example_course_layout_path').and_return({ 'part_time' => true, 'number_of_weeks' => 6, 'class_times' => { 'Sunday' => '9:00-17:00', 'Monday' => '18:00-21:00', 'Tuesday' => '18:00-21:00', 'Wednesday' => '18:00-21:00' }, 'code_reviews' => [] })
      visit new_cohort_path
      select office.name, from: 'Office'
      select track.description, from: 'Track'
      select admin.name, from: 'Teacher'
      fill_in 'Start Date', with: Date.today
      fill_in 'Layout file path', with: 'example_cohort_layout_path'
      click_on 'Create Cohort'
      expect(page).to have_content 'Cohort has been created'
      expect(page).to have_content 'Courses'
    end
  end
end

feature 'editing a cohort' do
  let!(:cohort) { FactoryBot.create(:pt_intro_cohort) }

  scenario 'not logged in' do
    visit edit_cohort_path(cohort)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit edit_cohort_path(cohort)
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, courses: cohort.courses) }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to cohort#edit page' do
      admin.current_course.cohort.update(end_date: admin.current_course.end_date)
      visit cohorts_path
      click_on 'Edit'
      expect(page).to have_content "Edit #{cohort.description}"
    end

    scenario 'with invalid input' do
      visit edit_cohort_path(cohort)
      fill_in 'Start Date', with: ''
      click_on 'Update Cohort'
      expect(page).to have_content "can't be blank"
    end

    scenario 'with valid input' do
      visit edit_cohort_path(cohort)
      select cohort.track.description, from: 'Track'
      click_on 'Update Cohort'
      expect(page).to have_content "has been updated"
      expect(page).to have_content 'Courses'
    end
  end
end
