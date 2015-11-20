feature 'index page' do

  context "as a student" do
    let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
    let!(:internship) { FactoryGirl.create(:internship, course_id: student.course.id) }
    before { login_as(student, scope: :student) }

    scenario 'students can see internships listed by comapany name' do
      visit root_path
      click_link 'Internships'
      expect(page).to have_content internship.company_name
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
      expect(page).to have_content internship.company_name
    end
  end
end

feature 'creating a new internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.build(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'an admin can navigate to the new internship form' do
    visit course_internships_path(internship.course)
    click_link '+ New Internship'
    expect(page).to have_content 'Internship description'
  end

  scenario 'a new internship will be created with valid input' do
    visit new_course_internship_path(internship.course)
    fill_in 'Internship description', with: internship.description
    fill_in 'Ideal intern', with: internship.ideal_intern
    fill_in 'Clearance description', with: internship.clearance_description
    check 'internship_clearance_required'
    select internship.company.name, from: "internship_company_id"
    click_on 'Create Internship'
    expect(page).to have_content internship.company_name
  end

  scenario 'a new internship will not be created with invalid input' do
    visit new_course_internship_path(internship.course)
    fill_in 'Internship description', with: ''
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
    expect(page).to_not have_content internship.company_name
  end
end

feature 'show page' do
  let(:admin) { FactoryGirl.create(:admin) }

  before { login_as(admin, scope: :admin) }

  scenario 'you can navigate to the show page from the index' do
    internship = FactoryGirl.create(:internship)
    visit course_internships_path(internship.course)
    click_link internship.company_name
    expect(page).to have_content internship.description
  end

  scenario 'clearance description is hidden if there is no clearance requirement' do
    internship = FactoryGirl.create(:internship, clearance_required: false)
    visit course_internships_path(internship.course)
    click_link internship.company_name
    expect(page).to_not have_content 'Clearance description'
  end

  scenario 'clearance description is visible if there is a clearance requirement' do
    internship = FactoryGirl.create(:internship)
    visit course_internships_path(internship.course)
    click_link internship.company_name
    expect(page).to have_content 'Clearance description'
  end
end

feature 'rating an internship' do
  let(:student) { FactoryGirl.create(:student) }
  let!(:internship_one) { FactoryGirl.create(:internship, course: student.course) }
  before { login_as(student, scope: :student) }

  scenario 'a student can rate an internship from the internship page' do
    visit course_internship_path(student.course, internship_one)
    choose "rating_interest_1"
    fill_in 'rating_notes', with: 'New note about the internship.'
    click_on "Submit"
    expect(page).to have_css 'div.bg-success'
  end

  scenario 'a student can update an internship with a new rating from the internship page' do
    visit course_internship_path(student.course, internship_one)
    choose "rating_interest_1"
    choose "rating_interest_3"
    fill_in 'rating_notes', with: 'New note about the internship.'
    click_on "Submit"
    expect(page).to have_css 'div.bg-danger'
  end

  scenario 'a student can rate an internship from the internships index page' do
    visit course_internships_path(student.course)
    choose "rating_interest_2"
    fill_in 'rating_notes', with: 'New note about the internship.'
    click_on "Submit"
    expect(page).to have_css 'div.bg-warning'
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
      expect(page).to have_content 'Rated Internships'
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
    click_link "Student Roster"
    click_link student.name
    expect(page).to have_content internship.company_name
  end

  scenario "an admin can see internships from that student's course" do
    visit student_path(student)
    expect(page).to have_content internship.company_name
  end

  scenario "rated internships display their correct background color" do
    rating = FactoryGirl.create(:rating, interest: '3', student: student, internship: internship)
    visit student_path(student)
    expect(page).to have_css 'div.bg-danger'
  end

  scenario "an admin can navigate through to an internship's show page" do
    visit student_path(student)
    click_link  internship.company_name
    expect(page).to have_content internship.description
  end
end

feature 'viewing the January internships navbar link' do
  let(:non_interning_student) { FactoryGirl.create(:user_with_all_documents_signed) }
  let(:ruby_course) { FactoryGirl.create(:course, description: 'January 2016 Internships - Ruby')}
  let(:interning_student) { FactoryGirl.create(:user_with_all_documents_signed, course: ruby_course) }

  scenario 'a student interning in January can see the navbar link' do
    login_as(interning_student, scope: :student)
    visit root_path
    expect(page).to have_content 'January 2016 Internships'
  end

  scenario 'a student not interning in January cannot see the navbar link' do
    login_as(non_interning_student, scope: :student)
    visit root_path
    expect(page).to_not have_content 'January 2016 Internships'
  end
end
