require 'rails_helper'

feature 'User signs up' do
  before do
    plan = Plan.create(name: "summer 2014, recurring", upfront_amount: 20000, recurring_amount: 60000)
    visit new_user_registration_path
    fill_in 'Email', with: 'example_user@example.com'
    fill_in 'Password', with: 'password'
    fill_in 'Password confirmation', with: 'password'
  end

  scenario 'with valid information', js: true do
    fill_in 'Name', with: 'Ryan Larson'
    select 'summer 2014, recurring', from: 'user_plan_id'
    click_on 'Sign up'
    expect(page).to have_content 'bank account information'
  end

  scenario 'with missing information', js: true do
    click_on 'Sign up'
    expect(page).to have_content 'error'
  end
end

feature "User signs in" do
  context "before entering bank account info" do
    it "takes them to the page to enter their bank account info" do
      user = FactoryGirl.create(:user)
      sign_in user
      expect(page).to have_content "Bank account information"
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

  context "after verifying their account", :vcr do
    it "shows them their payment history" do
      user = FactoryGirl.create(:user_with_verified_bank_account)
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
