require 'rails_helper'

feature 'User signs up' do
  before do
    @plan = FactoryGirl.create :recurring_plan_with_upfront_payment
    visit new_user_registration_path
    fill_in 'Email', with: 'example_user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
  end

  scenario 'with valid information', js: true do
    fill_in 'Name', with: 'Ryan Larson'
    select @plan.name, from: 'user_plan_id'
    click_on 'Sign up'
    expect(page).to have_content 'How would you like to make payments'
  end

  scenario 'with missing information', js: true do
    click_on 'Sign up'
    expect(page).to have_content 'error'
  end
end

feature "User signs in" do
  context "before adding a payment method" do
    it "takes them to the page to choose payment method" do
      user = FactoryGirl.create(:user)
      sign_in user
      expect(page).to have_content "How would you like to make payments"
    end
  end

  context "after entering bank account info but before verifying" do
    it "takes them to the page to verify their account", :vcr do
      user = FactoryGirl.create(:user)
      bank_account = FactoryGirl.create(:bank_account, user: user)
      sign_in user
      expect(page).to have_content "Confirm your account"
    end
  end

  context "after verifying their bank account", :vcr do
    it "shows them their payment history" do
      user = FactoryGirl.create(:user_with_verified_bank_account)
      sign_in user
      expect(page).to have_content "Your payments"
    end
  end

  context "after adding a credit card", :vcr do
    it "shows them their payment history" do
      user = FactoryGirl.create(:user_with_credit_card)
      sign_in user
      expect(page).to have_content "Your payments"
    end
  end
end

feature 'Guest not signed in' do
  subject { page }

  context 'visits new subscrition path' do
    before { visit new_bank_account_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_verification_path }
    it { should have_content 'You need to sign in' }
  end

  context 'visits payments path' do
    let(:user) { FactoryGirl.create(:user) }
    before { visit payments_path }
    it { should have_content 'You need to sign in' }
  end
end
