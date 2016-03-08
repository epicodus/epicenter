class Internship < ActiveRecord::Base
  default_scope { order('name') }

  belongs_to :company
  has_many :ratings
  has_many :course_internships
  has_many :courses, through: :course_internships
  has_many :students, through: :ratings

  validates :name, presence: true
  validates :website, presence: true
  validates :ideal_intern, presence: true
  validates :description, presence: true
  validates :courses, presence: true

  before_save :fix_url

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
        false
      end
    end
  end
end
