feature 'viewing the internships index page' do
  context 'as a student' do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
    let!(:internship) { FactoryGirl.create(:internship, courses: [student.course]) }
    before { login_as(student, scope: :student) }

    scenario 'students cannot view the page' do
      visit internships_path
      expect(page).to have_content 'You are not authorized to access this page'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:internship) { FactoryGirl.create(:internship) }
    before { login_as(admin, scope: :admin) }

    scenario 'admins can see all the internships' do
      visit internships_path
      expect(page).to have_content 'Internships'
    end
  end
end

feature 'updating an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:internship) { FactoryGirl.create(:internship) }
  let(:company) { FactoryGirl.create(:company, internships: [internship]) }
  let(:new_information) { FactoryGirl.build(:internship) }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    scenario 'admin can navigate to the edit page' do
      visit internships_path(active: true)
      within("#internship-#{internship.id}") do
        click_link 'Edit'
      end
      expect(page).to have_content 'Describe your company and internship. Get students excited about what you do!'
    end

    scenario 'an internship can be updated with valid input' do
      visit edit_internship_path(internship)
      fill_in 'Describe your company and internship. Get students excited about what you do!', with: new_information.description
      click_on 'Update internship'
      expect(page).to have_content 'Internship has been updated'
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
  end
end

feature 'removing an internship from a particular session' do
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:internship) { FactoryGirl.create(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'it deletes the record' do
    visit internships_path(active: true)
    click_link 'Withdraw'
    expect(page).to_not have_content 'Withdraw'
  end
end

feature 'visiting the internships show page' do
  context 'as a student' do
    let(:internship_course) { FactoryGirl.create(:internship_course) }
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed, courses: [internship_course]) }
    let(:internship) { FactoryGirl.create(:internship, courses: [internship_course]) }
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
  end

  context 'as an admin' do
    let(:admin) { FactoryGirl.create(:admin) }

    before { login_as(admin, scope: :admin) }

    scenario 'you can navigate to the show page from the index' do
      internship = FactoryGirl.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.description
    end

    scenario 'clearance description is hidden if there is no clearance requirement' do
      internship = FactoryGirl.create(:internship, clearance_required: false)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to_not have_content 'Clearance description'
    end

    scenario 'clearance description is visible if there is a clearance requirement' do
      internship = FactoryGirl.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content 'Clearance description'
    end

    scenario 'interview location is shown if field has been entered' do
      internship = FactoryGirl.create(:internship, interview_location: "test location")
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.interview_location
    end

    scenario 'company location is shown if interview location field has not been entered' do
      internship = FactoryGirl.create(:internship)
      visit internships_path(active: true)
      click_link internship.name
      expect(page).to have_content internship.address
    end
  end
end

feature 'viewing internships before rankings are live' do
  let(:internship_course) { FactoryGirl.create(:internship_course) }
  let(:student) { FactoryGirl.create(:student, course: internship_course) }

  scenario 'a student can rate an internship from the internships index page' do
    internship = FactoryGirl.create(:internship, courses: [student.course])
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
    expect(page).to_not have_content 'Save rankings'
  end
end

feature 'rating an internship' do
  let(:internship_course) { FactoryGirl.create(:internship_course, rankings_visible: true) }
  let(:student) { FactoryGirl.create(:student, course: internship_course) }

  scenario 'a student can rate an internship from the internships index page', :js do
    FactoryGirl.create(:internship, courses: [student.course])
    login_as(student, scope: :student)
    visit course_student_path(student.course, student)
    click_on "Save rankings", :match => :first
    expect(page).to have_content 'Internship rankings have been updated'
  end
end

feature 'admin viewing students interested in an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let(:internship) { FactoryGirl.create(:internship, courses: [student.course]) }
  before { login_as(admin, scope: :admin) }

  context 'on an internship page' do
    scenario 'an admin can see students highly interested in that internship' do
      FactoryGirl.create(:rating, number: '1', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      expect(page).to have_content student.name
    end

    scenario "an admin can click on a student's name to view their internships page" do
      FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_link student.name
      expect(page).to have_content 'Internships'
    end
  end
end

feature "admin viewing a student's internship page" do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:course) { FactoryGirl.create(:internship_course) }
  let(:student) { FactoryGirl.create(:student, course: course) }
  let!(:internship) { FactoryGirl.create(:internship, courses: [student.course]) }
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
