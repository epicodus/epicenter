class Subscription < ActiveRecord::Base
  scope :active, -> { where(status: 'active') }

  attr_accessor :first_deposit, :second_deposit
  validates_presence_of :account_uri

  belongs_to :user
  has_many :payments

  before_create :create_verification
  before_create :activate_subscription

  after_update :create_payment, if: :confirming_account?

  def create_verification
    Verification.new(self)
  end

  def self.billable_today
    active.select do |subscription|
      subscription.payments.last.created_at < 1.month.ago if !subscription.payments.empty?
    end
  end

  def self.bill_subscriptions
    billable_today.each do |subscription|
      subscription.send(:create_payment)
    end
  end

private

  def activate_subscription
    self.status = "active"
  end

  def create_payment
    self.payments.create(amount: 65000)
  end

  def confirming_account?
    first_deposit && second_deposit
  end
end
