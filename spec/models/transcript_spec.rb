describe Transcript do
  let(:student) { FactoryGirl.create(:student) }

  it 'initializes with a student' do
    transcript = Transcript.new(student)
    expect(transcript).to be_a Transcript
  end

  describe '#passing_assessments' do
    it 'returns all the assessments for which the student has met expectations', :vcr do
      passed_assessment = FactoryGirl.create(:assessment, cohort: student.cohort)
      passed_submission = FactoryGirl.create(:submission, student: student, assessment: passed_assessment)
      FactoryGirl.create(:passing_review, submission: passed_submission)

      failed_assessment = FactoryGirl.create(:assessment, cohort: student.cohort)
      failed_submission = FactoryGirl.create(:submission, student: student, assessment: failed_assessment)
      failed_review = FactoryGirl.create(:passing_review, submission: failed_submission)
      failing_score = FactoryGirl.create(:failing_score)
      failed_review.grades.update_all(score_id: failing_score.id)

      missed_assessment = FactoryGirl.create(:assessment, cohort: student.cohort)

      transcript = Transcript.new(student)
      expect(transcript.passing_assessments).to eq [passed_assessment]
    end
  end

  describe '#attendance_score' do
    it "calculates a score for the student's attendance record" do
      day_one = student.cohort.start_date
      day_two = day_one + 1.day
      day_three = day_two + 1.day

      student.cohort.update(end_date: day_three)

      travel_to day_one.beginning_of_day do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_two.beginning_of_day + 10.hours do
        FactoryGirl.create(:attendance_record, student: student)
      end

      travel_to day_three.end_of_day do
        transcript = Transcript.new(student)
        expect(transcript.attendance_score).to eq 0.5
      end
    end
  end


  describe '#bottom_of_percentile_range' do
    let(:transcript) { Transcript.new(student) }

    it "rounds percentage score down to the nearest 5th percentile" do
      allow(transcript).to receive(:attendance_score).and_return(0.96)
      expect(transcript.bottom_of_percentile_range).to eq 95
    end
  end
end
