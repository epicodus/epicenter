class DemographicInfo
  include ActiveModel::Model
  include ActiveModel::Validations
  include ActiveModel::Validations::Callbacks

  GENDER_OPTIONS = ["Female", "Male", "Non-binary", "Transgender", "Other"]
  PRONOUN_OPTIONS = ["she / her / hers", "he / him / his", "they / them / their", "Other"]
  RACE_OPTIONS = ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"]
  EDUCATION_OPTIONS = ["less than high school diploma", "GED", "high school diploma", "some post high school but no degree or certificate", "certificate (less than 2 years)", "associate's degree", "bachelor's degree", "master's degree", "doctoral degree or above", "other"]
  SHIRT_OPTIONS = ["XS", "S", "M", "L", "XL", "2XL", "3XL", "4XL"]
  AFTER_OPTIONS = ["I intend to start a new in-field job within 180 days of graduating the program.", "I intend to remain with my current employer upon graduation.", "I am attending the program to learn new skills for self-enrichment and do not intend to pursue an in-field job upon graduation.", "I intend to continue education in an accredited post-secondary institution and do not intend to pursue an in-field job upon graduation."]
  COUNTRY_OPTIONS = [["Afghanistan", "AF"], ["Aland Islands", "AX"], ["Albania", "AL"], ["Algeria", "DZ"], ["American Samoa", "AS"], ["Andorra", "AD"], ["Angola", "AO"], ["Anguilla", "AI"], ["Antarctica", "AQ"], ["Antigua and Barbuda", "AG"], ["Argentina", "AR"], ["Armenia", "AM"], ["Aruba", "AW"], ["Australia", "AU"], ["Austria", "AT"], ["Azerbaijan", "AZ"], ["Bahamas", "BS"], ["Bahrain", "BH"], ["Bangladesh", "BD"], ["Barbados", "BB"], ["Belarus", "BY"], ["Belgium", "BE"], ["Belize", "BZ"], ["Benin", "BJ"], ["Bermuda", "BM"], ["Bhutan", "BT"], ["Bolivia", "BO"], ["Bosnia and Herzegovina", "BA"], ["Botswana", "BW"], ["Bouvet Island", "BV"], ["Brazil", "BR"], ["British Virgin Islands", "VG"], ["British Indian Ocean Territory", "IO"], ["Brunei Darussalam", "BN"], ["Bulgaria", "BG"], ["Burkina Faso", "BF"], ["Burundi", "BI"], ["Cambodia", "KH"], ["Cameroon", "CM"], ["Canada", "CA"], ["Cape Verde", "CV"], ["Cayman Islands", "KY"], ["Central African Republic", "CF"], ["Chad", "TD"], ["Chile", "CL"], ["China", "CN"], ["Hong Kong, SAR China", "HK"], ["Macao, SAR China", "MO"], ["Christmas Island", "CX"], ["Cocos (Keeling) Islands", "CC"], ["Colombia", "CO"], ["Comoros", "KM"], ["Congo (Brazzaville)", "CG"], ["Congo, (Kinshasa)", "CD"], ["Cook Islands", "CK"], ["Costa Rica", "CR"], ["Côte d'Ivoire", "CI"], ["Croatia", "HR"], ["Cuba", "CU"], ["Cyprus", "CY"], ["Czech Republic", "CZ"], ["Denmark", "DK"], ["Djibouti", "DJ"], ["Dominica", "DM"], ["Dominican Republic", "DO"], ["Ecuador", "EC"], ["Egypt", "EG"], ["El Salvador", "SV"], ["Equatorial Guinea", "GQ"], ["Eritrea", "ER"], ["Estonia", "EE"], ["Ethiopia", "ET"], ["Falkland Islands (Malvinas)", "FK"], ["Faroe Islands", "FO"], ["Fiji", "FJ"], ["Finland", "FI"], ["France", "FR"], ["French Guiana", "GF"], ["French Polynesia", "PF"], ["French Southern Territories", "TF"], ["Gabon", "GA"], ["Gambia", "GM"], ["Georgia", "GE"], ["Germany", "DE"], ["Ghana", "GH"], ["Gibraltar", "GI"], ["Greece", "GR"], ["Greenland", "GL"], ["Grenada", "GD"], ["Guadeloupe", "GP"], ["Guam", "GU"], ["Guatemala", "GT"], ["Guernsey", "GG"], ["Guinea", "GN"], ["Guinea-Bissau", "GW"], ["Guyana", "GY"], ["Haiti", "HT"], ["Heard and Mcdonald Islands", "HM"], ["Holy See (Vatican City State)", "VA"], ["Honduras", "HN"], ["Hungary", "HU"], ["Iceland", "IS"], ["India", "IN"], ["Indonesia", "ID"], ["Iran, Islamic Republic of", "IR"], ["Iraq", "IQ"], ["Ireland", "IE"], ["Isle of Man", "IM"], ["Israel", "IL"], ["Italy", "IT"], ["Jamaica", "JM"], ["Japan", "JP"], ["Jersey", "JE"], ["Jordan", "JO"], ["Kazakhstan", "KZ"], ["Kenya", "KE"], ["Kiribati", "KI"], ["Korea (North)", "KP"], ["Korea (South)", "KR"], ["Kuwait", "KW"], ["Kyrgyzstan", "KG"], ["Lao PDR", "LA"], ["Latvia", "LV"], ["Lebanon", "LB"], ["Lesotho", "LS"], ["Liberia", "LR"], ["Libya", "LY"], ["Liechtenstein", "LI"], ["Lithuania", "LT"], ["Luxembourg", "LU"], ["Macedonia, Republic of", "MK"], ["Madagascar", "MG"], ["Malawi", "MW"], ["Malaysia", "MY"], ["Maldives", "MV"], ["Mali", "ML"], ["Malta", "MT"], ["Marshall Islands", "MH"], ["Martinique", "MQ"], ["Mauritania", "MR"], ["Mauritius", "MU"], ["Mayotte", "YT"], ["Mexico", "MX"], ["Micronesia, Federated States of", "FM"], ["Moldova", "MD"], ["Monaco", "MC"], ["Mongolia", "MN"], ["Montenegro", "ME"], ["Montserrat", "MS"], ["Morocco", "MA"], ["Mozambique", "MZ"], ["Myanmar", "MM"], ["Namibia", "NA"], ["Nauru", "NR"], ["Nepal", "NP"], ["Netherlands", "NL"], ["Netherlands Antilles", "AN"], ["New Caledonia", "NC"], ["New Zealand", "NZ"], ["Nicaragua", "NI"], ["Niger", "NE"], ["Nigeria", "NG"], ["Niue", "NU"], ["Norfolk Island", "NF"], ["Northern Mariana Islands", "MP"], ["Norway", "NO"], ["Oman", "OM"], ["Pakistan", "PK"], ["Palau", "PW"], ["Palestinian Territory", "PS"], ["Panama", "PA"], ["Papua New Guinea", "PG"], ["Paraguay", "PY"], ["Peru", "PE"], ["Philippines", "PH"], ["Pitcairn", "PN"], ["Poland", "PL"], ["Portugal", "PT"], ["Puerto Rico", "PR"], ["Qatar", "QA"], ["Réunion", "RE"], ["Romania", "RO"], ["Russian Federation", "RU"], ["Rwanda", "RW"], ["Saint-Barthelemy", "BL"], ["Saint Helena", "SH"], ["Saint Kitts and Nevis", "KN"], ["Saint Lucia", "LC"], ["Saint-Martin (French part)", "MF"], ["Saint Pierre and Miquelon", "PM"], ["Saint Vincent and Grenadines", "VC"], ["Samoa", "WS"], ["San Marino", "SM"], ["Sao Tome and Principe", "ST"], ["Saudi Arabia", "SA"], ["Senegal", "SN"], ["Serbia", "RS"], ["Seychelles", "SC"], ["Sierra Leone", "SL"], ["Singapore", "SG"], ["Slovakia", "SK"], ["Slovenia", "SI"], ["Solomon Islands", "SB"], ["Somalia", "SO"], ["South Africa", "ZA"], ["South Georgia and the South Sandwich Islands", "GS"], ["South Sudan", "SS"], ["Spain", "ES"], ["Sri Lanka", "LK"], ["Sudan", "SD"], ["Suriname", "SR"], ["Svalbard and Jan Mayen Islands", "SJ"], ["Swaziland", "SZ"], ["Sweden", "SE"], ["Switzerland", "CH"], ["Syrian Arab Republic (Syria)", "SY"], ["Taiwan, Republic of China", "TW"], ["Tajikistan", "TJ"], ["Tanzania, United Republic of", "TZ"], ["Thailand", "TH"], ["Timor-Leste", "TL"], ["Togo", "TG"], ["Tokelau", "TK"], ["Tonga", "TO"], ["Trinidad and Tobago", "TT"], ["Tunisia", "TN"], ["Turkey", "TR"], ["Turkmenistan", "TM"], ["Turks and Caicos Islands", "TC"], ["Tuvalu", "TV"], ["Uganda", "UG"], ["Ukraine", "UA"], ["United Arab Emirates", "AE"], ["United Kingdom", "GB"], ["United States of America", "US"], ["US Minor Outlying Islands", "UM"], ["Uruguay", "UY"], ["Uzbekistan", "UZ"], ["Vanuatu", "VU"], ["Venezuela (Bolivarian Republic)", "VE"], ["Viet Nam", "VN"], ["Virgin Islands, US", "VI"], ["Wallis and Futuna Islands", "WF"], ["Western Sahara", "EH"], ["Yemen", "YE"], ["Zambia", "ZM"], ["Zimbabwe", "ZW"]]

  before_validation :format_birth_date!, if: -> { @birth_date.present? }

  validates_presence_of :birth_date, :education, :shirt
  validates :address, presence: true, length: { maximum: 200 }
  validates :apartment, length: { maximum: 35 }, allow_nil: true
  validates :city, presence: true, length: { maximum: 100 }
  validates :state, presence: true, length: { maximum: 100 }
  validates :zip, presence: true, length: { maximum: 10 }
  validates :country, presence: true, length: { maximum: 100 }
  validates :education, inclusion: { in: EDUCATION_OPTIONS }
  validates :after_graduation, inclusion: { in: AFTER_OPTIONS }
  validates :shirt, inclusion: { in: SHIRT_OPTIONS }
  validates :disability, :veteran, :cs_degree, inclusion: { in: ['Yes', 'No'] }
  validates :time_off, inclusion: { in: ['Yes', 'No'] }, allow_nil: true
  validates :job, length: { maximum: 35 }, allow_nil: true
  validates :salary, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :ssn, numericality: { less_than: 1000000000 }, allow_nil: true
  validate :validate_birth_date, if: -> { @birth_date.present? }
  validate :validate_multiselect_list_attributes
  validate :validate_time_off

  attr_accessor :student, :birth_date, :disability, :veteran, :education, :cs_degree, :address, :apartment, :city, :state, :zip, :country, :shirt, :job, :salary, :genders, :races, :after_graduation, :time_off, :ssn, :pronouns, :pronouns_blank

  def initialize(student = nil, attributes = {})
    @student = student
    @birth_date = attributes[:birth_date]
    @disability = checkbox_to_yes_no(attributes[:disability])
    @veteran = checkbox_to_yes_no(attributes[:veteran])
    @education = attributes[:education]
    @cs_degree = checkbox_to_yes_no(attributes[:cs_degree])
    @address = attributes[:address]
    @apartment = attributes[:apartment]
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
    @time_off = attributes[:time_off] if @after_graduation == "I intend to start a new in-field job within 180 days of graduating the program."
    @ssn = attributes[:ssn].gsub(/\D/, '').to_i if attributes[:ssn].present?
    @pronouns = attributes[:pronouns]
    @pronouns_blank = attributes[:pronouns_blank]
  end

  def save
    if valid?
      @student.crm_lead.update(built_fields)
      @student.update_columns(pronouns: updated_pronouns.join(', ')) if @pronouns.present?
      true
    end
  end

  def built_fields
    {
      'addresses' => ["label": "mailing", "address_1": full_address, "city": @city, "state": @state, "zipcode": @zip, "country": @country],
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_BIRTH_DATE'] => @birth_date,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_DISABILITY'] => @disability,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_VETERAN'] => @veteran,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_EDUCATION'] => @education,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_DEGREE'] => @cs_degree,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_JOB'] => @job,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_SALARY'] => @salary,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_SHIRT'] => @shirt,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_AFTER_GRADUATION'] => @after_graduation,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_TIME_OFF'] => @time_off,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_GENDER'] => Array(@genders).join(', ').presence,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_RACE'] => Array(@races).join(', ').presence,
      Rails.application.config.x.crm_fields['DEMOGRAPHICS_PRONOUNS'] => Array(updated_pronouns).join(', ').presence,
      Rails.application.config.x.crm_fields['SSN'] => ssn ? encrypted_ssn : nil
    }.compact
  end

