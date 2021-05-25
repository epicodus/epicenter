feature 'teacher code_review report' do
  describe 'reports index page' do
    it 'links to teacher code review page' do
      admin = FactoryBot.create(:admin, :with_course, teacher: true)
      login_as(admin, scope: :admin)
      visit reports_path
      click_on 'Reviews sorted by teacher'
      expect(page).to have_content 'Reviews per admin'
    end
  end

  describe 'list of teachers with num of reviews' do
    let(:student) { FactoryBot.create(:student, :with_course) }
    let(:admin) { FactoryBot.create(:admin, current_course: student.course, teacher: true) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }
    let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }

    before { login_as(admin, scope: :admin) }

    it 'does not list non-teacher admin' do
      non_teacher = FactoryBot.create(:admin)
      review = FactoryBot.create(:review, submission: submission, admin: non_teacher)
      visit reports_teachers_path
      expect(page).to_not have_content non_teacher.name
    end

    it 'shows review just created' do
      travel_to student.course.start_date do
        review = FactoryBot.create(:review, submission: submission, admin: admin)
        visit reports_teachers_path
        expect(page).to have_content admin.name
        expect(page).to have_content 1
      end
    end

    it 'does not show review created previous week' do
      travel_to Date.today - 1.week do
        review = FactoryBot.create(:review, submission: submission, admin: admin)
      end
      visit reports_teachers_path
      expect(page).to_not have_content admin.name
    end

    it 'shows review created previous week when navigate to previous week' do
      travel_to Date.today - 1.week do
        review = FactoryBot.create(:review, submission: submission, admin: admin)
      end
      visit reports_teachers_path
      click_link 'previous-week'
      expect(page).to have_content admin.name
      expect(page).to have_content 1
    end

    it 'shows review created the next week when navigate to next week' do
      travel_to student.course.start_date do
        review = FactoryBot.create(:review, submission: submission, admin: admin)
        visit reports_teachers_path(week: Date.today - 1.week)
        click_link 'next-week'
        expect(page).to have_content admin.name
        expect(page).to have_content 1
      end
    end
  end

  describe 'individual teacher page' do
    let(:student) { FactoryBot.create(:student, :with_course) }
    let(:admin) { FactoryBot.create(:admin, current_course: student.course, teacher: true) }
    let(:code_review) { FactoryBot.create(:code_review, course: student.course) }
    let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
    let!(:review) { FactoryBot.create(:review, submission: submission, admin: admin) }

    before { login_as(admin, scope: :admin) }

    it 'shows review just created' do
      travel_to review.created_at do
        visit reports_teacher_path(admin)
        expect(page).to have_content admin.name
        expect(page).to have_content student.name
        expect(page).to have_content code_review.title
      end
    end

    it 'links to review' do
      travel_to review.created_at do
        visit reports_teacher_path(admin)
        click_on student.name
        expect(page).to have_content 'Objectives'
      end
    end

    it 'links to code review assignment' do
      travel_to review.created_at do
        visit reports_teacher_path(admin)
        click_on code_review.title
        expect(page).to have_content 'Project'
      end
    end

    it 'does not show review for a different day' do
      travel_to review.created_at do
        visit reports_teacher_path(admin, day: Date.today - 1.day)
        expect(page).to have_content admin.name
        expect(page).to_not have_content student.name
        expect(page).to_not have_content code_review.title
      end
    end
  end

  context 'visiting as a student' do
    let(:student) { FactoryBot.create(:student) }
    before { login_as(student, scope: :student) }

    it 'is not authorized to view reports index' do
      visit reports_path
      expect(page).to have_content("not authorized")
    end

    it 'is not authorized to view teacher reports' do
      visit reports_teachers_path
      expect(page).to have_content("not authorized")
    end
  end
end
