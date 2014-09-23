require 'rails_helper'

feature 'User adds a requirement to the assessment' do
  before do
    assessment = FactoryGirl.create(:assessment)
    visit assessment_path(assessment)
    click_link "New Requirement"
  end

  scenario 'with valid form', js: true do
    fill_in 'Content', with: 'Hosted on Heroku'
    click_on 'Submit'
    expect(page).to have_content 'Hosted on Heroku'
  end
end
