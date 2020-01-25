feature 'Visiting the submissions index page' do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }
  let(:code_review) { FactoryBot.create(:code_review, course: student.course) }

  context 'as a student' do
    before { login_as(student, scope: :student) }

    scenario 'you are not authorized' do
      visit code_review_submissions_path(code_review)
      expect(page).to have_content 'not authorized'
    end
  end

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin) }
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
        let(:admin) { FactoryBot.create(:admin) }
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

          scenario 'should be prepopulated with information from the last review created for this submission', :stub_mailgun do
            click_on 'Review'
            expect(page).to have_content "Great job!"
            expect(find_field('Note (Markdown compatible)').value).to eq ''
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
            submission.notes.create(content: 'first note')
            submission.notes.create(content: 'second note')
            click_on 'Review'
            expect(page).to have_content('first note')
            expect(page).to have_content('second note')
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

feature 'Creating a student submission for an internship course code review' do
  let(:student) { FactoryBot.create(:user_with_all_documents_signed) }
  let(:admin) { FactoryBot.create(:admin) }

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