private

  def encrypted_ssn
    public_key = OpenSSL::PKey::RSA.new(ENV['PUBLIC_KEY'])
    Base64.encode64(public_key.public_encrypt(ssn.to_s))
  end

  def format_birth_date!
    if @birth_date.match?(/\d{2}\/\d{2}\/\d{4}/)
      month, day, year = @birth_date.split('/')
      @birth_date = "#{year}-#{month}-#{day}"
    end
  end

  def validate_multiselect_list_attributes
    validate_in_list(:genders, @genders, GENDER_OPTIONS)
    validate_in_list(:races, @races, RACE_OPTIONS)
  end

  def validate_in_list(field, values, options)
    Array(values).each do |value|
      errors.add(field, "not found in list.") unless options.include? value
    end
  end

  def validate_time_off
    if @after_graduation == AFTER_OPTIONS.first && @time_off.nil?
      errors.add(:time_off, "Missing required field: When do you plan to start looking for work?")
    end
  end

  def validate_birth_date
    if !@birth_date.match?(/\d{4}-\d{2}-\d{2}/)
      errors.add(:birth_date, "is unrecognized.")
    elsif Date.parse(@birth_date) > Date.today - 10.years
      errors.add(:birth_date, "is too recent.")
    end
  rescue ArgumentError, TypeError, Date::Error
    errors.add(:birth_date, "unrecognized format.")
  end

  def checkbox_to_yes_no(value)
    value == '1' ? 'Yes' : 'No'
  end

  def full_address
    @apartment ? "#{@address} #{@apartment}" : @address
  end

  def updated_pronouns
    if @pronouns.present? && @pronouns_blank.present? && @pronouns.include?('Other')
      @pronouns.reject { |pronoun| pronoun == 'Other' } + [@pronouns_blank]
    else
      @pronouns
    end
  end
end