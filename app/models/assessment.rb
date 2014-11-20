class Assessment < ActiveRecord::Base
  default_scope { order(:number) }

  validates_presence_of :title
  validate :presence_of_requirements
  validates :cohort, presence: true

  has_many :requirements
  has_many :submissions
  belongs_to :cohort

  accepts_nested_attributes_for :requirements, reject_if: :attributes_blank?, allow_destroy: true

  before_create :set_number

  def submission_for(student)
    submissions.find_by(student: student)
  end

  def expectations_met_by?(student)
    submission_for(student).try(:meets_expectations?)
  end

private

  def set_number
    self.number = cohort.assessments.pluck(:number).last.to_i + 1
  end

  def presence_of_requirements
    if requirements.size < 1
      errors.add(:requirements, 'must be present.')
    end
  end

  def attributes_blank?(attributes)
    attributes['content'].blank?
  end
end
