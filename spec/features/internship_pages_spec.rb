feature 'index page' do

  context "as a student" do
    let(:student) { FactoryGirl.create(:student) }
    let!(:internship) { FactoryGirl.create(:internship, cohort_id: student.cohort.id) }
    before { login_as(student, scope: :student) }

    scenario 'students can see internships listed by comapany name' do
      visit root_path
      click_link 'Internships'
      expect(page).to have_content internship.company_name
    end

    scenario 'students cannot see the edit or delete links' do
      visit cohort_internships_path(student.cohort)
      expect(page).to_not have_content 'Edit'
    end

    scenario 'students cannot see the new internship link' do
      visit cohort_internships_path(student.cohort)
      expect(page).to_not have_content '+ New Internship'
    end
  end

  context "as an admin" do
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:internship) { FactoryGirl.create(:internship, cohort_id: admin.current_cohort_id) }
    before { login_as(admin, scope: :admin) }

    scenario 'admins can see internships listed by company name' do
      visit cohort_internships_path(admin.current_cohort)
      expect(page).to have_content internship.company_name
    end
  end
end

feature 'creating a new internship' do
  let(:admin) { FactoryGirl.create(:admin) }
  let(:internship) { FactoryGirl.build(:internship) }
  before { login_as(admin, scope: :admin) }

  scenario 'an admin can navigate to the new internship form' do
    visit cohort_internships_path(internship.cohort)
    click_link '+ New Internship'
    expect(page).to have_content 'Internship description'
  end

  scenario 'a new internship will be created with valid input' do
    visit new_cohort_internship_path(internship.cohort)
    fill_in 'Internship description', with: internship.description
    fill_in 'Ideal intern', with: internship.ideal_intern
    fill_in 'Clearance description', with: internship.clearance_description
    check 'internship_clearance_required'
    select internship.company.name, from: "internship_company_id"
    click_on 'Create Internship'
    expect(page).to have_content internship.company_name
  end

  scenario 'a new internship will not be created with invalid input' do
    visit new_cohort_internship_path(internship.cohort)
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
    visit cohort_internships_path(internship.cohort)
    click_link 'Edit'
    expect(page).to have_content 'Internship description'
  end

  scenario 'an internship can be update with valid input' do
    visit edit_cohort_internship_path(internship.cohort, internship)
    fill_in 'Internship description', with: new_information.description
    click_on 'Update Internship'
    expect(page).to have_content 'Internship updated'
  end

  scenario 'an internship cannot be update with invalid input' do
    visit edit_cohort_internship_path(internship.cohort, internship)
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
    visit cohort_internships_path(internship.cohort)
    click_link 'Delete'
    expect(page).to_not have_content internship.company_name
  end
end

feature 'show page' do
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'you can navigate to the show page from the index' do
    internship = FactoryGirl.create(:internship)
    visit cohort_internships_path(internship.cohort)
    click_link internship.company_name
    expect(page).to have_content internship.description
  end

  scenario 'clearance description is hidden if there is no clearance requirement' do
    internship = FactoryGirl.create(:internship, clearance_required: false)
    visit cohort_internships_path(internship.cohort)
    click_link internship.company_name
    expect(page).to_not have_content 'Clearance description'
  end

  scenario 'clearance description is visible if there is a clearance requirement' do
    internship = FactoryGirl.create(:internship)
    visit cohort_internships_path(internship.cohort)
    click_link internship.company_name
    expect(page).to have_content 'Clearance description'
  end
end
