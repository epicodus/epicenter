class InternshipAssignment < ApplicationRecord
  belongs_to :student
  belongs_to :internship
  belongs_to :course

  validates :student, presence: true
  validates :internship, presence: true
  validates :course, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  after_create :update_crm

  scope :for_internship, ->(internship) { where(internship_id: internship.id) }

  private

  def update_crm
    student.crm_lead.update({ Rails.application.config.x.crm_fields['INTERNSHIP_COMPANY'] => internship.name })
  end
end
