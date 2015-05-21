feature 'Creating a bank account' do
  scenario 'as a guest' do
    visit new_bank_account_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as a student' do
    before do

      student = FactoryGirl.create(:student)
      login_as(student, scope: :student)
      visit new_bank_account_path
      fill_in 'Name on account', with: student.name
    end

    scenario 'with valid information', :vcr, js: true do
      fill_in 'Routing number', with: '110000000'
      fill_in 'Bank account number', with: '000123456789'
      fill_in 'Country', with: 'US'
      fill_in 'Currency', with: 'USD'
      click_on 'Verify bank account'
      expect(page).to have_content '2-3 business days'
    end

    scenario 'with missing account number', js: true do
      fill_in 'Routing number', with: '110000000'
      fill_in 'Bank account number', with: ' '
      fill_in 'Country', with: 'US'
      fill_in 'Currency', with: 'USD'
      click_on 'Verify bank account'
      within '.alert-error' do
        expect(page).to have_content 'Cannot be blank.'
      end
    end

    scenario 'with invalid routing number', js: true do
      fill_in 'Bank account number', with: '000123456789'
      fill_in 'Routing number', with: '12345689'
      fill_in 'Country', with: 'US'
      fill_in 'Currency', with: 'USD'
      click_on 'Verify bank account'
      within '.alert-error' do
        expect(page).to have_content 'Invalid routing number.'
      end
    end
  end
end

feature 'Verifying a bank account' do
  context 'as a student' do
    context 'with correct deposit amounts' do
      let(:student) { FactoryGirl.create :user_with_unverified_bank_account, plan: plan }
      let(:plan) { FactoryGirl.create :recurring_plan_with_upfront_payment }

      before do
        login_as(student, scope: :student)
        visit payment_methods_path
        click_on 'Verify Account'
        fill_in 'First deposit amount', with: 32
        fill_in 'Second deposit amount', with: 45
        click_on 'Confirm account'
      end

      it 'gives the student a confirmation notice and redirects to payments page', :vcr, js: true do
        expect(page).to have_content 'account has been confirmed'
        expect(current_path).to eq payment_methods_path
      end
    end

    context 'with incorrect deposit amounts' do
      it 'gives an error notice', :vcr, js: true do
        student = FactoryGirl.create :user_with_unverified_bank_account
        login_as(student, scope: :student)
        visit payment_methods_path
        click_on 'Verify Account'
        fill_in 'First deposit amount', with: 16
        fill_in 'Second deposit amount', with: 78
        click_on 'Confirm account'
        expect(page).to have_content 'The amounts provided do not match the amounts that were sent to the bank account.'
      end
    end
  end
end
