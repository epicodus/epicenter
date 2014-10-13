class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :name, presence: true
  validates :plan_id, presence: true

  belongs_to :plan
  belongs_to :cohort
  has_one :bank_account
  has_many :payments, through: :bank_account
  has_many :attendance_records

  def signed_in_today?
    attendance_records.today.exists?
  end
end
