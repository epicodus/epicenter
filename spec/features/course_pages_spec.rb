feature 'viewing courses' do
  let(:student) { FactoryBot.create(:student, :with_course) }

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

feature 'viewing cohort on course list page' do
  scenario 'as a student' do
    student = FactoryBot.create(:student, :with_pt_intro_cohort)
    login_as(student, scope: :student)
    visit student_courses_path(student)
    expect(page).to have_content "Cohort: #{student.parttime_cohort.description}"
  end

  scenario 'as an admin' do
    student = FactoryBot.create(:student, :with_pt_intro_cohort)
    admin = FactoryBot.create(:admin)
    login_as(admin, scope: :admin)
    visit student_courses_path(student)
    expect(page).to have_content "Cohort: #{student.parttime_cohort.description}"
  end
end

feature 'editing a course' do
  let(:course) { FactoryBot.create(:internship_course, track: FactoryBot.create(:part_time_track)) }

  scenario 'not logged in' do
    visit edit_course_path(course)
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit edit_course_path(course)
    expect(page).to have_content 'not authorized'
  end

  context 'as an admin' do
    let(:admin) { course.admin }
    before { login_as(admin, scope: :admin) }

    scenario 'navigation to course#edit page' do
    visit course_path(course)
    click_on 'Edit'
    expect(page).to have_content "Edit #{course.description}"
    end

    scenario 'with valid input' do
      visit edit_course_path(course)
      select admin.current_course.language.name, from: 'Language'
      select admin.current_course.office.name, from: 'Office'
      find('#course_class_days', visible: false).set "2015-09-06,2015-09-07,2015-09-08"
      click_on 'Update Course'
      expect(page).to have_content "has been updated"
      expect(page).to have_content 'Career reviews'
    end

    scenario 'from the internships index page' do
      visit internships_path(active: true)
      click_on 'Mark as inactive'
      expect(page).to have_content "#{course.reload.description} has been updated"
    end

    scenario 'from the internships index page' do
      visit internships_path(active: true)
      click_on 'Mark as full'
      expect(page).to have_content "#{course.reload.description} has been updated"
    end
  end
end

feature 'visiting the course index page' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }

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
  let!(:admin) { FactoryBot.create(:admin, :with_course) }

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
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed)
      login_as(student, scope: :student)
      visit root_path
      click_on 'Courses'
      expect(page).to_not have_css ".alert"
    end
  end
  
  context "when on teacher probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, probation_teacher: true)
      login_as(student, scope: :student)
      visit root_path
      click_on 'Courses'
      section = find(:css, '.alert')
      expect(section).to have_content "Academic Warning"
    end
  end

  context "when on advisor probation" do
    it "as a student viewing their own page" do
      student = FactoryBot.create(:student, :with_course, :with_all_documents_signed, probation_advisor: true)
      login_as(student, scope: :student)
      visit root_path
      click_on 'Courses'
      section = find(:css, '.alert')
      expect(section).to have_content "Academic Warning"
    end
  end
end
