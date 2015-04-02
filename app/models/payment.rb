class Payment < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true
  validate :ensure_payment_isnt_over_balance, on: :create

  before_create :make_payment, :send_payment_receipt
  after_create :check_if_paid_up
  after_update :send_payment_failure_notice, if: ->(payment) { payment.status == "failed" }
  after_update :switch_recurring_off, if: ->(payment) { payment.status == "failed" }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }

  def total_amount
    amount + fee
  end

private
  def ensure_payment_isnt_over_balance
    if student && student.total_paid + amount.to_i > student.plan.total_amount
      errors.add(:amount, 'exceeds the outstanding balance.')
    end
  end

  def check_if_paid_up
    if student.total_paid == student.plan.total_amount
      student.update(recurring_active: false)
    end
  end

  def send_payment_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :subject => "Epicodus tuition payment receipt",
        :text => "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def send_payment_failure_notice
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => ENV['FROM_EMAIL_PAYMENT'],
        :to => student.email,
        :subject => "Epicodus payment failure notice",
        :text => "Hi #{student.name}. This is to notify you that a recent payment you made for Epicodus tuition has failed. Please reply to this email so we can sort it out together. Thanks!" }
    )
  end

  def make_payment
    self.fee = payment_method.calculate_fee(amount)
    begin
      debit = payment_method.fetch_balanced_account.debit(
        :amount => total_amount,
        :appears_on_statement_as => 'Epicodus tuition'
      )
      self.status = payment_method.starting_status
      self.payment_uri = debit.href
    rescue Balanced::Error => exception
      errors.add(:base, exception.description)
      false
    end
  end

  def switch_recurring_off
    student.update(recurring_active: false)
  end
end
