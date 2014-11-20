class Payment < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  belongs_to :payment_method

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true
  validate :ensure_payment_isnt_over_balance

  after_update :send_payment_failure_notice, if: lambda {|payment| payment.status == "failed" }
  before_create :make_payment, :send_payment_receipt
  after_validation :ensure_payment_isnt_over_balance, :on => :create
  after_create :check_if_paid_up

  scope :order_by_latest, -> { order('created_at DESC') }

  def total_amount
    amount + fee
  end

private
  def ensure_payment_isnt_over_balance
    if student && student.payments.sum(:amount) + amount.to_i > student.plan.total_amount
      errors.add(:amount, 'exceeds the outstanding balance.')
    end
  end

  def check_if_paid_up
    student.update(recurring_active: false) if student.payments.sum(:amount) == student.plan.total_amount
  end

  def send_payment_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => "michael@epicodus.com",
        :to => student.email,
        :bcc => "michael@epicodus.com",
        :subject => "Epicodus tuition payment receipt",
        :text => "Hi #{student.name}. This is to confirm your payment of #{number_to_currency(total_amount / 100.00)} for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def send_payment_failure_notice
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => "michael@epicodus.com",
        :to => student.email,
        :bcc => "michael@epicodus.com",
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
end
