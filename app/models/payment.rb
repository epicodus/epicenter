class Payment < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true, unless: ->(payment) { payment.offline? }

  before_create :check_amount
  before_create :make_payment, :send_payment_receipt, unless: ->(payment) { payment.offline? }
  after_create :set_offline_status, if: ->(payment) { payment.offline? }
  after_save :update_close_io, unless: ->(payment) { payment.refund_amount? || payment.offline? }
  before_update :issue_refund, if: ->(payment) { payment.refund_amount? }
  after_update :send_refund_receipt, if: ->(payment) { payment.refund_amount? }
  after_update :send_payment_failure_notice, if: ->(payment) { payment.status == "failed" }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }

  def total_amount
    amount + fee
  end

private

  def set_offline_status
    self.update(status: 'offline')
  end

  def issue_refund
    begin
      charge_id = Stripe::BalanceTransaction.retrieve(stripe_transaction).source
      refund = Stripe::Refund.create(charge: charge_id, amount: refund_amount)
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def update_close_io
    amount_paid = { 'custom.Amount paid': student.total_paid / 100 }
    if student.payments.count == 1
      student.update_close_io({ status: "Enrolled" }.merge(amount_paid))
    else
      student.update_close_io(amount_paid)
    end
  end

  def send_payment_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition payment receipt",
        :text => "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def send_payment_failure_notice
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus payment failure notice",
        :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
    )
  end

  def make_payment
    customer = student.stripe_customer
    self.fee = payment_method.calculate_fee(amount)
    begin
      charge = Stripe::Charge.create(amount: total_amount, currency: 'usd', customer: customer.id, source: payment_method.stripe_id)
      self.status = payment_method.starting_status
      self.stripe_transaction = charge.balance_transaction
    rescue Stripe::StripeError => exception
      errors.add(:base, exception.message)
      false
    end
  end

  def send_refund_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition refund receipt",
        :text => "Hi #{student.name}. This is to confirm your refund of #{number_to_currency(refund_amount / 100.00)} from your Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def check_amount
    if amount >= 5000_00
      errors.add(:amount, 'cannot be greater than $5,000.')
      false
    end
  end
end
