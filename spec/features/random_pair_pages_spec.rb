feature 'viewing the random pair page' do
  let(:student) { FactoryGirl.create(:user_with_all_documents_signed) }
  let(:student_2) { FactoryGirl.create(:student) }
  let(:student_3) { FactoryGirl.create(:student) }
  let(:admin) { FactoryGirl.create(:admin) }
  let(:monday) { Time.zone.now.to_date.beginning_of_week }
  let(:friday) { monday + 4.days }
  let(:saturday) { monday + 5.days }

  scenario 'viewing the random pair page as a guest' do
    visit random_pairs_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  scenario 'viewing the random pair page as an admin' do
    login_as(admin, scope: :admin)
    visit random_pairs_path
    expect(page).to have_content 'You need to sign in or sign up before continuing.'
  end

  scenario 'viewing the random pair page on a weekend as a current student' do
    login_as(student, scope: :student)
    travel_to saturday do
      visit random_pairs_path
      expect(current_path).to eql cohort_code_reviews_path(student.cohort)
    end
  end

  scenario 'visiting the random pair page on a weekday' do
    login_as(student, scope: :student)
    travel_to friday do
      visit random_pairs_path
      expect(current_path).to eql random_pairs_path
    end
  end

  scenario 'viewing random pairs on a weekday' do
    allow(student).to receive(:random_pairs).and_return [student_3, student_2]
    login_as(student, scope: :student)
    travel_to friday do
      visit random_pairs_path
      expect(page).to have_content student_2.name && student_3.name
    end
  end
end
