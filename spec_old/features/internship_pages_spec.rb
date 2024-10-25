feature 'viewing the internships index page' do
  context 'as a student' do
    let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
    let!(:internship) { FactoryBot.create(:internship, courses: [student.course]) }
    before { login_as(student, scope: :student) }

    scenario 'students cannot view the page' do
      visit internships_path
      expect(page).to have_content 'You are not authorized to access this page'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
    let!(:internship) { FactoryBot.create(:internship) }
    before { login_as(admin, scope: :admin) }

    scenario 'admins can see all the internships' do
      visit internships_path
      expect(page).to have_content 'Internships'
    end
  end
end

feature 'updating an internship' do
  let(:admin) { FactoryBot.create(:admin) }
  let!(:internship) { FactoryBot.create(:internship) }
  let(:company) { FactoryBot.create(:company, internships: [internship]) }
  let(:new_information) { FactoryBot.build(:internship, mentor_name: 'Michelle Obama') }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    scenario 'admin can navigate to the edit page' do
      visit internships_path(active: true)
      within("#internship-#{internship.id}") do
        click_link 'Edit'
      end
      expect(page).to have_content 'Describe your company and internship. Get students excited about what you do!'
    end

    scenario 'an internship edit page shows all current and future internship courses regardless of active' do
      course = internship.courses.first
      other_internship_course = FactoryBot.create(:internship_course, description: 'other internship course', internships: [internship], active: false)
      visit edit_internship_path(internship)
      expect(page).to have_content course.description
      expect(page).to have_content other_internship_course.description
    end

    scenario 'an internship edit page shows all current and future internship courses regardless of full' do
      course = internship.courses.first
      other_internship_course = FactoryBot.create(:internship_course, description: 'other internship course', internships: [internship], full: true)
      visit edit_internship_path(internship)
      expect(page).to have_content course.description
      expect(page).to have_content other_internship_course.description
    end

    scenario 'an internship can be updated with valid input' do
      visit edit_internship_path(internship)
      fill_in 'Describe your company and internship. Get students excited about what you do!', with: new_information.description
      fill_in 'Mentor name', with: new_information.mentor_name
      click_on 'Update internship'
      expect(page).to have_content 'Internship has been updated'
      expect(internship.reload.mentor_name).to eq 'Michelle Obama'
    end

    scenario 'an internship cannot be updated with invalid input' do
      visit edit_internship_path(internship)
      fill_in 'Describe your company and internship. Get students excited about what you do!', with: ''
      click_on 'Update internship'
      expect(page).to have_content 'Please correct these problems:'
    end
  end

  context 'as a company' do
    before { login_as(company, scope: :company) }

    scenario 'successfully' do
      visit internships_path
      click_on 'Edit'
      fill_in 'Describe your company and internship. Get students excited about what you do!', with: new_information.description
      click_on 'Update internship'
      expect(page).to have_content 'Internship has been updated'
    end

    scenario 'an internship edit page shows only current and future active internship courses with space' do
      course = internship.courses.first
      other_internship_course = FactoryBot.create(:internship_course, description: 'other internship course', internships: [internship], active: false)
      visit edit_internship_path(internship)
      expect(page).to have_content course.description
      expect(page).to_not have_content other_internship_course.description
    end

    scenario 'an internship edit page shows only current and future active internship courses with space' do
      course = internship.courses.first
      other_internship_course = FactoryBot.create(:internship_course, description: 'other internship course', internships: [internship], full: true)
      visit edit_internship_path(internship)
      expect(page).to have_content course.description
      expect(page).to_not have_content other_internship_course.description
    end
  end
end

feature 'removing an internship from a particular session' do
  let(:admin) { FactoryBot.create(:admin) }
  let!(:internship) { FactoryBot.create(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'it deletes the record' do
    visit internships_path(active: true)
    click_link 'Withdraw'
    expect(page).to_not have_content 'Withdraw'
  end
end

feature 'visiting the internships show page' do
  context 'as a student' do
    let(:internship_course) { FactoryBot.create(:internship_course) }
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [internship_course]) }
    let(:internship) { FactoryBot.create(:internship, courses: [internship_course]) }
    before { login_as(student, scope: :student) }

    scenario 'students can view internship contact and details sections' do
      visit course_internship_path(student.course, internship)
      expect(page).to have_content 'Contact'
      expect(page).to have_content internship.company.name
      expect(page).to have_content 'Details'
      expect(page).to have_content internship.description
    end

    scenario 'students can not see edit internship link' do
      visit course_internship_path(student.course, internship)
      expect(page).to_not have_content 'Edit'
    end

    scenario 'students can not see rankings' do
      visit course_internship_path(student.course, internship)
      expect(page).to_not have_content 'Rankings'
    end

    scenario 'students can not see list of internship periods' do
      visit course_internship_path(student.course, internship)
      expect(page).to_not have_content 'Internship periods'
    end

    scenario 'students can not see admin/company only fields' do
      visit course_internship_path(student.course, internship)
      expect(page).to_not have_content 'maybe'
      expect(page).to_not have_content 'Ada Lovelace'
      expect(page).to_not have_content 'two and a half years'
      expect(page).to_not have_content 'Mon-Fri 9-5'
      expect(page).to_not have_content 'really fun projects'
      expect(page).to_not have_content 'no contract'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, :with_course) }

    before { login_as(admin, scope: :admin) }

    scenario 'you can navigate to the show page from the index' do
      internship = FactoryBot.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.description
    end

    scenario 'clearance description is hidden if there is no clearance requirement' do
      internship = FactoryBot.create(:internship, clearance_required: false)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to_not have_content 'Clearance description'
    end

    scenario 'clearance description is visible if there is a clearance requirement' do
      internship = FactoryBot.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content 'Clearance description'
    end

    scenario 'interview location is shown if field has been entered' do
      internship = FactoryBot.create(:internship, interview_location: "test location")
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.interview_location
    end

    scenario 'company location is shown if interview location field has not been entered' do
      internship = FactoryBot.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.address
    end

    scenario 'admin can see list of internship periods' do
      internship = FactoryBot.create(:internship)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content 'Internship periods'
      expect(page).to have_content internship.courses.first.description
    end

    scenario 'admin can see company/admin only fields' do
      internship = FactoryBot.create(:internship)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content 'maybe'
      expect(page).to have_content 'Ada Lovelace'
      expect(page).to have_content 'two and a half years'
      expect(page).to have_content 'Mon-Fri 9-5'
      expect(page).to have_content 'really fun projects'
      expect(page).to have_content 'no contract'
    end
  end
