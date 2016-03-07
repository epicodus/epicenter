feature 'visiting the companies index page' do
  scenario 'as a guest' do
    visit companies_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student' do
    student = FactoryGirl.create(:user_with_all_documents_signed)
    login_as(student, scope: :student)
    visit companies_path
    expect(page).to have_content 'You are not authorized to access this page'
  end

  context "as an admin" do
    let(:course) { FactoryGirl.create(:course) }
    let(:admin) { FactoryGirl.create(:admin) }
    let!(:company) { FactoryGirl.create(:company) }
    let!(:other_company) { FactoryGirl.create(:company) }
    before { login_as(admin, scope: :admin) }

    scenario "all companies should be listed" do
      visit companies_path
      expect(page).to have_content company.name
      expect(page).to have_content other_company.name
    end

    scenario "Companies are linked to their show page" do
      visit companies_path
      click_link company.name
      expect(page).to have_content company.name
    end
  end
end

feature 'signing up as a company' do
  let!(:course) { FactoryGirl.create(:course) }

  scenario 'successfully' do
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in 'Description', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    fill_in 'Ideal intern', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'
  end

  scenario 'unsuccessfully with a duplicate email address' do
    FactoryGirl.create(:company, email: 'employee1@company.com')
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in 'Description', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    fill_in 'Ideal intern', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Email has already been taken'
  end

  scenario 'unsuccessfully with blank internship fields' do
    visit new_company_registration_path
    fill_in 'Company name', with: ''
    fill_in 'Description', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    fill_in 'Ideal intern', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'
  end
end
