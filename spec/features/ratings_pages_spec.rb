feature 'viewing the ratings index page' do
  let(:internship_course) { FactoryGirl.create(:internship_course) }
  let(:admin) { FactoryGirl.create(:admin, current_course: internship_course) }

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