end

feature 'viewing internships before rankings are live' do
  let(:internship_course) { FactoryBot.create(:internship_course) }
  let(:student) { FactoryBot.create(:student, course: internship_course) }

  scenario 'a student can rate an internship from the internships index page' do
    internship = FactoryBot.create(:internship, courses: [student.course])
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
    expect(page).to_not have_content 'Save rankings'
  end
end

feature 'rating an internship' do
  let(:internship_course) { FactoryBot.create(:internship_course, rankings_visible: true) }
  let(:student) { FactoryBot.create(:student, course: internship_course) }

  scenario 'a student can rate an internship from the internships index page', :js do
    FactoryBot.create(:internship, courses: [student.course])
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    click_on "Save rankings", :match => :first
    expect(page).to have_content 'Internship rankings have been updated'
  end
end

feature 'admin viewing students interested in an internship' do
  let(:course) { FactoryBot.create(:internship_course) }
  let(:admin) { FactoryBot.create(:admin, current_course: course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:internship) { FactoryBot.create(:internship, courses: [student.course]) }
  before { login_as(admin, scope: :admin) }

  context 'on an internship page' do
    scenario 'an admin can see students highly interested in that internship' do
      FactoryBot.create(:rating, number: '1', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content student.name
    end

    scenario "an admin can click on a student's name to view their internships page" do
      FactoryBot.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_link student.name
      expect(page).to have_content 'Internships'
    end

    scenario "an admin can view student feedback post-interview" do
      FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_student: 1, feedback_from_student: 'Great interview!')
      login_as(admin, scope: :admin)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content "Great interview!"
    end

    scenario "an admin can view company feedback post-interview" do
      FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_company: 1, feedback_from_company: 'Great student!')
      login_as(admin, scope: :admin)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content "Great student!"
    end
  end
end

feature "admin viewing a student's internship page" do
  let(:course) { FactoryBot.create(:internship_course) }
  let(:admin) { FactoryBot.create(:admin, current_course: course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let!(:internship) { FactoryBot.create(:internship, courses: [student.course]) }
  before { login_as(admin, scope: :admin) }

  scenario "an admin can see internships from that student's course" do
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
  end

  scenario "an admin can navigate through to an internship's show page" do
    visit course_student_path(student.course, student)
    click_link(internship.name)
    expect(page).to have_content internship.description
  end
end

feature "viewing a student's internship page after internship assignment" do
  let(:course) { FactoryBot.create(:internship_course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:admin) { FactoryBot.create(:admin, current_course: course) }
  let(:internship) { FactoryBot.create(:internship, courses: [student.course]) }
  let!(:interview_assignment) { FactoryBot.create(:interview_assignment, student: student, internship: internship, course: internship.courses.first, ranking_from_student: 1, feedback_from_student: 'Great interview!') }
  let!(:internship_assignment) { FactoryBot.create(:internship_assignment, student: student, internship: internship, course: course) }

  scenario "an admin can see internship assignment" do
    login_as(admin, scope: :admin)
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
    expect(page).to have_content 'Contact name'
  end

  scenario "students can not see internship assignment before course.internship_assignments_visible is set" do
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to_not have_content 'Contact name'
  end

  scenario "students can see internship assignment after course.internship_assignments_visible is set" do
    course.internship_assignments_visible = true
    course.save
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
    expect(page).to have_content 'Contact name'
  end

  scenario "admin can enable internship assignment student visibility" do
    login_as(admin, scope: :admin)
    visit course_path(student.course)
    click_on 'Make internship assignments public'
    logout(admin)
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
    expect(page).to have_content 'Contact name'
  end

  scenario "admin can disable internship assignment student visibility" do
    course.internship_assignments_visible = true
    course.save
    login_as(admin, scope: :admin)
    visit course_path(student.course)
    click_on 'Hide internship assignments'
    logout(admin)
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to_not have_content 'Contact name'
  end
end
