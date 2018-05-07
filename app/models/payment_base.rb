class PaymentBase < ApplicationRecord
  self.table_name = "payments"
  include ActionView::Helpers::NumberHelper  #for number_to_currency

  belongs_to :student
  validates :category, presence: true, on: :create

  before_create :check_amount
  before_create :set_offline_status, if: ->(payment) { payment.offline? }
  before_create :set_category, if: ->(payment) { payment.category == 'tuition' } # must run before set_description
  before_create :set_description

  after_create :update_crm
  after_create :send_webhook, if: ->(payment) { payment.status == 'succeeded' || payment.status == 'offline' }

  scope :order_by_latest, -> { order('created_at DESC') }
  scope :without_failed, -> { where.not(status: 'failed') }
  scope :without_offline, -> { where.not(status: 'offline') }

private
  def set_offline_status
    binding.pry
    self.status = 'offline'
  end

  def send_webhook
    binding.pry
    WebhookPayment.new({ event_name: type.downcase + '_' + status, payment: self })
  end
end
