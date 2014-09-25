class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  validates :name, presence: true
  devise :database_authenticatable, :registerable, :omniauthable,
         :recoverable, :rememberable, :trackable, :validatable

  has_one :bank_account
  has_many :payments, through: :bank_account
  has_many :submissions

  scope :teachers, -> { where(admin: true) }
  scope :students, -> { where(admin: false) }

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_create do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.nickname
      user.email = auth.info.email
    end
  end

  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  def assessment_completion
     (self.submissions.assessed.select(:assessment_id).distinct.count.to_f / Assessment.all.count.to_f * 100).floor
  end

  def grade_four
    grade = 0
    self.submissions.each { |sub| grade += sub.grades.where(score: 4).count }
    grade
  end

  def grade_three
    grade = 0
    self.submissions.each { |sub| grade += sub.grades.where(score: 3).count }
    grade
  end

  def grade_two
    grade = 0
    self.submissions.each { |sub| grade += sub.grades.where(score: 2).count }
    grade
  end

  def grade_one
    grade = 0
    self.submissions.each { |sub| grade += sub.grades.where(score: 1).count }
    grade
  end

  def last_assessment
    self.submissions.map { |submission| submission.assessment }.sort_by {|assessment| assessment.section_number }.last
  end

  def password_required?
    super && provider.blank?
  end
end
