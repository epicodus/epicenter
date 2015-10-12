class Internship < ActiveRecord::Base
  belongs_to :course
  belongs_to :company
  has_many :ratings
  has_many :students, through: :ratings

  validates :ideal_intern, presence: true
  validates :description, presence: true
  validates :course_id, presence: true
  validates :company_id, presence: true, uniqueness: { scope: :course_id }

  delegate :name, to: :company, prefix: :company

  scope :by_company_name, -> { joins(:company).order("name") }
end
