class InternshipAssignment < ApplicationRecord
  belongs_to :student
  belongs_to :internship
  belongs_to :course

  validates :student, presence: true
  validates :internship, presence: true
  validates :course, presence: true
  validates :student_id, uniqueness: { scope: :course_id }

  after_create { update_crm(:create) }
  before_destroy { update_crm(:destroy) }

  scope :for_internship, ->(internship) { where(internship_id: internship.id) }

  private

  def update_crm(action)
    updated_value = action == :create ? internship.name : nil
    student.crm_lead.update({ Rails.application.config.x.crm_fields['INTERNSHIP_COMPANY'] => updated_value })
  end
end
