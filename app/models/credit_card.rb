class CreditCard < ActiveRecord::Base
  belongs_to :user
  has_many :payments, :as => :payment_method

  validates :credit_card_uri, presence: true
  validates :user_id, presence: true

  before_create :get_last_four_string

  def fetch_balanced_account
    Balanced::Card.fetch(credit_card_uri)
  end

  def calculate_fee(amount)
    ((amount / BigDecimal.new("0.971")) + 30).to_i - amount
  end

private
  def get_last_four_string
    self.last_four_string = fetch_balanced_account.number
  end
end
