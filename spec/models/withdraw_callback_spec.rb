describe WithdrawCallback do
  context 'valid email' do
    it 'deletes student' do
      student = FactoryBot.create(:student)
      WithdrawCallback.new(email: student.email)
      expect(Student.count).to eq 0
    end
  end

  context 'invalid email' do
    it 'raises error' do
      expect { WithdrawCallback.new(email: 'does_not_exist@example.com') }.to raise_error(ActiveRecord::RecordNotFound, "WithdrawCallback: does_not_exist@example.com not found")
    end
  end
end
