feature 'Adding survey to code reviews' do
  let!(:course) { FactoryBot.create(:course) }
  let!(:code_review) { FactoryBot.create(:code_review, course: course, visible_date: Time.zone.now.beginning_of_week + 4.days) }

  scenario 'as a guest cannot view form' do
    visit new_survey_path
    expect(page).to have_content 'need to sign in'
  end

  scenario 'as a student cannot view form' do
    student = FactoryBot.create(:student, :with_all_documents_signed)
    login_as(student, scope: :student)
    visit new_survey_path
    expect(page).to have_content 'need to sign in'
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }

    before do
      login_as(admin, scope: :admin)
      visit new_survey_path
    end

    scenario 'can view survey form' do
      expect(page).to have_content "Survey URL"
    end

    scenario 'can add survey to this week code reviews' do
      fill_in 'url', with: 'foo.js'
      click_on "Add survey to this week's code reviews"
      expect(page).to have_content 'foo.js is assigned to the following code reviews'
      expect(page).to have_content code_review.title
    end

    scenario 'sees error when adding survey with invalid url' do
      fill_in 'url', with: 'bad input'
      click_on "Add survey to this week's code reviews"
      expect(page).to have_content 'Invalid survey URL'
    end

    scenario 'sees error when no code reviews found to assign survey to' do
      code_review.destroy
      fill_in 'url', with: 'foo.js'
      click_on "Add survey to this week's code reviews"
      expect(page).to have_content 'No code reviews found'
    end
  end
end
