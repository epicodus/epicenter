class DemographicInfo
  include ActiveModel::Model

  GENDER_OPTIONS = ["Female", "Male", "Non-binary", "Transgender"]
  RACE_OPTIONS = ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"]
  EDUCATION_OPTIONS = ["High school diploma or equivalent", "Postsecondary certificate", "Some college, no degree", "Associate's degree", "Bachelor's degree", "Master's degree or higher"]

  attr_accessor :age, :job, :salary, :education, :veteran, :genders, :races

  def initialize(student = nil, attributes = {})
    @student = student
    @gender = (attributes[:genders].select{ |input| GENDER_OPTIONS.include?(input) }).join(", ") if attributes[:genders]
    @age = attributes[:age].to_i if attributes[:age].to_i > 0
    @education = attributes[:education] if EDUCATION_OPTIONS.include?(attributes[:education])
    @job = attributes[:job][0...35] if attributes[:job] && attributes[:job] != ""
    @salary = attributes[:salary].to_i if attributes[:salary].to_i > 0
    @race = (attributes[:races].select{ |input| RACE_OPTIONS.include?(input) }).join(", ") if attributes[:races]
    @veteran = attributes[:veteran] if ["Yes", "No"].include?(attributes[:veteran])
  end

  def save
    fields = {}
    fields['custom.Gender'] = @gender
    fields['custom.Age'] = @age
    fields['custom.Education'] = @education
    fields['custom.Previous job'] = @job
    fields['custom.Previous salary'] = @salary
    fields['custom.Race'] = @race
    fields['custom.veteran'] = @veteran
    fields = fields.compact
    @student.update_close_io(fields) if fields.any?
    @student.update(demographics: true)
  end
end
