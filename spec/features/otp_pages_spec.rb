feature 'Signing up for 2fa' do
  let(:student) { FactoryBot.create(:student) }
  let(:company) { FactoryBot.create(:company) }
  let(:admin) { FactoryBot.create(:admin, :with_course) }

  scenario 'guest does not have access' do
    visit new_otp_path
    expect(page).to have_content 'You need to sign in'
  end

  scenario 'student does not have access' do
    login_as(student, scope: :student)
    visit new_otp_path
    expect(page).to have_content 'You need to sign in'
  end

  scenario 'company does not have access' do
    login_as(company, scope: :company)
    visit new_otp_path
    expect(page).to have_content 'You need to sign in'
  end

  scenario 'admin warned if 2fa already enabled' do
    admin.update(otp_required_for_login: true)
    login_as(admin, scope: :admin)
    visit new_otp_path
    expect(page).to have_content 'already enabled'
  end
  
  scenario 'admin has access if 2fa not already enabled' do
    login_as(admin, scope: :admin)
    visit new_otp_path
    expect(page).to have_content 'Two Factor Authentication Setup'
  end

  scenario 'is possible with correct code and password' do
    login_as(admin, scope: :admin)
    visit new_otp_path
    fill_in 'code_field', with: admin.current_otp
    fill_in 'password_field', with: admin.password
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Successfully enabled two factor authentication'
  end

  scenario 'is not possible with incorrect password' do
    login_as(admin, scope: :admin)
    visit new_otp_path
    fill_in 'code_field', with: admin.current_otp
    fill_in 'password_field', with: 'wrong_password'
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Incorrect password or code'
  end

  scenario 'is not possible with incorrect code' do
    login_as(admin, scope: :admin)
    visit new_otp_path
    fill_in 'code_field', with: 'wrong_code'
    fill_in 'password_field', with: admin.password
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Incorrect password or code'
  end

  scenario 'admin brought to 2fa page if not yet signed in' do
    login_as(admin, scope: :admin)
    visit root_path
    expect(current_path).to eq new_otp_path
  end

  scenario 'admin brought to 2fa page if not yet signed in' do
    admin.update(otp_required_for_login: true)
    login_as(admin, scope: :admin)
    visit root_path
    expect(current_path).to_not eq new_otp_path
  end
end
