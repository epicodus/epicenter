class CrmLead
  def initialize(email)
    @email = email
  end

  def self.lead_exists?(email)
    Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false).list_leads('email: "' + email + '"')['total_results'] == 1
  end

  def update(update_fields)
    CrmUpdateJob.perform_later(lead['id'], update_fields)
  end

  def update_now(update_fields)
    CrmLead.perform_update(lead['id'], update_fields)
  end

  def status
    lead.try('dig', 'status_label')
  end

  def name
    lead.try('dig', 'contacts').try('first').try('dig', 'name') || CrmLead.raise_error("Name not found in CRM")
  end

  def cohort
    if fidgetech?
      Cohort.find_by(description: 'Fidgetech')
    else
      Cohort.find_by(office: office, start_date: start_date, track: track) || CrmLead.raise_error("Cohort not found in Epicenter")
    end
  end

  def work_eligible?
    lead.try('dig', Rails.application.config.x.crm_fields['DEMOGRAPHICS_WORK_ELIGIBILITY_USA']) != 'No'
  end

  def update_internship_class(course)
    if course && course.description == "Internship Exempt"
      description = "Internship Exempt"
    elsif course
      description = "#{course.office.short_name} #{course.description.split.first} #{course.start_date.strftime('%b %-d')} - #{course.end_date.strftime('%b %-d')}"
    else
      description = nil
    end
    update({ Rails.application.config.x.crm_fields['INTERNSHIP_CLASS'] => description })
  end

  def self.perform_update(lead_id, update_fields)
    if update_fields[:email]
      crm_response = update_email(lead_id, update_fields[:email])
    elsif update_fields[:note]
      crm_response = create_note(lead_id, update_fields[:note])
    else
      crm_response = update_lead(lead_id, update_fields.except(:email))
    end
    errors = crm_response.try('field-errors').try(:values).try(:join, '; ')
    CrmLead.raise_error(errors) if errors.present?
  end

  def forum_id
    lead.try('dig', Rails.application.config.x.crm_fields['FORUM_ID']).try(:to_int)
  end

  def contact_id
    lead.try('dig', 'contacts').try('first').try('dig', 'id')
  end

  def create_task(text)
    close_io_client.create_task(lead_id: lead.try('dig', 'id'), text: text, date: Time.zone.now.to_date.to_s)
  end

private

  def lead
    return @lead if @lead
    leads = close_io_client.list_leads('email: "' + @email + '"')
    if leads['total_results'] >= 1
      return @lead = leads['data'].first
    else
      CrmLead.raise_error("The Close.io lead for #{@email} was not found.")
    end
  end

  def cohort_applied
    cohort = lead.try('dig', Rails.application.config.x.crm_fields['COHORT_APPLIED'])
    if cohort.nil? || cohort.include?('Legacy') || cohort.include?('A later class')
      CrmLead.raise_error("Cohort - Applied not found in CRM")
    else
      cohort.split(': ').last
    end
  end

  def office
    Office.find_by(short_name: cohort_applied.split[3])
  end

  def track
    if cohort_applied.include? 'Part-Time JS/React'
      Track.find_by(description: 'Part-Time JS/React')
    elsif cohort_applied.include? 'Part-Time Intro to Programming'
      Track.find_by(description: 'Part-Time Intro to Programming')
    else
      Track.find_by(description: cohort_applied.split[4]) || CrmLead.raise_error("Track not found in Epicenter")
    end
  end

  def parttime?
    cohort_applied.include? 'Part-'
  end

  def fidgetech?
    cohort_applied.include? 'Fidgetech'
  end

  def start_date
    Date.parse(cohort_applied[0,10])
  end

  def self.update_email(lead_id, new_email)
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    contact = close_io_client.find_lead(lead_id)['contacts'].first
    updated_emails = contact['emails'].unshift(Hashie::Mash.new({ type: "office", email: new_email }))
    close_io_client.update_contact(contact['id'], emails: updated_emails)
  end

  def self.create_note(lead_id, note)
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    close_io_client.create_note({ lead_id: lead_id, note: note})
  end

  def self.update_lead(lead_id, update_fields)
    close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
    close_io_client.update_lead(lead_id, update_fields)
  end

  def self.raise_error(message)
    raise CrmError, message
  end

  def close_io_client
    @close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  end
end
