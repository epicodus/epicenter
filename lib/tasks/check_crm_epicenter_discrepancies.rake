desc "check for discrepancies between Epicenter and CRM"
task :check_crm_epicenter_discrepancies => [:environment] do
  unless Date.today.saturday? || Date.today.sunday?
    IGNORE_LIST = ["do_not_email@example.com", "unknown_email1@epicodus.com", "unknown_email2@epicodus.com", "audrey2@epicodus.com", "rachel2@epicodus.com", "michael2@epicodus.com", "becky2@epicodus.com", "jill2@epicodus.com"]
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    Student.where(cohort_id: Cohort.where('start_date > ?', Date.parse('2018-10-01'))).each do |student|
      unless IGNORE_LIST.include? student.email
        lead = close_io_client.list_leads('email: "' + student.email + '"')['data'].first
        status = lead['status_label']
        is_enrolled = status == 'Enrolled'
        is_withdrawn = status.include?('Dropped') || status.include?('Expelled')
        is_potential = status.include?('Potential')
        withdrawal_date = lead[Rails.application.config.x.crm_fields['WITHDRAWAL_DATE']]
        cohort_current_crm = lead[Rails.application.config.x.crm_fields['COHORT_CURRENT']]
        cohort_current_epicenter = student.cohort.try(:description)
        cohort_pt_crm = lead[Rails.application.config.x.crm_fields['COHORT_PARTTIME']]
        cohort_pt_epicenter = student.parttime_cohort.try(:description)
        payment_plan_crm = lead[Rails.application.config.x.crm_fields['PAYMENT_PLAN']]
        payment_plan_epicenter = student.plan.try(:close_io_description)

        create_task(lead, 'Missing current or part-time cohort') if is_enrolled && cohort_current_crm.blank? && cohort_pt_crm.blank?
        create_task(lead, 'Current cohort should be blank?') if (is_potential || is_withdrawn) && cohort_current_crm.present?
        create_task(lead, 'Missing withdrawal date') if is_withdrawn && withdrawal_date.blank?
        create_task(lead, 'Payment plan does not match Epicenter') if payment_plan_epicenter != payment_plan_crm
        create_task(lead, 'Current cohort does not match Epicenter') if cohort_current_epicenter != cohort_current_crm
        create_task(lead, 'Part-time cohort does not match Epicenter') if cohort_pt_epicenter != cohort_pt_epicenter
      end
    end
  end
end

def create_task(lead, text)
  WebhookCreateTask.new({ lead_id: lead['id'], text: text, auth: ENV['ZAPIER_SECRET_TOKEN']})
  # puts "#{lead['contacts'].first['emails'].first['email']} #{text}"
end
