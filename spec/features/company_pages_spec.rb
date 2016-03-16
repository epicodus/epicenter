feature 'signing up as a company' do
  let!(:course) { FactoryGirl.create(:internship_course) }

  scenario 'successfully' do
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'
  end

  scenario 'unsuccessfully with invalid internship fields' do
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: "8789u2ljrlkj;'l;'l;"
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'prohibited this company from being saved:'
  end

  scenario 'unsuccessfully with invalid internship fields first, then successfully' do
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: "8789u2ljrlkj;'l;'l;"
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    click_on 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'
  end
end
