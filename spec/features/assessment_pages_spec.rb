require 'rails_helper'

feature 'User creates new assessment' do
  before do
    visit new_assessment_path
  end

  scenario 'with valid form', js: true do
    fill_in 'Title', with: 'example title'
    fill_in 'Section', with: 'example section'
    fill_in 'Url', with: 'www.someurl.com'
    click_on 'Submit'
    expect(page).to have_content 'Assessment added!'
  end
end
