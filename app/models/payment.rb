class Payment < ApplicationRecord
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method, optional: true
  belongs_to :cohort, optional: true
  belongs_to :linked_payment, class_name: :Payment, optional: true

  validates :amount, presence: true
  validates :payment_method, presence: true, unless: ->(payment) { payment.offline? }
  validates :category, presence: true, on: :create

  before_save :set_cohort, if: ->(payment) { payment.refund_amount? }
  before_save :check_refund_date, if: ->(payment) { payment.refund_date? && payment.cohort_id? }
  before_create :check_amount
  before_create :set_category, if: ->(payment) { payment.category == 'tuition' }
  before_create :set_description
  before_create :make_payment, unless: ->(payment) { payment.offline? }
  before_create :set_offline_status, if: ->(payment) { payment.offline? }
  before_update :issue_refund, if: ->(payment) { payment.refund_amount? && !payment.offline? && !payment.refund_issued? }

  after_save :update_crm
  after_create :send_webhook, if: ->(payment) { payment.category != 'keycard' && (payment.status == 'succeeded' || payment.status == 'offline') }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }
  scope :offline, -> { where(status: 'offline') }
  scope :online, -> { where.not(status: 'offline') }

  def total_amount
    amount + fee
  end

  def full_description
    [created_at.try(:strftime, "%b %-d %Y"), number_to_currency(total_amount / 100.00), status.try(:capitalize), payment_method.try(:description), category, notes].compact.join(' - ')
  end

private

  def update_crm
    amount_paid = student.total_paid / 100
    student.crm_lead.update(Rails.application.config.x.crm_fields['AMOUNT_PAID'] => amount_paid)
    if student.crm_lead.status == "Applicant - Accepted"
      student.crm_lead.update({ status: "Enrolled" })
    end
    if refund_amount?
      student.crm_lead.update(note: "PAYMENT REFUND #{number_to_currency(refund_amount / 100.00)}: #{refund_notes}")
    elsif created_at == updated_at # don't duplicate note when updating payment status
      student.crm_lead.update(note: "PAYMENT #{number_to_currency(amount / 100.00)}: #{notes}")
    end
  end

  def set_offline_status
    self.status = 'offline'
  end

  def issue_refund
    begin
      charge_id = Stripe::BalanceTransaction.retrieve(stripe_transaction).source
      refund = Stripe::Refund.create(charge: charge_id, amount: refund_amount)
      self.refund_issued = true
      WebhookPayment.new({ event_name: 'refund', payment: self })
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def set_category
    self.category = refund_amount.present? ? 'refund' : 'upfront'
  end

  def set_cohort
    self.cohort = cohort || linked_payment.cohort
  end

  def set_description
    if category == 'keycard'
      self.description = 'keycard'
    else
      start_date = refund_date || (student.courses & cohort.courses).first.start_date
      self.description = "#{start_date.to_s}-#{cohort.end_date.to_s} | #{cohort.description}"
    end
  end

  def make_payment
    customer = student.stripe_customer
    self.fee = payment_method.calculate_fee(amount)
    begin
      charge = Stripe::Charge.create(amount: total_amount, currency: 'usd', customer: customer.id, source: payment_method.stripe_id, description: description, receipt_email: student.email)
      self.status = payment_method.starting_status
      self.stripe_transaction = charge.balance_transaction
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      throw :abort
    end
  end

  def check_amount
    if amount < 0 || amount > ENV['MAX_PAYMENT_AMOUNT'].to_i
      errors.add(:amount, 'is invalid.')
      throw :abort
    end
  end

  def check_refund_date
    if refund_date < cohort.start_date
      self.refund_date = cohort.start_date
    elsif refund_date > cohort.end_date
      errors.add(:refund_date, "cannot be later than #{cohort.description} cohort end date.")
      throw :abort
    end
  end

  def send_webhook
    if refund_amount.present?
      WebhookPayment.new({ event_name: "refund_offline", payment: self })
    elsif status == 'offline'
      WebhookPayment.new({ event_name: "payment_offline", payment: self })
    else
      WebhookPayment.new({ event_name: "payment", payment: self })
    end
  end
end
