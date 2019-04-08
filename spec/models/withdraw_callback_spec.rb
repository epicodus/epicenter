describe WithdrawCallback do
  context 'valid email' do
    it 'archives enrollments' do
      student = FactoryBot.create(:student)
      WithdrawCallback.new(email: student.email)
      expect(Student.first.enrollments.empty?).to eq true
    end
  end

  context 'invalid email' do
    it 'raises error' do
      expect { WithdrawCallback.new(email: 'does_not_exist@example.com') }.to raise_error(ActiveRecord::RecordNotFound, "WithdrawCallback: does_not_exist@example.com not found")
    end
  end
end
