class Payment < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper

  belongs_to :student
  belongs_to :payment_method

  validates :amount, presence: true
  validates :student_id, presence: true
  validates :payment_method, presence: true
  validate :ensure_payment_isnt_over_balance

  before_create :make_payment
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

  def make_payment
    self.fee = payment_method.calculate_fee(amount)
    begin
      debit = payment_method.fetch_balanced_account.debit(
        :amount => total_amount,
        :appears_on_statement_as => 'Epicodus tuition'
      )
      self.payment_uri = debit.href
      send_payment_receipt
    rescue Balanced::Error => exception
      errors.add(:base, exception.description)
      false
    end
  end
end
