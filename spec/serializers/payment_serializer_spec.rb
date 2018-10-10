describe PaymentSerializer, :stripe_mock, :stub_mailgun, :vcr do

  it 'includes the expected attributes for a payment' do
    student = FactoryBot.create(:user_with_credit_card)
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:amount]).to eq 60000
    expect(serialized_payment[:email]).to eq student.email
    expect(serialized_payment[:office]).to eq student.office.short_name
  end

  it 'includes the expected attributes for a refund' do
    cohort = FactoryBot.create(:intro_only_cohort)
    student = FactoryBot.create(:user_with_credit_card, cohort: cohort, ending_cohort: cohort, courses: [cohort.courses.first])
    payment = FactoryBot.create(:payment_with_credit_card, student: student, amount: 600_00, refund_amount: 100_00, refund_date: student.course.start_date)
    serialized_payment = PaymentSerializer.new(payment).as_json
    expect(serialized_payment[:refund_amount]).to eq payment.refund_amount
    expect(serialized_payment[:refund_date]).to eq payment.refund_date.to_s
    expect(serialized_payment[:end_date]).to eq student.ending_cohort.end_date.to_s
  end
end
