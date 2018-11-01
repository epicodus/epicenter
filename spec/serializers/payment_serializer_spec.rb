describe PaymentSerializer, :stripe_mock, :stub_mailgun, :vcr do

  it 'includes the expected attributes for a payment' do
    student = FactoryBot.create(:student_with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:refund_amount]).to eq nil
    expect(serialized_payment[:email]).to eq student.email
    expect(serialized_payment[:office]).to eq student.office.short_name
    expect(serialized_payment[:start_date]).to eq student.course.start_date.to_s
    expect(serialized_payment[:end_date]).to eq student.course.end_date.to_s
  end

  it 'includes the expected attributes for a refund' do
    student = FactoryBot.create(:student_with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: Date.today)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:refund_amount]).to eq 10000
    expect(serialized_payment[:email]).to eq student.email
    expect(serialized_payment[:office]).to eq student.office.short_name
    expect(serialized_payment[:start_date]).to eq Date.today.to_s
    expect(serialized_payment[:end_date]).to eq student.course.end_date.to_s
  end
end
