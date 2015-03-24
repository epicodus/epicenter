feature 'index page' do

  context "not an admin" do
    scenario 'not logged in' do
      visit companies_path
      expect(page).to have_content 'need to sign in'
    end

    scenario 'logged in as student' do
      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit companies_path
      expect(page).to have_content 'You are not authorized to access this page'
    end
  end

  context "as an admin" do
    let(:cohort) { FactoryGirl.create(:cohort) }
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:company) { FactoryGirl.create(:company) }
    let!(:other_company) { FactoryGirl.create(:company) }
    before { login_as(admin, scope: :admin) }

    scenario "all companies should be listed" do
      visit companies_path
      expect(page).to have_content "1 labs"
      expect(page).to have_content other_company.name
    end

    scenario "Companies are linked to their show page" do
      visit companies_path
      click_link company.name
      expect(page).to have_content company.description
    end
  end

end

