describe PaymentCallback do
  let(:student) { FactoryBot.create(:student, :with_pt_intro_cohort, :with_credit_card) }
  let(:payment) { FactoryBot.create(:payment_with_credit_card, student: student) }

  it 'adds journal entry id to payment', :stripe_mock do
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'txnID' => '42' })
    expect(payment.reload.qbo_journal_entry_ids).to eq ['42']
  end

  it 'adds multiple txnIDs to payment', :stripe_mock do
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'txnID' => '1' })
    payment_callback = PaymentCallback.new({ 'paymentId' => payment.id.to_s, 'txnID' => '2' })
    expect(payment.reload.qbo_journal_entry_ids).to eq ['1', '2']
  end

  it 'raises error if payment not found', :stripe_mock do
    expect { PaymentCallback.new({ 'paymentId' => '99', 'txnID' => '1' }) }.to raise_error(PaymentError, "Unable to find payment 99 in response to Zapier callback.")
  end

  it 'raises error if txnID missing', :stripe_mock do
    expect { PaymentCallback.new({ 'paymentId' => payment.id.to_s }) }.to raise_error(PaymentError, "Unable to find QBO txnID for payment #{payment.id} in response to Zapier callback.")
  end
end
