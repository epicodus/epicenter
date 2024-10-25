feature 'viewing the ratings index page' do
  context 'as an admin' do
    let(:internship) { FactoryBot.create(:internship) }
    let(:student) { FactoryBot.create(:student, courses: [internship.courses.first]) }
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
    before { login_as(admin, scope: :admin) }

    scenario 'shows student ratings of companies pre-interviews' do
      rating = FactoryBot.create(:rating, student: student, internship: internship, number: 99)
      visit internships_path(active: true)
      click_on 'Interview rankings'
      expect(page).to have_content student.course.description
      expect(page).to have_content rating.number
    end

    scenario 'shows student ratings of companies post-interviews' do
      interview_assignment = FactoryBot.create(:interview_assignment, student_id: student.id, internship_id: internship.id, ranking_from_student: 55)
      visit internships_path(active: true)
      click_on 'Placement rankings'
      expect(page).to have_content student.course.description
      expect(page).to have_content '55'
    end
  end

  context 'as a student' do
    let(:internship_course) { FactoryBot.create(:internship_course) }
    let(:student) { FactoryBot.create(:student, :with_all_documents_signed) }
    before { login_as(student, scope: :student) }

    scenario 'without permission' do
      visit course_ratings_path(internship_course)
      expect(page).to have_content "You are not authorized to access this page."
    end
  end
end
