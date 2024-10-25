feature '2fa enrollment' do
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }
  let(:company) { FactoryBot.create(:company) }
  let(:admin) { FactoryBot.create(:admin, :with_course) }
  let(:student_with_2fa) { FactoryBot.create(:student, :with_2fa, :with_all_documents_signed) }
  let(:company_with_2fa) { FactoryBot.create(:company, :with_2fa) }
  let(:admin_with_2fa) { FactoryBot.create(:admin, :with_course, :with_2fa) }

  scenario 'guest does not have access' do
    visit new_otp_path
    expect(page).to have_content 'You need to sign in'
  end

  scenario 'admin can enroll' do
    login_as(admin, scope: :admin)
    visit new_otp_path
    fill_in 'code_field', with: admin.current_otp
    fill_in 'password_field', with: admin.password
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Successfully enabled two factor authentication'
    expect(admin.reload.otp_required_for_login).to eq true
    expect(admin.reload.otp_secret).to_not eq nil
  end

  scenario 'admin can disable' do
    old_otp_secret = admin_with_2fa.otp_secret
    login_as(admin_with_2fa, scope: :admin)
    visit new_otp_path
    fill_in 'password_field', with: admin_with_2fa.password
    click_on 'Disable Two Factor'
    expect(page).to have_content 'Two Factor Authentication disabled'
    expect(admin_with_2fa.reload.otp_required_for_login).to eq false
    expect(admin_with_2fa.reload.otp_secret).to_not eq old_otp_secret
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

  scenario 'admin brought to 2fa page if not yet enrolled' do
    login_as(admin, scope: :admin)
    visit root_path
    expect(current_path).to eq new_otp_path
  end

  scenario 'admin not brought to 2fa page if already enrolled' do
    admin.update(otp_required_for_login: true)
    login_as(admin, scope: :admin)
    visit root_path
    expect(current_path).to_not eq new_otp_path
  end

  scenario 'student can enroll' do
    login_as(student, scope: :student)
    visit new_otp_path
    fill_in 'code_field', with: student.current_otp
    fill_in 'password_field', with: student.password
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Successfully enabled two factor authentication'
    expect(student.reload.otp_required_for_login).to eq true
    expect(student.reload.otp_secret).to_not eq nil
  end

  scenario 'student can cancel out from enrollment page' do
    login_as(student, scope: :student)
    visit new_otp_path
    click_on "Nevermind, I'll set this up later."
    expect(current_path).to_not eq new_otp_path
  end

  scenario 'student can disable' do
    old_otp_secret = student_with_2fa.otp_secret
    login_as(student_with_2fa, scope: :student)
    visit new_otp_path
    fill_in 'password_field', with: student_with_2fa.password
    click_on 'Disable Two Factor'
    expect(page).to have_content 'Two Factor Authentication disabled'
    expect(student_with_2fa.reload.otp_required_for_login).to eq false
    expect(student_with_2fa.reload.otp_secret).to_not eq old_otp_secret
  end

  scenario 'student can cancel out from enrollment page' do
    old_otp_secret = student_with_2fa.otp_secret
    login_as(student_with_2fa, scope: :student)
    visit new_otp_path
    click_on "Nevermind"
    expect(current_path).to_not eq new_otp_path
  end

  scenario 'student can enroll from profile edit' do
    login_as(student, scope: :student)
    visit edit_student_registration_path
    click_on 'Two-factor authentication settings'
    expect(page).to have_content 'Two Factor Authentication Enrollment'
  end

  scenario 'student can disable from profile edit' do
    login_as(student_with_2fa, scope: :student)
    visit edit_student_registration_path
    click_on 'Two-factor authentication settings'
    expect(page).to have_content 'Disable Two Factor Authentication'
  end

  scenario 'company can enroll' do
    login_as(company, scope: :company)
    visit new_otp_path
    fill_in 'code_field', with: company.current_otp
    fill_in 'password_field', with: company.password
    click_on 'Confirm and Enable Two Factor'
    expect(page).to have_content 'Successfully enabled two factor authentication'
    expect(company.reload.otp_required_for_login).to eq true
    expect(company.reload.otp_secret).to_not eq nil
  end

  scenario 'company can disable' do
    old_otp_secret = company_with_2fa.otp_secret
    login_as(company_with_2fa, scope: :company)
    visit new_otp_path
    fill_in 'password_field', with: company_with_2fa.password
    click_on 'Disable Two Factor'
    expect(page).to have_content 'Two Factor Authentication disabled'
    expect(company_with_2fa.reload.otp_required_for_login).to eq false
    expect(company_with_2fa.reload.otp_secret).to_not eq old_otp_secret
  end

  scenario 'company can enroll from profile edit' do
    login_as(company, scope: :company)
    visit edit_company_registration_path
    click_on 'Two-factor authentication settings'
    expect(page).to have_content 'Two Factor Authentication Enrollment'
  end

  scenario 'company can disable from profile edit' do
    login_as(company_with_2fa, scope: :company)
    visit edit_company_registration_path
    click_on 'Two-factor authentication settings'
    expect(page).to have_content 'Disable Two Factor Authentication'
  end
end
