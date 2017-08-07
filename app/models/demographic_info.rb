class DemographicInfo
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  GENDER_OPTIONS = ["Female", "Male", "Non-binary", "Transgender"]
  RACE_OPTIONS = ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"]
  EDUCATION_OPTIONS = ["High school diploma or equivalent", "Postsecondary certificate", "Some college, no degree", "Associate's degree", "Bachelor's degree", "Master's degree or higher"]
  VETERAN_OPTIONS = ["Yes", "No"]

  before_validation :nil_if_blank

  validates_numericality_of :age, greater_than: 0, allow_nil: true
  validates_numericality_of :salary, greater_than_or_equal_to: 0, allow_nil: true
  validates_length_of :job, maximum: 35, allow_nil: true
  validates_length_of :pronouns, maximum: 70, allow_nil: true
  validates_inclusion_of :education, in: EDUCATION_OPTIONS, allow_nil: true
  validates_inclusion_of :veteran, in: VETERAN_OPTIONS, allow_nil: true
  validate :check_array_genders, if: ->(demographic_info) { demographic_info.genders.present? }
  validate :check_array_races, if: ->(demographic_info) { demographic_info.races.present? }

  attr_accessor :age, :job, :salary, :education, :veteran, :genders, :races, :pronouns

  def initialize(student = nil, attributes = {})
    @student = student
    @age = attributes[:age]
    @salary = attributes[:salary]
    @job = attributes[:job]
    @education = attributes[:education]
    @veteran = attributes[:veteran]
    @genders = attributes[:genders]
    @races = attributes[:races]
    @pronouns = attributes[:pronouns]
  end

  def save
    if valid?
      fields = {}
      fields['custom.Gender'] = @genders.join(", ") if @genders
      fields['custom.Pronouns'] = @pronouns
      fields['custom.Age'] = @age
      fields['custom.Education'] = @education
      fields['custom.Previous job'] = @job
      fields['custom.Previous salary'] = @salary
      fields['custom.Race'] = @races.join(", ") if @races
      fields['custom.veteran'] = @veteran
      fields = fields.compact
      @student.update_close_io(fields)
    end
  end

private

  def nil_if_blank
    @age = @age.blank? ? nil : @age.to_i
    @salary = @salary.blank? ? nil : @salary.to_i
    @job = nil if @job.blank?
    @pronouns = nil if @pronouns.blank?
    @education = nil if @education.blank?
  end

  def check_array_genders
    @genders.each do |gender|
      unless GENDER_OPTIONS.include?(gender)
        errors.add(:genders, "#{gender} not found in list.")
      end
    end
  end

  def check_array_races
    @races.each do |race|
      unless RACE_OPTIONS.include?(race)
        errors.add(:races, "#{race} not found in list.")
      end
    end
  end
end
