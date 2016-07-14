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
      visit internships_path
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
      click_on 'Edit internship details'
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
    visit internships_path
    click_link 'Withdraw'
    expect(page).to_not have_content 'Withdraw'
  end
end

feature 'visiting the internships show page' do
  let(:admin) { FactoryGirl.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'you can navigate to the show page from the index' do
    internship = FactoryGirl.create(:internship)
    visit internships_path
    click_link internship.name
    expect(page).to have_content internship.description
  end

  scenario 'clearance description is hidden if there is no clearance requirement' do
    internship = FactoryGirl.create(:internship, clearance_required: false)
    visit internships_path
    click_link internship.name
    expect(page).to_not have_content 'Clearance description'
  end

  scenario 'clearance description is visible if there is a clearance requirement' do
    internship = FactoryGirl.create(:internship)
    visit internships_path
    click_link internship.name
    expect(page).to have_content 'Clearance description'
  end
end

feature 'rating an internship' do
  let(:internship_course) { FactoryGirl.create(:internship_course) }
  let(:student) { FactoryGirl.create(:student, course: internship_course) }
  let!(:low_rated_internship_1) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:low_rated_internship_2) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:low_rated_internship_3) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:low_rated_internship_4) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:low_rated_internship_5) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:unrated_internship) { FactoryGirl.create(:internship, courses: [student.course]) }
  let!(:low_rating_1) { FactoryGirl.create(:low_rating, internship: low_rated_internship_1, student: student)}
  let!(:low_rating_2) { FactoryGirl.create(:low_rating, internship: low_rated_internship_2, student: student)}
  let!(:low_rating_3) { FactoryGirl.create(:low_rating, internship: low_rated_internship_3, student: student)}
  before { login_as(student, scope: :student) }

  scenario 'a student can rate an internship from the internships index page' do
    visit course_student_path(student.course, student)
    within "#internship_#{low_rated_internship_1.id}" do
      choose "Medium"
      fill_in 'Minimum 10 characters', with: 'Note about the first internship.'
    end
    within "#internship_#{low_rated_internship_2.id}" do
      choose "High"
      fill_in 'Minimum 10 characters', with: 'Note about the second internship.'
    end
    click_on "Submit ratings"
    within "#internship_#{low_rated_internship_2.id}" do
      internship_2_selected_radio_button = find('#student_ratings_attributes_1_interest_1')
      expect(internship_2_selected_radio_button).to be_checked
    end
  end

  scenario 'a student cannot rate five internships as low' do
    visit course_student_path(student.course, student)
    within "#internship_#{unrated_internship.id}" do
      fill_in 'Minimum 10 characters', with: 'Note about the sixth internship.'
      choose "Low"
    end
    expect(page).to have_content 'You may only rank 3 companies as "Low" interest.'
  end
end

feature 'admin viewing students interested in an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let(:internship) { FactoryGirl.create(:internship, courses: [student.course]) }
  before { login_as(admin, scope: :admin) }

  context 'on an internship page' do
    scenario 'an admin can see students highly interested in that internship' do
      FactoryGirl.create(:rating, interest: '1', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_on 'Highly interested students'
      expect(page).to have_content student.name
    end

    scenario "an admin can't see students not-highly interested in that internship when on the 'high tab'" do
      FactoryGirl.create(:rating, interest: '2', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_on 'Highly interested students'
      expect(page).to_not have_content student.name
    end

    scenario 'an admin can see students moderately interested in that internship' do
      FactoryGirl.create(:rating, interest: '2', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_on 'Moderately interested students'
      expect(page).to have_content student.name
    end

    scenario 'an admin can see students not interested in that internship' do
      FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_on 'Not interested students'
      expect(page).to have_content student.name
    end

    scenario "an admin can click on a student's name to view their internships page" do
      FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.courses.first, internship)
      click_on 'Not interested students'
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

  scenario "rated internships display their correct background color" do
    FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
    visit course_student_path(student.course, student)
    expect(page).to have_css 'span.label-primary'
  end

  scenario "an admin can navigate through to an internship's show page" do
    visit course_student_path(student.course, student)
    click_link(internship.name)
    expect(page).to have_content internship.description
  end
end
