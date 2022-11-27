feature 'Visiting the submissions index page' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let(:code_review) { FactoryBot.create(:code_review, course: student.course) }

  context 'as a student' do
    before { login_as(student, scope: :student) }

    scenario 'you are not authorized' do
      visit code_review_submissions_path(code_review)
      expect(page).to have_content 'not authorized'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
    before { login_as(admin, scope: :admin) }

    scenario 'lists submissions' do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      visit code_review_submissions_path(code_review)
      expect(page).to have_content submission.student.name
    end

    scenario 'lists only submissions needing review', :stub_mailgun do
      reviewed_submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      FactoryBot.create(:passing_review, submission: reviewed_submission)
      visit code_review_submissions_path(code_review)
      expect(page).to_not have_content reviewed_submission.student.name
    end

    scenario 'lists only submissions for enrolled students', :stub_mailgun do
      reviewed_submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      student.enrollments.destroy_all
      visit code_review_submissions_path(code_review)
      expect(page).to_not have_content reviewed_submission.student.name
    end

    scenario 'lists submissions in order of when they were submitted' do
      another_student = FactoryBot.create(:student)
      first_submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      second_submission = FactoryBot.create(:submission, code_review: code_review, student: another_student)
      visit code_review_submissions_path(code_review)
      within 'tbody' do
        expect(first('tr')).to have_content first_submission.student.name
      end
    end

    context 'assign teacher to submission' do
      let!(:admin2) { FactoryBot.create(:admin, name: 'second teacher')}

      scenario 'assign teacher' do
        submission = FactoryBot.create(:submission, code_review: code_review, student: student)
        visit code_review_submissions_path(code_review)
        select admin2.name, from: 'submission_admin_id'
        click_on 'Update'
        expect(submission.reload.admin).to eq admin2
        expect(page).to have_content admin2.name
      end
    end

    context 'within an individual submission' do
      scenario 'shows how long ago the submission was last updated' do
        travel_to 2.days.ago do
          FactoryBot.create(:submission, code_review: code_review, student: student)
        end
        visit code_review_submissions_path(code_review)
        expect(page).to have_content (Time.zone.now.in_time_zone(student.course.office.time_zone).to_date - 2.days).strftime("%a, %b %d, %Y")
      end

      scenario 'clicking review link to show review form' do
        FactoryBot.create(:submission, code_review: code_review, student: student)
        visit code_review_submissions_path(code_review)
        expect(page).to_not have_button 'Create Review'
        click_on 'Review'
        expect(page).to have_content code_review.objectives.first.content
        expect(page).to have_button 'Create Review'
      end

      context 'creating a review' do
        let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
        let!(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }
        let!(:score) { FactoryBot.create(:passing_score) }

        before do
          login_as(admin, scope: :admin)
          visit code_review_submissions_path(code_review)
        end

        scenario 'with valid input', :stub_mailgun do
          click_on 'Review'
          select score.description, from: 'review_grades_attributes_0_score_id'
          fill_in 'Note (Markdown compatible)', with: 'Well done!'
          fill_in 'review_student_signature', with: "#{student.name}"
          click_on 'Create Review'
          expect(page).to have_content 'Review saved.'
        end

        scenario 'with invalid input' do
          click_on 'Review'
          click_on 'Create Review'
          expect(page).to have_content "can't be blank"
        end

        context 'when the submission has been reviewed before' do
          let!(:review) { FactoryBot.create(:passing_review, submission: submission) }

          before { submission.update(needs_review: true) }

          scenario 'should be prepopulated with information from the last review created for this submission' do
            click_on 'Review'
            expect(page).to have_content "Great job!"
            expect(all('#review_note').last.value).to eq ''
          end

          scenario 'allow editing past review feedback' do
            click_on 'Review'
            all('#review_note').first.set('updated old feedback')
            click_on 'Update previously submitted note'
            expect(page).to have_content 'updated old feedback'
          end
        end

        context 'updating staff sticky note' do
          let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
          let(:submission) { FactoryBot.create(:submission, code_review: code_review, student: student) }

          before do
            login_as(admin, scope: :admin)
            visit new_submission_review_path(submission)
          end

          scenario 'updating staff sticky note' do
            fill_in 'student_staff_sticky', with: 'test staff sticky note'
            click_on 'Update sticky'
            visit new_submission_review_path(submission)
            expect(page).to have_content 'test staff sticky note'
            expect(student.reload.staff_sticky).to eq 'test staff sticky note'
          end

          scenario 'staff sticky note viewable from any CR review page' do
            fill_in 'student_staff_sticky', with: 'test staff sticky note'
            click_on 'Update sticky'
            new_submission = FactoryBot.create(:submission, student: student)
            visit new_submission_review_path(new_submission)
            expect(page).to have_content 'test staff sticky note'
          end
        end

        describe 'updating submission times_submitted', js: true do
          before do
            submission.update_columns(times_submitted: 2)
            click_on 'Review'
          end
          it 'increments when click plus sign' do
            click_link '+'
            expect(page).to have_content "Submitted 3 times"
            expect(submission.reload.times_submitted).to eq 3
          end
          it 'decrements when click minus sign' do
            click_on '-'
            expect(page).to have_content "Submitted 1 time"
            expect(submission.reload.times_submitted).to eq 1
          end
        end

        describe 'displays submission notes' do
          it 'displays notes if there are any' do
            submission.submission_notes.create(content: 'first note')
            submission.submission_notes.create(content: 'second note')
            click_on 'Review'
            expect(page).to have_content('first note')
            expect(page).to have_content('second note')
          end

          it 'renders markdown' do
            submission.submission_notes.create(content: '- note')
            click_on 'Review'
            expect(page).to have_css('li', text: 'note')
          end
        end

        describe 'shows links to other reviews for same course' do
          it 'displays links when at least one exists' do
            code_review = submission.code_review
            course = code_review.course
            code_review2 = FactoryBot.create(:code_review, course: course)
            submission2 = FactoryBot.create(:submission, code_review: code_review2, student: student)
            FactoryBot.create(:passing_review, submission: submission2)
            click_on 'Review'
            expect(page).to have_content("[View CR #{code_review2.number} review: #{code_review2.title}]")
          end
        end

        describe 'notes when submission is already passing' do
          it 'displays alert' do
            FactoryBot.create(:passing_review, submission: submission)
            click_on 'Review'
            expect(page).to have_content 'This submission has already been marked as passing.'
          end
        end
      end
    end
  end
