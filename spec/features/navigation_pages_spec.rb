require 'rails_helper'

describe 'Home page' do
  subject { page }
  before(:each) { visit root_path }

  it { should have_link 'Start making payments' }
  it { should have_link 'Sign in'}
end

describe 'Start making payments link' do
  it "navigates to sign up page" do
    visit root_path
    click_on 'Start making payments'
    expect(page).to have_content 'Sign up'
  end
end

describe 'Guest not signed in' do
  subject { page }
  context 'visits new subscrition path' do
    before { visit new_subscription_path }
    it { should have_content 'You need to sign in'}
  end

  context 'visits edit verification path' do
    before { visit edit_verification_path }
    it { should have_content 'You need to sign in' }
  end

  context 'visits user show path' do
    let(:user) { create(:user) }
    before { visit user_path(user) }
    it { should have_content 'You need to sign in' }
  end
end
