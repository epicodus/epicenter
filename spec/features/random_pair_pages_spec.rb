feature 'viewing the random pair page' do
  let(:current_student) { FactoryGirl.create(:user_with_all_documents_signed) }
  let(:pair_1) { FactoryGirl.create(:student) }
  let(:pair_2) { FactoryGirl.create(:student) }
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
    allow(current_student).to receive(:random_pairs).and_return [pair_2, pair_1]
    login_as(current_student, scope: :student)
    visit random_pairs_path
    expect(page).to have_content pair_1.name && pair_2.name
  end

  scenario 'viewing random pairs page when no random pairs are available' do
    allow(current_student).to receive(:random_pairs).and_return []
    login_as(current_student, scope: :student)
    visit random_pairs_path
    expect(page).to have_content 'No pair suggestions available just yet!'
  end
end
