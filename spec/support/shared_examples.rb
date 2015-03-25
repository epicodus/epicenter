shared_examples "require admin login" do
  before { visit root_path }
  before { click_link "Log out" }
  it "requires login" do
    action
    expect(page).to have_content 'You need to sign in.'
  end

  it "doesn't allow student access" do
    student = FactoryGirl.create(:student)
    login_as(student, scope: :student)
    action
    expect(page).to have_content 'You are not authorized to access this page'
  end
end
