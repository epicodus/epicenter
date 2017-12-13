class DemographicInfo
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  GENDER_OPTIONS = ["Female", "Male", "Non-binary", "Transgender", "Other"]
  RACE_OPTIONS = ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"]
  EDUCATION_OPTIONS = ["less than high school diploma", "GED", "high school diploma", "some post high school but no degree or certificate", "certificate (less than 2 years)", "associate's degree", "bachelor's degree", "master's degree", "doctoral degree or above", "other"]
  SHIRT_OPTIONS = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]

  before_validation :nil_if_blank

  validates_presence_of :address, :city, :state, :zip, :country, :birth_date
  validates_length_of :address, maximum: 200
  validates_length_of :city, maximum: 100
  validates_length_of :state, maximum: 100
  validates_length_of :zip, maximum: 10
  validates_length_of :country, maximum: 100
  validate :validate_date_format, unless: ->(demographic_info) { demographic_info.birth_date.nil? }
  validates_inclusion_of :disability, in: ["Yes", "No"]
  validates_inclusion_of :veteran, in: ["Yes", "No"]
  validates_inclusion_of :cs_degree, in: ["Yes", "No"]
  validates_inclusion_of :education, in: EDUCATION_OPTIONS
  validates_inclusion_of :shirt, in: SHIRT_OPTIONS
  validates_numericality_of :salary, greater_than_or_equal_to: 0, allow_nil: true
  validates_length_of :job, maximum: 35, allow_nil: true
  validate :check_array_genders, if: ->(demographic_info) { demographic_info.genders.present? }
  validate :check_array_races, if: ->(demographic_info) { demographic_info.races.present? }

  attr_accessor :student, :birth_date, :disability, :veteran, :education, :cs_degree, :address, :city, :state, :zip, :country, :shirt, :job, :salary, :genders, :races

  def initialize(student = nil, attributes = {})
    @student = student
    @birth_date = attributes[:birth_date]
    @disability = attributes[:veteran]
    @veteran = attributes[:veteran]
    @education = attributes[:education]
    @cs_degree = attributes[:cs_degree]
    @address = attributes[:address]
    @city = attributes[:city]
    @state = attributes[:state]
    @zip = attributes[:zip]
    @country = attributes[:country]
    @shirt = attributes[:shirt]
    @salary = attributes[:salary]
    @job = attributes[:job]
    @genders = attributes[:genders]
    @races = attributes[:races]
  end

  def save
    if valid?
      fields = {}
      fields['addresses'] = ["label": "mailing", "address_1": @address, "city": @city, "state": @state, "zipcode": @zip, "country": @country]
      fields['custom.Demographics - Birth date'] = @birth_date
      fields['custom.Demographics - Disability'] = @disability
      fields['custom.Demographics - Veteran'] = @veteran
      fields['custom.Demographics - Education'] = @education
      fields['custom.Demographics - CS Degree'] = @cs_degree
      fields['custom.Demographics - Previous job'] = @job
      fields['custom.Demographics - Previous salary'] = @salary
      fields['custom.Demographics - Shirt size'] = @shirt
      fields['custom.Demographics - Gender'] = @genders.join(", ") if @genders
      fields['custom.Demographics - Race'] = @races.join(", ") if @races
      fields = fields.compact
      @student.crm_lead.update(fields)
      true
    end
  end

private

  def nil_if_blank
    @salary = @salary.blank? ? nil : @salary.to_i
    @job = nil if @job.blank?
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

  def validate_date_format
    begin
      if @birth_date.match?(/\d{2}\/\d{2}\/\d{4}/)
        date_parts = @birth_date.split('/')
        @birth_date = "#{date_parts[2]}-#{date_parts[0]}-#{date_parts[1]}"
      end
      unless @birth_date.match?(/\d{4}-\d{2}-\d{2}/) && Date.parse(@birth_date) < Date.today - 10.years
        errors.add(:birth_date, "invalid.")
      end
    rescue ArgumentError => e
      errors.add(:birth_date, "unrecognized format.")
    end
  end
end
