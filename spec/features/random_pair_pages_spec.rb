feature 'viewing the random pair page' do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
  let(:student_2) { FactoryGirl.create(:student) }
  let(:student_3) { FactoryGirl.create(:student) }
  let(:admin) { FactoryGirl.create(:admin) }

  scenario 'viewing the random pair page as a guest' do
    visit random_pairs_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  scenario 'viewing the random pair page as an admin' do
    login_as(admin, scope: :admin)
    visit random_pairs_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  scenario 'viewing random pairs' do
    allow(student).to receive(:random_pairs).and_return [student_3, student_2]
    login_as(student, scope: :student)
    visit random_pairs_path
    expect(page).to have_content student_2.name && student_3.name
  end

  scenario 'viewing random pairs page when no random pairs are available' do
    allow(student).to receive(:random_pairs).and_return []
    login_as(student, scope: :student)
    visit random_pairs_path
    expect(page).to have_content 'No random pairs available just yet!'
  end
end
