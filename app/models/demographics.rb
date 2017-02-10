  class Demographics
  def self.create(student, demographics)
    fields = {}
    fields['custom.Gender'] = (demographics[:genders].select{ |input| ["Female", "Male", "Non-binary", "Transgender"].include?(input) }).join(", ") if demographics[:genders]
    fields['custom.Age'] = demographics[:age].to_i if demographics[:age].to_i != 0
    fields['custom.Education'] = demographics[:education] if ["High school diploma or equivalent", "Postsecondary certificate", "Some college, no degree", "Associate's degree", "Bachelor's degree", "Master's degree or higher"].include?(demographics[:education])
    fields['custom.Previous job'] = demographics[:job][0...35] if demographics[:job] && demographics[:job] != ""
    fields['custom.Previous salary'] = demographics[:salary].to_i if demographics[:salary].to_i != 0
    fields['custom.Race'] = (demographics[:races].select{ |input| ["Asian or Asian American", "American Indian or Alaska Native", "Black or African American", "Hispanic or Latino", "Middle Eastern", "Native Hawaiian or Other Pacific Islander", "White", "Other"].include?(input) }).join(", ") if demographics[:races]
    fields['custom.veteran'] = demographics[:veteran] if ["Yes", "No"].include?(demographics[:veteran])
    student.update_close_io(fields) if fields.any?
    student.update(demographics: true)
  end
end
