feature 'signing up as a company' do
  let!(:course) { FactoryBot.create(:internship_course) }
  let!(:track) { FactoryBot.create(:track) }

  scenario 'successfully' do
    visit new_company_registration_path
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    select track.description
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    find('#clearance-checkbox').set true
    fill_in 'Clearance description', with: 'Security clearance needed.'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    check 'internship-agreement-checkbox'
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
    select track.description
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    find('#clearance-checkbox').set true
    fill_in 'Clearance description', with: 'Security clearance needed.'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    check 'internship-agreement-checkbox'
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
    select track.description
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    find('#clearance-checkbox').set true
    fill_in 'Clearance description', with: 'Security clearance needed.'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    check 'internship-agreement-checkbox'
    click_on 'Sign up'
    fill_in 'Company name', with: 'Awesome company'
    fill_in '* Describe your company and internship. Get students excited about what you do!', with: 'You will write awesome software here!'
    fill_in 'Website', with: 'http://www.testcompany.com'
    fill_in 'Address', with: '123 N Main st. Portland, OR 97200'
    select course.description
    choose '2'
    select track.description
    fill_in '* Describe your ideal intern.', with: 'Somebody who writes awesome software!'
    find('#clearance-checkbox').set true
    fill_in 'Clearance description', with: 'Security clearance needed.'
    fill_in 'Name', with: 'Company employee 1'
    fill_in 'Email', with: 'employee1@company.com'
    fill_in '* Password', with: 'password'
    fill_in '* Password confirmation', with: 'password'
    check 'internship-agreement-checkbox'
    click_on 'Sign up'
    expect(page).to have_content 'Welcome! You have signed up successfully.'
  end
end

feature 'joining an internship course as a company' do
  let(:company) { FactoryBot.create(:company) }
  let!(:internship) { FactoryBot.create(:internship, company: company) }
  let!(:other_internship_course) { FactoryBot.create(:internship_course) }

  before do
    other_internship_course.update_columns(description: 'Other course')
    login_as(company, scope: :company)
  end

  scenario 'as a company on the company show page' do
    visit company_path(company)
    select other_internship_course.description
    click_on 'Join'
    expect(page).to have_content other_internship_course.description
  end
end

feature 'signing in as a company' do
  let(:internship) { FactoryBot.create(:internship) }
  let(:company) { FactoryBot.create(:company, internships: [internship]) }

  scenario 'successfully' do
    visit root_path
    fill_in 'Email', with: company.email
    fill_in 'Password', with: company.password
    click_on 'Sign in'
    expect(page).to have_content 'Signed in successfully.'
    expect(page).to have_content 'Internships'
  end
end
