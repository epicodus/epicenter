class Internship < ActiveRecord::Base
  belongs_to :cohort
  belongs_to :company
  has_many :ratings
  has_many :students, through: :ratings

  validates :ideal_intern, presence: true
  validates :description, presence: true
  validates :cohort_id, presence: true
  validates :company_id, presence: true, uniqueness: { scope: :cohort_id }

  delegate :name, to: :company, prefix: :company
end
