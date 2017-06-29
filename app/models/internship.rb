class Internship < ApplicationRecord
  belongs_to :company
  has_many :ratings
  has_many :course_internships
  has_many :courses, through: :course_internships
  has_many :students, through: :ratings
  has_many :internship_tracks
  has_many :interview_assignments
  has_many :tracks, through: :internship_tracks
  has_many :internship_assignments

  validates :name, presence: true
  validates :website, presence: true
  validates :ideal_intern, presence: true
  validates :description, presence: true
  validates :courses, presence: true
  validates :number_of_students, presence: true
  validates :tracks, presence: true

  before_validation :fix_url
  before_save :check_number_of_students

  def self.assigned_as_interview_for(student)
    includes(:interview_assignments).where(interview_assignments: { student_id: student.id }).order(:name)
  end

  def self.not_assigned_as_interview_for(student)
    all - includes(:interview_assignments).where(interview_assignments: { student_id: student.id })
  end

  def other_internship_courses
    Course.internship_courses.where(active: true).where.not(id: courses.map(&:id))
  end

  def tracks_ordered_by_description
    tracks.order(:description).map(&:description).join(', ')
  end

private

  def fix_url
    self.website = self.website.try(:strip)
    if self.website
      begin
        uri = URI.parse(self.website)
        unless uri.scheme
          self.website = URI::HTTP.build({ host: self.website }).to_s
        end
      rescue URI::InvalidURIError, URI::InvalidComponentError
        errors.add(:website, "is invalid.")
        throw :abort
      end
    end
  end

  def check_number_of_students
    allowed_numbers = [2,4,6]
    if allowed_numbers.exclude?(number_of_students)
      errors.add(:number_of_students, 'must be 2, 4, or 6.')
      throw :abort
    end
  end
end
