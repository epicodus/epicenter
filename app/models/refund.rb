class Refund < PaymentBase
  belongs_to :original_payment, class_name: 'Payment', foreign_key: 'original_payment_id'

  validates :refund_amount, presence: true
  validates :refund_date, presence: true

  before_create :issue_refund, unless: ->(refund) { refund.offline? || refund.refund_issued? }

private

# ------------------ BEFORE --------------------

  def check_amount
    if refund_amount <= 0 || refund_amount > original_payment.total_amount - original_payment.total_refunded
      errors.add(:refund_amount, 'must be positive and less than original payment total + fees.')
      throw :abort
    end
  end

  def set_category
    category = 'refund'
  end

  def set_description
    self.description = original_payment.description # NOTE: should improve this later, but this is how it currently works
  end


  # ------------------ ACTION --------------------

  def issue_refund
    begin
      charge_id = Stripe::BalanceTransaction.retrieve(original_payment.stripe_transaction).source
      refund = Stripe::Refund.create(charge: charge_id, amount: refund_amount)
      self.refund_issued = true
      send_refund_receipt
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def send_refund_receipt
    EmailJob.perform_later(
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition refund receipt",
        :text => "Hi #{student.name}. This is to confirm your refund of #{number_to_currency(refund_amount / 100.00)} from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end


  # ------------------ AFTER --------------------

  def update_crm
    amount_paid = student.total_paid / 100
    student.crm_lead.update('custom.Amount paid': amount_paid)
    student.crm_lead.update(note: "PAYMENT REFUND #{number_to_currency(refund_amount / 100.00)}: #{refund_notes}")
  end
end
