feature 'index page' do

  context "not an admin" do
    scenario 'not logged in' do
      visit companies_path
      expect(page).to have_content 'need to sign in'
    end

    scenario 'logged in as student' do
      student = FactoryGirl.create(:user_with_all_documents_signed)
      login_as(student, scope: :student)
      visit companies_path
      expect(page).to have_content 'You are not authorized to access this page'
    end
  end

  context "as an admin" do
    let(:course) { FactoryGirl.create(:course) }
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:company) { FactoryGirl.create(:company) }
    let!(:other_company) { FactoryGirl.create(:company) }
    before { login_as(admin, scope: :admin) }

    xscenario "all companies should be listed" do # passes when run individually, but not with whole test suite
      visit companies_path
      expect(page).to have_content "1 labs"
      expect(page).to have_content other_company.name
    end

    scenario "Companies are linked to their show page" do
      visit companies_path
      click_link company.name
      expect(page).to have_content company.description
    end

    scenario "it should have an add new company button" do
      visit companies_path
      expect(page).to have_content "+ New company"
    end
  end
end

feature "creating a new company" do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin) }
  before { login_as(admin, scope: :admin) }


  context "with valid input" do
    scenario "it adds a new company" do
      visit companies_path
      click_link "+ New company"
      fill_in "Company Name", with: "New company"
      fill_in "Website", with: "www.newcompany.com"
      click_on "Create Company"
      expect(page).to have_content "New company"
    end
  end

  context "with invalid input" do
    scenario "it adds a new company" do
      visit companies_path
      click_link "+ New company"
      fill_in "Company Name", with: ""
      fill_in "Website", with: "www.newcompany.com"
      click_on "Create Company"
      expect(page).to have_content "Company Name"
    end
  end
end

feature "editing a company" do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:company) { FactoryGirl.create(:company) }
  before { login_as(admin, scope: :admin) }

  context "with valid input" do
    scenario "updates a company successfully" do
      visit companies_path
      click_link "Edit"
      fill_in "Company Name", with: "New company Name"
      click_on "Update Company"
      expect(page).to have_content "New company Name"
    end
  end

  context "with invalid input" do
    scenario "doesn't update the company" do
      visit companies_path
      click_link "Edit"
      fill_in "Company Name", with: ""
      click_on "Update Company"
      expect(page).to have_content "Please correct these problems:"
    end
  end
end

feature "deleting a company" do
  let(:course) { FactoryGirl.create(:course) }
  let(:admin) { FactoryGirl.create(:admin) }
  let!(:company) { FactoryGirl.create(:company) }
  before { login_as(admin, scope: :admin) }

  context "as an admin" do
    scenario "it removes company from database" do
      visit companies_path
      click_link "Delete"
      expect(page).to have_content "Companies"
      expect(page).to_not have_content company.name
    end
  end
end
