describe PaymentCallback do
  let(:student) { FactoryBot.create(:student_with_credit_card) }
  let(:payment) { FactoryBot.create(:payment_with_credit_card, student: student) }

  it 'adds doc_number to payment', :stripe_mock do
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'docNumber' => '1A' })
    expect(payment.reload.qbo_doc_numbers).to eq ['1A']
  end

  it 'adds multiple doc_numbers to payment', :stripe_mock do
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'docNumber' => '1A' })
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'docNumber' => '2A' })
    expect(payment.reload.qbo_doc_numbers).to eq ['1A', '2A']
  end

  it 'raises error if payment not found', :stripe_mock do
    expect { PaymentCallback.new({ 'paymentId' => '99', 'docNumber' => '1A' }) }.to raise_error(PaymentError, "Unable to find payment 99 in response to Zapier callback.")
  end

  it 'raises error if doc_number missing', :stripe_mock do
    expect { PaymentCallback.new({ 'paymentId' => payment.id.to_s }) }.to raise_error(PaymentError, "Unable to find doc_number for payment #{payment.id} in response to Zapier callback.")
  end
end
