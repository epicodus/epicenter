require 'rails_helper'

describe 'Home page' do
  subject { page }
  before(:each) { visit root_path }

  it { should have_link 'Start Making Payments' }
  it { should have_link 'Sign-in'}
end

describe 'Start making payments link' do
  it "navigates to sign up page" do
    visit root_path
    click_on 'Start Making Payments'
    expect(page).to have_content 'Sign up'
  end
end
