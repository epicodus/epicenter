describe DailySubmission do
  it { should belong_to :student }
  it { should validate_presence_of :link }

  describe "one submission per student per day" do
    it 'allows one submission per student per day' do
      student = FactoryBot.create(:student)
      daily_submission = DailySubmission.create(student: student, link: 'first submission')
      expect(DailySubmission.count).to eq 1
    end

    it 'allows submissions from two different students on the same day' do
      student = FactoryBot.create(:student)
      student_2 = FactoryBot.create(:student)
      daily_submission = DailySubmission.create(student: student, link: 'first submission')
      daily_submission_2 = DailySubmission.create(student: student_2, link: 'first submission')
      expect(DailySubmission.count).to eq 2
    end

    it 'replaces first submission with second from same student on same day' do
      student = FactoryBot.create(:student)
      daily_submission = DailySubmission.create(student: student, link: 'first submission')
      daily_submission_2 = DailySubmission.create(student: student, link: 'second submission')
      expect(DailySubmission.count).to eq 1
      expect(DailySubmission.first.link).to eq 'second submission'
    end
  end
end
