class Payment < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true, unless: ->(payment) { payment.offline? }

  before_create :check_amount
  before_create :make_payment, :send_payment_receipt, unless: ->(payment) { payment.offline? }
  before_create :set_offline_status, if: ->(payment) { payment.offline? }
  after_create :add_to_less_accounting
  after_save :update_close_io, unless: ->(payment) { payment.refund_amount? || payment.offline? }
  before_update :issue_refund, if: ->(payment) { payment.refund_amount? && !payment.offline? }
  after_update :send_refund_receipt, if: ->(payment) { payment.refund_amount? && !payment.offline? }
  after_update :send_payment_failure_notice, if: ->(payment) { payment.status == "failed" }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }

  def total_amount
    amount + fee
  end

private

  def determine_payment_receipt_email_body
    email_body = "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. "
    if student.plan.standard? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan and that we will be charging you the remaining $1,080 on the first day of class. I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    elsif student.plan.loan? && student.payments.count == 0
      email_body += "I am going over the payments for your class and just wanted to confirm that you have chosen the #{student.plan.name} plan. Since you are in the process of obtaining a loan for program tuition, would you please let me know (which loan company, date you applied, etc.)? I want to be sure we know your intentions and don't mistakenly charge you. Thanks so much!"
    else
      email_body += "Thanks so much!"
    end
  end

  def set_offline_status
    self.status = 'offline'
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

  def add_to_less_accounting
    RestClient::Request.execute(
      url: "https://epicodus.lessaccounting.com/expenses.json?api_key=#{ENV['LESS_ACCOUNTING_API_KEY']}&expense[title]=#{student.name}&expense[amount]=#{amount / 100}&expense[paid_date]=#{Date.today.strftime('%Y-%m-%d')}&expense[bank_account_id]=120215&expense[expense_category_id]=1496063",
      method: :post,
      user: ENV['LESS_ACCOUNTING_EMAIL'],
      password: ENV['LESS_ACCOUNTING_PASSWORD']
    )
  end

  def update_close_io
    amount_paid = { 'custom.Amount paid': student.total_paid / 100 }
    if student.close_io_lead_exists?
      if student.payments.count == 1
        student.update_close_io({ status: "Enrolled" }.merge(amount_paid))
      else
        student.update_close_io(amount_paid)
      end
    end
  end

  def send_payment_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :bcc => ENV['FROM_EMAIL_PAYMENT'],
        :subject => "Epicodus tuition payment receipt",
        :text => determine_payment_receipt_email_body }
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
