 require 'rails_helper'

feature 'Viewing payment index page' do
  scenario 'as a guest' do
    visit payments_path
    expect(page).to have_content 'need to sign in'
  end
  
  context 'as a student' do
    context 'before any payments have been made', :vcr do
      it "doesn't show payment history" do
        student = FactoryGirl.create(:user_with_credit_card)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_content "Looks like you haven't made any payments yet."
      end
    end

    context 'after a payment has been made with bank account', :vcr do
      it 'shows payment history with correct charge' do
        payment = FactoryGirl.create(:payment, amount: 600_00)
        student = payment.student
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_content 600.00
        expect(page).to have_content "Bank account ending in 0002"
      end
    end

    context 'after a payment has been made with credit card', :vcr do
      it 'shows payment history with correct charge' do
        payment = FactoryGirl.create(:payment_with_credit_card, amount: 600_00)
        student = payment.student
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_content 618.21
        expect(page).to have_content "Credit card ending in 1111"
      end
    end

    context 'with upfront payment due using a bank account', :vcr do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_verified_bank_account, plan: plan)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_button('Make upfront payment of $200.00')
        expect(page).to_not have_button('Start recurring payments')
      end
    end

    context 'with upfront payment due using a credit card', :vcr do
      it 'only shows a link to make an upfront payment with correct amount' do
        plan = FactoryGirl.create(:recurring_plan_with_upfront_payment, upfront_amount: 200_00)
        student = FactoryGirl.create(:user_with_credit_card, plan: plan)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_button('Make upfront payment of $206.27')
        expect(page).to_not have_button('Start recurring payments')
      end
    end

    context 'with no upfront payment due', :vcr do
      it "doesn't show a link to make an upfront payment" do
        plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment, recurring_amount: 600_00)
        student = FactoryGirl.create(:user_with_credit_card, plan: plan)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to_not have_button('Make upfront payment')
        expect(page).to have_button('Start recurring payments of $618.21')
      end
    end

    context 'with recurring payments not active', :vcr do
      it 'shows a link to start recurring payments' do
        plan = FactoryGirl.create(:recurring_plan_with_no_upfront_payment, recurring_amount: 600_00)
        student = FactoryGirl.create(:user_with_verified_bank_account, plan: plan)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to have_button('Start recurring payments of $600.00')
        expect(page).to_not have_button('Make upfront payment')
      end
    end

    context 'with recurring payments active', :vcr do
      it "doesn't show a link to start recurring payments" do
        student = FactoryGirl.create(:user_with_recurring_active)
        login_as(student, scope: :student)
        visit payments_path
        expect(page).to_not have_button('Start recurring payments')
      end
    end
  end
end
