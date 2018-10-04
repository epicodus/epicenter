class DemographicInfo
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  GENDER_OPTIONS = ["Female", "Male", "Non-binary", "Transgender", "Other"]
  RACE_OPTIONS = ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"]
  EDUCATION_OPTIONS = ["less than high school diploma", "GED", "high school diploma", "some post high school but no degree or certificate", "certificate (less than 2 years)", "associate's degree", "bachelor's degree", "master's degree", "doctoral degree or above", "other"]
  SHIRT_OPTIONS = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]
  AFTER_OPTIONS = ["Look for a full-time job that requires the skills I'll learn at Epicodus", "Look for a part-time job that requires the skills I'll learn at Epicodus", "Return to my previous employer", "Start a business or become a self-employed contractor", "Not look for work in the U.S., because I don't have a U.S. work visa", "Continue education at another institution", "Something else; I'm just taking Epicodus for self-enrichment and don't plan to work in-field", "Other (please explain)"]

  # required fields
  validates_presence_of :address, :city, :state, :zip, :country, :birth_date
  validates_length_of :address, maximum: 200
  validates_length_of :city, maximum: 100
  validates_length_of :state, maximum: 100
  validates_length_of :zip, maximum: 10
  validates_length_of :country, maximum: 100
  validates_inclusion_of :disability, in: ['Yes', 'No']
  validates_inclusion_of :veteran, in: ['Yes', 'No']
  validates_inclusion_of :cs_degree, in: ['Yes', 'No']
  validate :validate_birth_date, unless:->(obj) { obj.birth_date.nil? }
  validate :validate_education
  validate :validate_shirt
  validate :validate_after_graduation
  validates_length_of :after_graduation_explanation, maximum: 255, allow_nil: true # only required if @after_graduation == 'Other (please explain)'
  validates_numericality_of :ssn, less_than: 1000000000, allow_nil: true

  # optional fields
  validate :validate_array_genders, if: ->(obj) { obj.genders.present? }
  validate :validate_array_races, if: ->(obj) { obj.races.present? }
  validates_length_of :job, maximum: 35, allow_nil: true
  validates_numericality_of :salary, greater_than_or_equal_to: 0, allow_nil: true

  attr_accessor :student, :birth_date, :disability, :veteran, :education, :cs_degree, :address, :city, :state, :zip, :country, :shirt, :job, :salary, :genders, :races, :after_graduation, :after_graduation_explanation, :time_off, :ssn

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
    @salary = attributes[:salary].to_i if attributes[:salary].present?
    @job = attributes[:job] if attributes[:job].present?
    @genders = attributes[:genders]
    @races = attributes[:races]
    @after_graduation = attributes[:after_graduation]
    @time_off = attributes[:time_off] if [AFTER_OPTIONS[0], AFTER_OPTIONS[1]].include? @after_graduation
    @after_graduation_explanation = 'Other: ' + attributes[:after_graduation_explanation] if @after_graduation == AFTER_OPTIONS[-1] && attributes[:after_graduation_explanation].present?
    @ssn = attributes[:ssn].gsub(/\D/, '').to_i if attributes[:ssn].present?
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
      fields['custom.Demographics - After graduation plan'] = @after_graduation_explanation || @after_graduation
      fields['custom.Demographics - Time off planned'] = @time_off
      fields = fields.compact
      @student.crm_lead.update(fields)
      @student.crm_lead.update({ 'custom.Demographics - Encrypted SSN': encrypted_ssn }) if ssn
      true
    end
  end

private

  def encrypted_ssn
    public_key = OpenSSL::PKey::RSA.new(ENV['PUBLIC_KEY'])
    Base64.encode64(public_key.public_encrypt(ssn.to_s))
  end

  def validate_array_genders
    @genders.each do |gender|
      errors.add(:genders, "#{gender} not found in list.") unless GENDER_OPTIONS.include?(gender)
    end
  end

  def validate_array_races
    @races.each do |race|
      errors.add(:races, "#{race} not found in list.") unless RACE_OPTIONS.include?(race)
    end
  end

  def validate_birth_date
    begin
      if @birth_date.match?(/\d{2}\/\d{2}\/\d{4}/)
        date_parts = @birth_date.split('/')
        @birth_date = "#{date_parts[2]}-#{date_parts[0]}-#{date_parts[1]}"
      end
      unless @birth_date.match?(/\d{4}-\d{2}-\d{2}/) && Date.parse(@birth_date) < Date.today - 10.years
        errors.add(:birth_date, "is not recognized.")
      end
    rescue ArgumentError => e
      errors.add(:birth_date, "unrecognized format.")
    end
  end

  def validate_education
    errors.add(:custom, "Missing required field: What is your highest level of prior education?") unless EDUCATION_OPTIONS.include? @education
  end

  def validate_shirt
    errors.add(:custom, "Missing required field: What is your t-shirt size?") unless SHIRT_OPTIONS.include? @shirt
  end

  def validate_after_graduation
    if [AFTER_OPTIONS[0], AFTER_OPTIONS[1]].include? @after_graduation
      errors.add(:custom, "Missing required field: When do you plan to start looking for work?") unless ['Yes', 'No'].include? @time_off
    elsif @after_graduation == AFTER_OPTIONS[-1]
      errors.add(:custom, 'Please explain your selection of "Other".') unless @after_graduation_explanation.present?
    else
      errors.add(:custom, "Missing required field: What is your plan after graduating?") unless AFTER_OPTIONS.include? @after_graduation
    end
  end
end
