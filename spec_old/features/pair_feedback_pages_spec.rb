feature 'Visiting the pair feedback index page' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
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

  context 'as a student' do
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
  end
end

feature 'Submitting pair feedback' do
  let(:student) { FactoryBot.create(:student, :with_course, :with_all_documents_signed) }
  let!(:pair) { FactoryBot.create(:student, :with_all_documents_signed, courses: [student.course]) }

  before { login_as(student, scope: :student) }

  context 'when not signed in' do
    scenario 'does not show pair feedback page' do
      travel_to student.course.start_date do
        visit pair_feedback_path
        expect(page).to have_content "You haven't signed in yet today"
        expect(page).to_not have_content 'Pair feedback'
      end
    end
  end

  context 'without a pair' do
    let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date) }

    context 'when in classroom' do
      before { allow(IpLocation).to receive(:is_local_computer_portland?).and_return(true) }
      scenario 'does not redirect to pair feedback' do
        travel_to student.course.start_date do
          visit '/sign_out'
          click_on 'Attendance sign out'
          expect(page).to have_content 'Your attendance record has been updated.'
          expect(page).to_not have_content 'Pair feedback'
        end
      end
    end

    context 'when remote' do
      before { allow(IpLocation).to receive(:is_local_computer_portland?).and_return(false) }
      scenario 'does not redirect to pair feedback' do
        travel_to student.course.start_date do
          visit '/sign_out'
          click_on 'Attendance sign out'
          expect(page).to have_content 'Your attendance record has been updated.'
          expect(page).to_not have_content 'Pair feedback'
        end
      end
    end

    context 'when navigating directly to pair feedback' do
      scenario 'does not show pair feedback page' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          expect(page).to have_content 'You signed in solo today'
          expect(page).to_not have_content 'Pair feedback'
        end
      end
    end
  end

  context 'with a pair' do
    let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [pair_id: pair.id]) }

    context 'when in classroom' do
      before do
        allow(IpLocation).to receive(:is_local_computer_portland?).and_return(true)
        allow(EmailJob).to receive(:perform_later).and_return({})
      end
      scenario 'does not direct to pair feedback' do
        today = student.course.start_date
        travel_to today do
          visit '/sign_out'
          click_on 'Attendance sign out'
          expect(EmailJob).to have_received(:perform_later).with(
            { :from => student.course.admin.email,
              :to => student.email,
              :subject => 'Pair feedback form for ' + today.strftime("%A %B ") + today.day.ordinalize,
              :text => "If you wish to submit pair feedback for " + today.strftime("%A %B ") + today.day.ordinalize + ", please visit https://epicenter.epicodus.com/pair_feedback before midnight."
            }
          )
          expect(page).to have_content 'Your attendance record has been updated.'
          expect(page).to_not have_content "Only Epicodus staff will see your pair feedback"
        end
      end
    end

    context 'when remote' do
      before { allow(IpLocation).to receive(:is_local_computer_portland?).and_return(false) }

      scenario 'directs to pair feedback when not in classroom' do
        travel_to student.course.start_date do
          visit '/sign_out'
          click_on 'Attendance sign out'
          expect(page).to have_content "Only Epicodus staff will see your pair feedback"
        end
      end

      scenario 'does not show pair feedback page if already submitted for all pairs' do
        travel_to student.course.start_date do
          pair_feedback = FactoryBot.create(:pair_feedback, student: student, pair: pair)
          visit pair_feedback_path
          expect(page).to have_content 'All pair feedback submitted for today'
        end
      end

      scenario 'allows skipping of pair feedback submission' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          click_on 'Skip pair feedback'
          expect(page).to_not have_content 'Pair feedback'
        end
      end

      scenario 'you can submit with all fields' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          find('textarea').set('foo')
          click_on 'Submit pair feedback'
          expect(page).to have_content "All pair feedback submitted for today"
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
          visit pair_feedback_path
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          click_on 'Submit pair feedback'
          expect(page).to have_content "All pair feedback submitted for today"
        end
      end

      scenario 'you can not submit if missing q1' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          choose 'pair_feedback_q2_response_2'
          choose 'pair_feedback_q3_response_3'
          click_on 'Submit pair feedback'
          expect(page).to have_content "Q1 response can't be blank"
        end
      end

      scenario 'you can not submit if missing q2' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q3_response_3'
          click_on 'Submit pair feedback'
          expect(page).to have_content "Q2 response can't be blank"
        end
      end

      scenario 'you can not submit if missing q3' do
        travel_to student.course.start_date do
          visit pair_feedback_path
          choose 'pair_feedback_q1_response_1'
          choose 'pair_feedback_q2_response_2'
          click_on 'Submit pair feedback'
          expect(page).to have_content "Q3 response can't be blank"
        end
      end
    end
  end

  context 'with a group of 3', :stub_mailgun do
    let!(:pair2) { FactoryBot.create(:student) }
    let!(:attendance_record) { FactoryBot.create(:attendance_record, student: student, date: student.course.start_date, pairings_attributes: [{pair_id: pair.id}, {pair_id: pair2.id}]) }

    scenario 'you can submit feedback for both partners' do
      travel_to student.course.start_date do
        visit pair_feedback_path
        choose 'pair_feedback_q1_response_1'
        choose 'pair_feedback_q2_response_2'
        choose 'pair_feedback_q3_response_3'
        find('textarea').set("#{pair.name} feedback")
        click_on 'Continue to next pair feedback'
        choose 'pair_feedback_q1_response_1'
        choose 'pair_feedback_q2_response_2'
        choose 'pair_feedback_q3_response_3'
        find('textarea').set("#{pair2.name} feedback")
        click_on 'Submit pair feedback'
        expect(page).to have_content "All pair feedback submitted for today"
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
