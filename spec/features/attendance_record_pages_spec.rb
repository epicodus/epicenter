require 'rails_helper'

feature 'creating an attencance record' do
  before do
    5.times { FactoryGirl.create(:user) }
  end

  scenario 'correctly' do
    visit '/attendance'
    first('form').click_button("I'm here")
    expect(page).to have_content "Welcome"
  end
end
