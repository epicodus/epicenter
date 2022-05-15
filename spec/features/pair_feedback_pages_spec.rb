feature 'Visiting the pair feedback index page' do
  let(:office) { FactoryBot.create(:online_office) }
  let(:course) { FactoryBot.create(:course, office: office)}
  let(:student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [course]) }
  let!(:pair) { FactoryBot.create(:student, :with_all_documents_signed, courses: [student.course]) }

  context 'as an admin' do
    let(:admin) { FactoryBot.create(:admin, current_course: student.course) }
    before { login_as(admin, scope: :admin) }

    scenario 'you can navigate to view pair feedback' do
      visit student_courses_path(pair)
      click_on 'Pair Feedback'
      expect(page).to have_content "Evaluator"
    end

    scenario 'you can view pair feedback for a student' do
      pair_feedback = FactoryBot.create(:pair_feedback, student: student, pair: pair)
      visit student_pair_feedbacks_path(pair)
      expect(page).to have_content student.name
      expect(page).to have_content pair_feedback.score
    end
  end

  context 'as a remote student' do
    before { login_as(student, scope: :student) }

    context 'you can not view pair feedback' do
      let!(:pair_feedback) { FactoryBot.create(:pair_feedback) }

      scenario 'written by you' do
        visit student_pair_feedbacks_path(student)
        expect(page).to have_content 'You are not authorized'
      end

      scenario 'written about you' do
        visit student_pair_feedbacks_path(pair)
        expect(page).to have_content 'You are not authorized'
      end
    end

    context 'without a pair' do
      let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }
      scenario 'sign out page has only sign out button' do
        travel_to student.course.start_date do
          visit '/sign_out'
          expect(page).to_not have_content "Only Epicodus staff will see your pair feedback"
          expect(page).to have_content "You'll be leaving early"
        end
      end
    end

    context 'submitting pair feedback' do
      let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [pair_id: pair.id]) }

      scenario 'you can navigate to the new feedback form' do
        travel_to student.course.start_date do
          visit '/sign_out'
          expect(page).to have_content "Only Epicodus staff will see your pair feedback"
        end
      end

      scenario 'you can submit with all fields' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          find('textarea').set('foo')
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Pair feedback submitted"
          expect(page).to have_content "You'll be leaving early"
          feedback = PairFeedback.last
          expect(feedback.student).to eq student
          expect(feedback.pair).to eq pair
          expect(feedback.q1_response).to eq 1
          expect(feedback.q2_response).to eq 2
          expect(feedback.q3_response).to eq 3
          expect(feedback.comments).to eq 'foo'
        end
      end

      scenario 'you can submit without comments' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Pair feedback submitted"
          expect(page).to have_content "You'll be leaving early"
        end
      end

      scenario 'you can not submit if missing q1' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Q1 response can't be blank"
        end
      end

      scenario 'you can not submit if missing q2' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q3_response_3'
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Q2 response can't be blank"
        end
      end

      scenario 'you can not submit if missing q3' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Q3 response can't be blank"
        end
      end
    end

    context 'submitting pair feedback for group of 3' do
      let!(:pair2) { FactoryBot.create(:student) }
      let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [{pair_id: pair.id}, {pair_id: pair2.id}]) }

      scenario 'you can submit feedback for both partners' do
        travel_to student.course.start_date do
          visit '/sign_out'
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          find('textarea').set("#{pair.name} feedback")
          click_on 'Continue to next pair feedback'
          expect(page).to have_content "Only Epicodus staff will see your pair feedback"
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          find('textarea').set("#{pair2.name} feedback")
          click_on 'Continue to attendance sign out'
          expect(page).to have_content "Pair feedback submitted"
          expect(page).to have_content "You'll be leaving early"
          pair1_feedback = PairFeedback.find_by(student: student, pair: pair)
          pair2_feedback = PairFeedback.find_by(student: student, pair: pair2)
          expect(pair1_feedback.student).to eq student
          expect(pair1_feedback.pair).to eq pair
          expect(pair1_feedback.q1_response).to eq 1
          expect(pair1_feedback.q2_response).to eq 2
          expect(pair1_feedback.q3_response).to eq 3
          expect(pair2_feedback.student).to eq student
          expect(pair2_feedback.pair).to eq pair2
          expect(pair2_feedback.q1_response).to eq 1
          expect(pair2_feedback.q2_response).to eq 2
          expect(pair2_feedback.q3_response).to eq 3
        end
      end
    end
  end

  context 'as an in-person student' do
    let(:pdx_office) { FactoryBot.create(:portland_office) }
    let(:pdx_course) { FactoryBot.create(:course, office: pdx_office) }
    let(:pdx_student) { FactoryBot.create(:student, :with_all_documents_signed, courses: [pdx_course]) }
    let!(:attendance_record) { FactoryBot.create(:attendance_record, student: pdx_student, date: pdx_course.start_date, pairings_attributes: [pair_id: pair.id]) }

    before do
      allow(IpLocation).to receive(:is_local?).and_return(true)
      login_as(pdx_student, scope: :student)
    end

    scenario 'it allows pair feedback to be submitted manually' do
      travel_to pdx_course.start_date do
        visit root_path
        click_on 'Pair feedback'
        choose 'pair_feedback_q1_response_1'
        choose 'pair_feedback_q2_response_2'
        choose 'pair_feedback_q3_response_3'
        find('textarea').set('foo')
        click_on 'Submit pair feedback'
        expect(page).to have_content "Pair feedback submitted"
        expect(page).to_not have_content "You'll be leaving early"
        feedback = PairFeedback.last
        expect(feedback.student).to eq pdx_student
        expect(feedback.pair).to eq pair
        expect(feedback.q1_response).to eq 1
        expect(feedback.q2_response).to eq 2
        expect(feedback.q3_response).to eq 3
        expect(feedback.comments).to eq 'foo'
      end
    end

    scenario 'it does not show pair feedback form when signing out' do
      travel_to pdx_course.start_date do
        visit '/sign_out'
        expect(page).to_not have_content 'Only Epicodus staff will see your pair feedback'
        expect(page).to have_content 'Attendance sign out'
      end
    end
  end
end
