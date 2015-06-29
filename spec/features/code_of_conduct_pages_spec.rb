feature 'viewing code of conduct document' do
  scenario 'as a student', js: true do
    include Capybara::DSL
    Capybara.current_driver = :poltergeist_billy_custom
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    visit new_code_of_conduct_path
    within_frame('hsEmbeddedFrame') do
      expect(page).to have_content 'Sign to accept the Epicodus Code of Conduct'
    end
  end
end
