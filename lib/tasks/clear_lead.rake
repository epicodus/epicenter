desc "clear all CRM lead fields filled in by Epicenter"
task :clear_lead, [:email] => [:environment] do |t, args|
  email = args.email || ""
  while email == ""
    puts "Enter email:"
    email = STDIN.gets.chomp
  end
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  lead_id = close_io_client.list_leads('email: "' + email + '"')['data'].first['id']
  fields =
  {
    Rails.application.config.x.crm_fields['COHORT_STARTING'] => nil,
    Rails.application.config.x.crm_fields['COHORT_CURRENT'] => nil,
    Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => nil,
    Rails.application.config.x.crm_fields['AMOUNT_PAID'] => nil,
    Rails.application.config.x.crm_fields['SIGNED_INTERNSHIP_AGREEMENT'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_BIRTH_DATE'] => nil,
    Rails.application.config.x.crm_fields['INTERNSHIP_CLASS'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_DISABILITY'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_VETERAN'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_EDUCATION'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_DEGREE'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_JOB'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_SALARY'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_SHIRT'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_GENDER'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_PRONOUNS'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_RACE'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_AFTER_GRADUATION'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_TIME_OFF'] => nil,
    Rails.application.config.x.crm_fields['SSN'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_DIPLOMA'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_OVER18'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_WORK_ELIGIBILITY_USA'] => nil,
    Rails.application.config.x.crm_fields['DEMOGRAPHICS_WORK_ELIGIBILITY_COUNTRY'] => nil,
    Rails.application.config.x.crm_fields['WITHDRAWAL_DATE'] => nil,
    Rails.application.config.x.crm_fields['KEYCARD'] => nil,
    'addresses': nil
  }
  close_io_client.update_lead(lead_id, fields)
end
