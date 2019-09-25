desc "clear all CRM lead fields filled in by Epicenter"
task :clear_lead, [:email] => [:environment] do |t, args|
  email = args.email || ""
  while email == ""
    puts "Enter email:"
    email = STDIN.gets.chomp
  end
  close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  lead_id = close_io_client.list_leads('email: "' + email + '"')['data'].first['id']
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['COHORT_STARTING']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['COHORT_CURRENT']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['START_DATE']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['END_DATE']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['PAYMENT_PLAN']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['AMOUNT_PAID']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['SIGNED_INTERNSHIP_AGREEMENT']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_BIRTH_DATE']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['INTERNSHIP_CLASS']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_DISABILITY']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_VETERAN']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_EDUCATION']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_DEGREE']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_JOB']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_PREVIOUS_SALARY']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_SHIRT']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_GENDER']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_PRONOUNS']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_RACE']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_AFTER_GRADUATION']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['DEMOGRAPHICS_TIME_OFF']}": nil })
  close_io_client.update_lead(lead_id, { "custom.#{Rails.application.config.x.crm_fields['SSN']}": nil })
  close_io_client.update_lead(lead_id, { 'addresses': nil })
end
