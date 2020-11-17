describe PairFeedback do
  it { should belong_to(:student) }
  it { should belong_to(:pair).class_name('Student') }
  it { should validate_presence_of :q1_response }
  it { should validate_presence_of :q2_response }
  it { should validate_presence_of :q3_response }

  describe '.today' do
    it 'returns all the pair feedback created today' do
      student = FactoryBot.create(:student)
      travel_to Date.today - 1.week do
        FactoryBot.create(:pair_feedback, student: student)
      end
      pair_feedback_today = FactoryBot.create(:pair_feedback, student: student)
      expect(PairFeedback.today).to eq [pair_feedback_today]
    end
  end

  it 'returns total score' do
    pair_feedback = FactoryBot.create(:pair_feedback)
    expect(pair_feedback.score).to eq pair_feedback.q1_response + pair_feedback.q2_response + pair_feedback.q3_response
  end

  it 'returns average total score for student in course so far' do
    student = FactoryBot.create(:student)
    travel_to student.course.start_date do
      pair_feedback = FactoryBot.create(:pair_feedback, pair: student, q1_response: 1, q2_response: 2, q3_response: 3)
      pair_feedback_2 = FactoryBot.create(:pair_feedback, pair: student, q1_response: 1, q2_response: 2, q3_response: 3)
    end
    travel_to student.course.start_date - 1.day do
      pair_feedback_other_course = FactoryBot.create(:pair_feedback, pair: student, q1_response: 5, q2_response: 5, q3_response: 5)
    end
    expect(PairFeedback.average(student, student.course)).to eq 6
  end

  it 'returns response if no pair feedbacks of student during course' do
    student = FactoryBot.create(:student)
    expect(PairFeedback.average(student, student.course)).to eq '-'
  end
end