end

feature 'creating a passing submission from a student page' do
  let(:course) { FactoryBot.create(:course) }
  let!(:code_review) { FactoryBot.create(:code_review, course: course) }
  let(:student) { FactoryBot.create(:student, course: course) }
  let(:admin) { course.admin }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    it 'shows link to create CR exemption when no submission exists' do
      visit course_student_path(course, student)
      expect(page).to have_css('#exempt-edit')
    end

    it 'does not show link to create CR exemption when submission exists' do
      submission = FactoryBot.create(:submission, code_review: code_review, student: student)
      visit course_student_path(course, student)
      expect(page).to_not have_css('#exempt-edit')
    end

    it 'links to CR exemption page' do
      visit course_student_path(course, student)
      find("[id='exempt-edit']").click
      expect(page).to have_content 'Code Review Exemption'
      expect(page).to have_content student.name
      expect(page).to have_content code_review.title
    end

    it 'allows creation of exempt passing submission' do
      visit course_student_path(course, student)
      find("[id='exempt-edit']").click
      click_on "Exempt #{student.name.upcase} from #{code_review.title.upcase}"
      expect(page).to have_content "#{code_review.title} marked as passing for #{student.name}"
      expect(current_path).to eq course_student_path(course, student)
      expect(page).to_not have_css('#exempt-edit')
      expect(page).to have_content 'exempt'
      expect(code_review.submission_for(student).meets_expectations?).to eq true
      expect(code_review.submission_for(student).needs_review).to eq false
      expect(code_review.submission_for(student).review_status).to eq 'pass'
    end
  end

  context 'as a student' do
    it 'does not show link to create CR exemption' do
      login_as(student, scope: :student)
      visit course_student_path(course, student)
      expect(page).to_not have_css('#exempt-edit')
    end
  end
end

feature 'Creating a student submission for an internship course code review' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let(:admin) { FactoryBot.create(:admin, current_course: student.course) }

  before { login_as(admin, scope: :admin) }

  scenario 'as an admin' do
    FactoryBot.create(:code_review, course: student.course, submissions_not_required: true)
    visit course_path(student.course)
    expect { click_on('missing') }.to change { student.submissions.count }.by 1
  end

  it 'finds existing submission if already exists when no submission required' do
    code_review = FactoryBot.create(:code_review, course: student.course, submissions_not_required: true)
    visit course_path(student.course)
    FactoryBot.create(:submission, student: student, code_review: code_review)
    click_on 'missing'
    expect(page).to_not have_content 'There was a problem'
    expect(page).to have_content 'Submitted less than a minute ago'
  end
