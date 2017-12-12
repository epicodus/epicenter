describe PaymentSerializer do
  let(:student) { FactoryBot.create(:user_with_credit_card) }
  let(:payment) { FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00) }

  it 'includes the expected attributes' do
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:email]).to eq student.email
  end
end
