feature 'viewing the ratings index page' do
  let(:internship_course) { FactoryGirl.create(:internship_course) }
  let(:admin) { FactoryGirl.create(:admin, current_course: internship_course) }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    scenario 'with a paginated list of ratings' do
      visit internships_path(active: true)
      click_on 'Interview rankings'
      expect(page).to have_content internship_course.description
    end

    scenario 'with all ratings' do
      FactoryGirl.create(:student, course: internship_course)
      visit internships_path(active: true)
      click_on 'Interview rankings'
      click_on 'View all'
      expect(page).to have_content internship_course.description
    end
  end

  context 'as a student' do
    let(:student) { FactoryGirl.create(:student) }
    before { login_as(student, scope: :student) }

    scenario 'without permission' do
      visit course_ratings_path(internship_course)
      expect(page).to have_content "You are not authorized to access this page."
    end
  end

end
