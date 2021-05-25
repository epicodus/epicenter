feature 'Visiting the peer evaluations index page' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let(:other_student) { FactoryBot.create(:student, :with_all_documents_signed) }

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
    before { login_as(admin, scope: :admin) }

    context 'you can view the peer evaluations list' do
      scenario 'via the student page' do
        visit course_student_path(student.course, student)
        click_on 'Peer evaluations'
        expect(page).to have_content "Peer evaluations written by #{student.name}"
      end

      scenario 'of evals written by the student' do
        peer_evaluation = FactoryBot.create(:peer_evaluation, evaluator: student, evaluatee: other_student)
        visit student_peer_evaluations_path(student)
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
        expect(page).to have_content peer_evaluation.evaluatee.name
      end

      scenario 'of evals written for the student' do
        peer_evaluation = FactoryBot.create(:peer_evaluation, evaluator: student, evaluatee: other_student)
        visit student_peer_evaluations_path(other_student)
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
        expect(page).to_not have_content peer_evaluation.evaluator.name
      end

      scenario 'you can view the list of all students with number of peer evaluations' do
        visit course_path(student.course)
        click_on 'Peer Evaluations'
        expect(page).to have_content 'Peer evaluations by or of students in this course'
        expect(page).to have_content student.name
        expect(page).to have_content 0
      end
    end

    context 'you can view an individual evaluation' do
      let!(:peer_evaluation) { FactoryBot.create(:peer_evaluation, evaluator: student, evaluatee: other_student) }

      scenario 'writen by the student' do
        visit student_peer_evaluations_path(student)
        click_on peer_evaluation.evaluatee.name
        expect(page).to have_content 'Technical'
      end

      scenario 'including the evaluator name' do
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content "Interviewer: #{peer_evaluation.evaluator.name}"
      end

      scenario 'including the evaluatee name and date' do
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content "Interviewee: #{peer_evaluation.evaluatee.name}"
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
      end

      scenario 'question text and response to multiple choice question' do
        peer_response = FactoryBot.create(:peer_response, peer_evaluation: peer_evaluation)
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content peer_response.peer_question.content
        expect(page).to have_content 'All of the time'
      end

      scenario 'question text and response to feedback question' do
        peer_response = FactoryBot.create(:peer_response_feedback, peer_evaluation: peer_evaluation)
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content peer_response.peer_question.content
        expect(page).to have_content peer_response.response
      end
    end
  end



  context 'as a student' do
    before { login_as(student, scope: :student) }

    context 'you can view the peer evaluations list' do
      scenario 'via the navbar' do
        visit root_path
        click_on 'Peer evaluations'
        expect(page).to have_content "Peer evaluations written by you"
      end

      scenario 'of evals you wrote' do
        peer_evaluation = FactoryBot.create(:peer_evaluation, evaluator: student, evaluatee: other_student)
        visit student_peer_evaluations_path(student)
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
        expect(page).to have_content peer_evaluation.evaluatee.name
      end

      scenario 'of evals about your whiteboarding' do
        peer_evaluation = FactoryBot.create(:peer_evaluation, evaluator: other_student, evaluatee: student)
        visit student_peer_evaluations_path(student)
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
        expect(page).to_not have_content peer_evaluation.evaluator.name
      end
    end

    context 'you can not view evaluations of other students' do
      let!(:peer_evaluation) { FactoryBot.create(:peer_evaluation) }

      scenario 'on your evaluations list page' do
        visit student_peer_evaluations_path(student)
        expect(page).to_not have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
      end

      scenario 'on other student evaluations list page' do
        visit student_peer_evaluations_path(other_student)
        expect(page).to have_content 'You are not authorized'
      end

      scenario 'on peer evaluation by and for another student' do
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content 'You are not authorized'
      end

      scenario 'on peer evaluation by and for another student' do
        visit student_peer_evaluation_path(other_student, peer_evaluation)
        expect(page).to have_content 'You are not authorized'
      end
    end

    context 'you can view an individual evaluation' do
      let!(:peer_evaluation) { FactoryBot.create(:peer_evaluation, evaluator: student, evaluatee: other_student) }

      scenario 'writen by you' do
        visit student_peer_evaluations_path(student)
        click_on peer_evaluation.evaluatee.name
        expect(page).to have_content 'Technical'
      end

      scenario 'writen about you' do
        eval_of_you = FactoryBot.create(:peer_evaluation, evaluator: other_student, evaluatee: student)
        visit student_peer_evaluations_path(student)
        click_on 'click to view'
        expect(page).to have_content 'Technical'
      end

      scenario 'does not show the evaluator name' do
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to_not have_content "Interviewer: #{peer_evaluation.evaluator.name}"
      end

      scenario 'including the evaluatee name and date' do
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content "Interviewee: #{peer_evaluation.evaluatee.name}"
        expect(page).to have_content peer_evaluation.created_at.to_date.strftime('%B %d %Y')
      end

      scenario 'question text and response to multiple choice question' do
        peer_response = FactoryBot.create(:peer_response, peer_evaluation: peer_evaluation)
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content peer_response.peer_question.content
        expect(page).to have_content 'All of the time'
      end

      scenario 'question text and response to feedback question' do
        peer_response = FactoryBot.create(:peer_response_feedback, peer_evaluation: peer_evaluation)
        visit student_peer_evaluation_path(student, peer_evaluation)
        expect(page).to have_content peer_response.peer_question.content
        expect(page).to have_content peer_response.response
      end
    end

    context 'you can create a new evaluation' do
      scenario 'you can navigate to the new evaluation form' do
        visit student_peer_evaluations_path(student)
        click_on 'New peer evaluation'
        expect(page).to have_content "Interview the candidate using the following criteria."
      end

      scenario 'you can select a student from same course dates at a different office' do
        course_other_office = FactoryBot.create(:course, class_days: student.course.class_days)
        student_other_office = FactoryBot.create(:student, course: course_other_office)
        visit new_student_peer_evaluation_path(student)
        expect(page).to have_content student_other_office.name
      end

      scenario 'you can submit the form' do
        FactoryBot.create(:peer_question)
        FactoryBot.create(:peer_question_feedback)
        cohort_student = FactoryBot.create(:student, course: student.course)
        visit new_student_peer_evaluation_path(student)
        select cohort_student.name, from: 'peer-eval-select-name'
        find('#peer_evaluation_peer_responses_attributes_0_response option:last-of-type').select_option
        find('textarea').set('foo')
        click_on 'Submit peer evaluation'
        expect(page).to have_content "Peer evaluation of #{cohort_student.name} submitted"
        eval = PeerEvaluation.first
        expect(eval.evaluator).to eq student
        expect(eval.evaluatee).to eq cohort_student
        expect(eval.peer_responses.first.response).to eq 'None of the time'
        expect(eval.peer_responses.last.response).to eq 'foo'
      end
    end
  end
end
