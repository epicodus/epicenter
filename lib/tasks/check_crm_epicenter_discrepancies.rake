desc "check for discrepancies between Epicenter and CRM"
task :check_crm_epicenter_discrepancies => [:environment] do
  unless Date.today.saturday? || Date.today.sunday?
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    Student.where(cohort_id: Cohort.where('start_date > ?', Date.parse('2018-10-01'))).each do |student|
      unless student.email.include?('example.com') || student.email.include?('epicodus.com')
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

        create_task(student, 'Missing current or part-time cohort') if is_enrolled && cohort_current_crm.blank? && cohort_pt_crm.blank?
        create_task(student, 'Current cohort should be blank?') if (is_potential || is_withdrawn) && cohort_current_crm.present?
        create_task(student, 'Missing withdrawal date') if is_withdrawn && withdrawal_date.blank?
        create_task(student, 'Payment plan does not match Epicenter') if payment_plan_epicenter != payment_plan_crm
        create_task(student, 'Current cohort does not match Epicenter') if cohort_current_epicenter != cohort_current_crm
        create_task(student, 'Part-time cohort does not match Epicenter') if cohort_pt_epicenter != cohort_pt_epicenter
      end
    end
  end
end

def create_task(student, text)
  if Rails.env.production?
    student.crm_lead.create_task(text)
  else
    puts student.email + ': ' + text
  end
end