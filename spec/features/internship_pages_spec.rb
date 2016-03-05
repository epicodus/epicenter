feature 'index page' do

  context "as a student" do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
    let!(:internship) { FactoryGirl.create(:internship, course_id: student.course.id) }
    before { login_as(student, scope: :student) }

    scenario 'students can see internships listed by comapany name' do
      visit root_path
      click_link 'Internships'
      expect(page).to have_content internship.name
    end

    scenario 'students cannot see the edit or delete links' do
      visit course_internships_path(student.course)
      expect(page).to_not have_content 'Edit'
    end

    scenario 'students cannot see the new internship link' do
      visit course_internships_path(student.course)
      expect(page).to_not have_content '+ New Internship'
    end
  end

  context "as an admin" do
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:internship) { FactoryGirl.create(:internship, course_id: admin.current_course_id) }
    before { login_as(admin, scope: :admin) }

    scenario 'admins can see internships listed by company name' do
      visit course_internships_path(admin.current_course)
      expect(page).to have_content internship.name
    end
  end
end

feature 'creating a new internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.build(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'an admin can navigate to the new internship form' do
    visit course_internships_path(internship.course)
    click_link '+ New internship'
    expect(page).to have_content 'Internship description'
  end

  scenario 'a new internship will be created with valid input' do
    visit new_course_internship_path(internship.course)
    fill_in 'Name', with: internship.name
    fill_in 'Internship description', with: internship.description
    fill_in 'Website', with: internship.website
    fill_in 'Address', with: internship.address
    fill_in 'Ideal intern', with: internship.ideal_intern
    fill_in 'Clearance description', with: internship.clearance_description
    check 'internship_clearance_required'
    select internship.company.name, from: "internship_company_id"
    click_on 'Create Internship'
    expect(page).to have_content internship.name
  end

  scenario 'a new internship will not be created with invalid input' do
    visit new_course_internship_path(internship.course)
    fill_in 'Name', with: internship.name
    fill_in 'Internship description', with: ''
    fill_in 'Website', with: internship.website
    fill_in 'Address', with: internship.address
    fill_in 'Ideal intern', with: internship.ideal_intern
    fill_in 'Clearance description', with: internship.clearance_description
    check 'internship_clearance_required'
    select internship.company.name, from: "internship_company_id"
    click_on 'Create Internship'
    expect(page).to have_content 'Please correct these problems:'
  end
end