end

feature 'Moving submissions between internship courses' do
  let(:admin) { FactoryBot.create(:admin, :with_course) }

  context 'as an admin' do
    before { login_as(admin, scope: :admin) }

    context 'move submission button' do
      scenario 'is displayed for admins when multiple internship courses and at least one submissions' do
        course_1 = FactoryBot.create(:internship_course)
        course_2 = FactoryBot.create(:internship_course)
        student = FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2])
        cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
        cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
        submission = FactoryBot.create(:submission, student: student, code_review: cr_1)
        visit course_student_path(course_1, student)
        expect(page).to have_content 'Move submissions to new internship course...'
      end

      scenario 'is not displayed when no submission in source career review' do
        course_1 = FactoryBot.create(:internship_course)
        course_2 = FactoryBot.create(:internship_course)
        student = FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2])
        cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
        cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
        submission = FactoryBot.create(:submission, student: student, code_review: cr_2)
        visit course_student_path(course_1, student)
        expect(page).to_not have_content 'Move submissions to new internship course...'
      end

      scenario 'is not displayed when only one internship course' do
        course_1 = FactoryBot.create(:internship_course)
        course_2 = FactoryBot.create(:course)
        student = FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2])
        cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
        cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
        submission = FactoryBot.create(:submission, student: student, code_review: cr_1)
        visit course_student_path(course_1, student)
        expect(page).to_not have_content 'Move submissions to new internship course...'
      end
    end

    context 'lists submissions ready to be moved' do
      let(:course_1) { FactoryBot.create(:internship_course) }
      let(:course_2) { FactoryBot.create(:internship_course) }
      let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2]) }
      let!(:cr_1) { FactoryBot.create(:code_review, course: course_1, title: "same title") }
      let!(:submission) { FactoryBot.create(:submission, student: student, code_review: cr_1) }

      scenario 'with matching code review in other internship course' do
        cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
        visit course_student_path(course_1, student)
        expect(page).to have_content 'ready to be moved'
      end

      scenario 'without matching code review in other internship course' do
        cr_2 = FactoryBot.create(:code_review, course: course_2, title: "different title")
        visit course_student_path(course_1, student)
        expect(page).to have_content 'matching career review not found in destination course'
      end

      scenario 'without submission' do
        cr_2 = FactoryBot.create(:code_review, course: course_1, title: "second code review")
        visit course_student_path(course_1, student)
        expect(page).to have_content 'no submission'
      end
    end

    context 'moving submissions' do
      let(:course_1) { FactoryBot.create(:internship_course) }
      let(:course_2) { FactoryBot.create(:internship_course) }
      let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2]) }
      let!(:cr_1) { FactoryBot.create(:code_review, course: course_1, title: "first code review") }
      let!(:cr_2) { FactoryBot.create(:code_review, course: course_1, title: "second code review") }
      let!(:cr_3) { FactoryBot.create(:code_review, course: course_1, title: "third code review") }
      let!(:cr_4) { FactoryBot.create(:code_review, course: course_2, title: "first code review") }
      let!(:submission_1) { FactoryBot.create(:submission, student: student, code_review: cr_1) }
      let!(:submission_2) { FactoryBot.create(:submission, student: student, code_review: cr_2) }

      before do
        login_as(admin, scope: :admin)
        visit course_student_path(course_1, student)
      end

      scenario 'with one matching code review with submission' do
        click_on 'submit-move-submissions-button'
        expect(submission_1.reload.code_review).to eq cr_4
        expect(submission_2.reload.code_review).to eq cr_2
      end
    end
  end

  context 'as a student' do
    scenario 'move submissions button is not displayed' do
      course_1 = FactoryBot.create(:internship_course)
      course_2 = FactoryBot.create(:internship_course)
      student = FactoryBot.create(:student, :with_all_documents_signed, courses: [course_1, course_2])
      cr_1 = FactoryBot.create(:code_review, course: course_1, title: "same title")
      cr_2 = FactoryBot.create(:code_review, course: course_2, title: "same title")
      submission = FactoryBot.create(:submission, student: student, code_review: cr_1)
      login_as(student, scope: :student)
      visit course_student_path(course_1, student)
      expect(page).to_not have_content 'Move submissions to new internship course...'
    end
  end
end