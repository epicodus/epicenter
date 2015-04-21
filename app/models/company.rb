class Company < ActiveRecord::Base
  has_many :internships

  validates :name, presence: true, uniqueness: true
  validates :contact_phone, presence: true
  validates :contact_email, presence: true
  validates :website, presence: true

  default_scope { order('name') }

  before_save :fix_url

private

  def fix_url
    self.website = self.website.rstrip.lstrip
    if self.website
      begin
        uri = URI.parse(self.website)
        unless uri.scheme
            self.website = URI::HTTP.build({ host: self.website }).to_s
        end
      rescue URI::InvalidURIError
        errors.add(:website, "is invalid.")
        false
      end
    end
  end
end