feature 'updating an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.create(:internship) }
  let(:new_information) { FactoryGirl.build(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'admin can navigate to the edit page' do
    visit course_internships_path(internship.course)
    click_link 'Edit'
    expect(page).to have_content 'Internship description'
  end

  scenario 'an internship can be update with valid input' do
    visit edit_course_internship_path(internship.course, internship)
    fill_in 'Internship description', with: new_information.description
    click_on 'Update Internship'
    expect(page).to have_content 'Internship updated'
  end

  scenario 'an internship cannot be update with invalid input' do
    visit edit_course_internship_path(internship.course, internship)
    fill_in 'Internship description', with: ''
    click_on 'Update Internship'
    expect(page).to have_content 'Please correct these problems:'
  end
end

feature 'deleting an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.create(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'it deletes the record' do
    visit course_internships_path(internship.course)
    click_link 'Delete'
    expect(page).to_not have_content internship.name
  end
end

feature 'show page' do
  let(:admin) { FactoryGirl.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'you can navigate to the show page from the index' do
    internship = FactoryGirl.create(:internship)
    visit course_internships_path(internship.course)
    click_link internship.name
    expect(page).to have_content internship.description
  end

  scenario 'clearance description is hidden if there is no clearance requirement' do
    internship = FactoryGirl.create(:internship, clearance_required: false)
    visit course_internships_path(internship.course)
    click_link internship.name
    expect(page).to_not have_content 'Clearance description'
  end

  scenario 'clearance description is visible if there is a clearance requirement' do
    internship = FactoryGirl.create(:internship)
    visit course_internships_path(internship.course)
    click_link internship.name
    expect(page).to have_content 'Clearance description'
  end
end

feature 'rating an internship' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:low_rated_internship_1) { FactoryGirl.create(:internship, course: student.course) }
  let!(:low_rated_internship_2) { FactoryGirl.create(:internship, course: student.course) }
  let!(:low_rated_internship_3) { FactoryGirl.create(:internship, course: student.course) }
  let!(:low_rated_internship_4) { FactoryGirl.create(:internship, course: student.course) }
  let!(:low_rated_internship_5) { FactoryGirl.create(:internship, course: student.course) }
  let!(:unrated_internship) { FactoryGirl.create(:internship, course: student.course) }
  let!(:low_rating_1) { FactoryGirl.create(:low_rating, internship: low_rated_internship_1, student: student)}
  let!(:low_rating_2) { FactoryGirl.create(:low_rating, internship: low_rated_internship_2, student: student)}
  let!(:low_rating_3) { FactoryGirl.create(:low_rating, internship: low_rated_internship_3, student: student)}
  let!(:low_rating_4) { FactoryGirl.create(:low_rating, internship: low_rated_internship_4, student: student)}
  let!(:low_rating_5) { FactoryGirl.create(:low_rating, internship: low_rated_internship_5, student: student)}
  before { login_as(student, scope: :student) }

  scenario 'a student can rate an internship from the internship page' do
    visit course_internship_path(student.course, low_rated_internship_1)
    choose "High"
    fill_in 'Notes: minimum 10 characters', with: 'New note about the internship.'
    click_on "Submit rating"
    selected_radio_button = find('#student_ratings_attributes_0_interest_1')
    expect(selected_radio_button).to be_checked
  end

  scenario 'a student can update an internship with a new rating from the internship page' do
    visit course_internship_path(student.course, low_rated_internship_1)
    choose "High"
    fill_in 'Notes: minimum 10 characters', with: 'Old note.'
    click_on "Submit rating"
    choose "Low"
    fill_in 'Notes: minimum 10 characters', with: 'New note.'
    click_on "Submit rating"
    selected_radio_button = find('#student_ratings_attributes_0_interest_3')
    expect(selected_radio_button).to be_checked
  end

  scenario 'a student can rate an internship from the internships index page' do
    visit course_internships_path(student.course)
    within "#internship_#{low_rated_internship_1.id}" do
      choose "Medium"
      fill_in 'Notes: minimum 10 characters', with: 'Note about the first internship.'
    end
    within "#internship_#{low_rated_internship_2.id}" do
      choose "High"
      fill_in 'Notes: minimum 10 characters', with: 'Note about the second internship.'
    end
    click_on "Submit ratings"
    within "#internship_#{low_rated_internship_2.id}" do
      internship_2_selected_radio_button = find('#student_ratings_attributes_1_interest_1')
      expect(internship_2_selected_radio_button).to be_checked
    end
  end

  scenario 'a student cannot rate five internships as low' do
    visit course_internships_path(student.course)
    within "#internship_#{unrated_internship.id}" do
      fill_in 'Notes: minimum 10 characters', with: 'Note about the sixth internship.'
      choose "Low"
    end
    expect(page).to have_content 'You may only rank 5 companies as "Low" interest.'
  end
end

feature 'admin viewing students interested in an internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let(:internship) { FactoryGirl.create(:internship, course: student.course) }
  before { login_as(admin, scope: :admin) }

  context 'on an internship page' do
    scenario 'an admin can see students highly interested in that internship' do
      rating = FactoryGirl.create(:rating, interest: '1', student: student, internship: internship)
      visit course_internship_path(internship.course, internship)
      click_on 'Highly interested students'
      expect(page).to have_content student.name
    end

    scenario "an admin can't see students not-highly interested in that internship when on the 'high tab'" do
      rating = FactoryGirl.create(:rating, interest: '2', student: student, internship: internship)
      visit course_internship_path(internship.course, internship)
      click_on 'Highly interested students'
      expect(page).to_not have_content student.name
    end

    scenario 'an admin can see students moderately interested in that internship' do
      rating = FactoryGirl.create(:rating, interest: '2', student: student, internship: internship)
      visit course_internship_path(internship.course, internship)
      click_on 'Moderately interested students'
      expect(page).to have_content student.name
    end

    scenario 'an admin can see students not interested in that internship' do
      rating = FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.course, internship)
      click_on 'Not interested students'
      expect(page).to have_content student.name
    end

    scenario "an admin can click on a student's name to view their internships page" do
      rating = FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
      visit course_internship_path(internship.course, internship)
      click_on 'Not interested students'
      click_link student.name
      expect(page).to have_content 'Internships'
    end
  end
end

feature "admin viewing a student's internship page" do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:student) { FactoryGirl.create(:student) }
  let!(:internship) { FactoryGirl.create(:internship, course: student.course) }
  before { login_as(admin, scope: :admin) }

  scenario "an admin can navigate to a student's internship page from the student list" do
    visit root_path
    click_link student.name
    expect(page).to have_content internship.name
  end

  scenario "an admin can see internships from that student's course" do
    visit course_student_path(student.course, student)
    expect(page).to have_content internship.name
  end

  scenario "rated internships display their correct background color" do
    rating = FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
    visit course_student_path(student.course, student)
    expect(page).to have_css 'span.btn-primary'
  end

  scenario "an admin can navigate through to an internship's show page" do
    visit course_student_path(student.course, student)
    click_link  internship.name
    expect(page).to have_content internship.description
  end
end
