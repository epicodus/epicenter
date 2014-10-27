class Payment < ActiveRecord::Base
  belongs_to :user
  belongs_to :payment_method, polymorphic: true

  validates_presence_of :amount, :user_id
  validates :payment_method, presence: true

  before_create :make_payment

  scope :order_by_latest, -> { order('created_at DESC') }

private
  def send_payment_receipt
    Mailgun::Client.new(ENV['MAILGUN_API_KEY']).send_message(
      "epicodus.com",
      { :from => "michael@epicodus.com",
        :to => user.email,
        :bcc => "michael@epicodus.com",
        :subject => "Epicodus tuition payment receipt",
        :text => "Hi #{user.name}. This is to confirm your payment of #{amount} for Epicodus tuition. If you have any questions, reply to this email. Thanks!" }
    )
  end

  def make_payment
    payment_method_to_charge = user.primary_payment_method
    self.amount = payment_method_to_charge.calculate_charge(amount)
    begin
      debit = payment_method_to_charge.fetch_balanced_account.debit(
        :amount => amount,
        :appears_on_statement_as => 'Epicodus tuition'
      )
      self.payment_uri = debit.href
      send_payment_receipt
    rescue => exception
      errors.add(:base, exception.description)
      false
    end
  end
end
