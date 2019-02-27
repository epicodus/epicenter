describe WithdrawCallback do
  let!(:student) { FactoryBot.create(:student) }

  it 'deletes student' do
    WithdrawCallback.new(email: student.email)
    expect(Student.count).to eq 0
  end
end
