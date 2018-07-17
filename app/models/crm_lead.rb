class CrmLead
  def initialize(email)
    @email = email
  end

  def update(update_fields)
    CrmUpdateJob.perform_later(lead['id'], update_fields)
  end

  def status
    lead.try('dig', 'status_label')
  end

  def name
    lead.try('dig', 'contacts').try('first').try('dig', 'name') || CrmLead.raise_error("Name not found in CRM")
  end

  def cohort
    Cohort.find_by(office: office, start_date: start_date, track: track) || CrmLead.raise_error("Cohort not found in Epicenter") unless parttime?
  end

  def first_course
    if parttime?
      course = Course.parttime_courses.find_by(office: office, start_date: start_date)
    else
      course = cohort.courses.first
    end
    course || CrmLead.raise_error("Course not found in Epicenter")
  end

  def update_internship_class(course)
    if course && course.description == "Internship Exempt"
      description = "Internship Exempt"
    elsif course
      description = "#{course.office.short_name} #{course.description.split.first} #{course.start_date.strftime('%b %-d')} - #{course.end_date.strftime('%b %-d')}"
    else
      description = nil
    end
    update({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => description })
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

private

  def lead
    return @lead if @lead
    leads = close_io_client.list_leads('email:' + @email)
    if leads['total_results'] >= 1
      if leads['data'][0]['contacts'][0]['emails'][0]['email'] == @email # extra check because Close email queries sometimes return extraneous results
        return @lead = leads['data'].first
      else
        CrmLead.raise_error("Close.io returned the incorrect lead for #{@email}.")
      end
    else
      CrmLead.raise_error("The Close.io lead for #{@email} was not found.")
    end
  end

  def cohort_applied
    cohort = lead.try('dig', 'custom').try('dig', 'Cohort - Applied') || lead.try('dig', 'custom').try('dig', 'Cohort - Part-time')
    if cohort.nil? || cohort.include?('Legacy') || cohort.include?('A later class')
      CrmLead.raise_error("Cohort - Applied not found in CRM")
    else
      cohort.split(': ').last
    end
  end

  def office
    Office.find_by(short_name: cohort_applied.split[1])
  end

  def track
    if cohort_applied.include? 'Front End Development'
      Track.find_by(description: 'Front End Development')
    else
      Track.find_by(description: cohort_applied.split[2]) || CrmLead.raise_error("Track not found in Epicenter")
    end
  end

  def parttime?
    cohort_applied.include? 'Part-time'
  end

  def start_date
    year = cohort_applied.split[0].to_i
    start_section = cohort_applied.split(' - ').first.split('(').last
    month = Date::ABBR_MONTHNAMES.index(start_section.split.first)
    day = start_section.split.last.to_i
    Time.new(year, month, day).to_date
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
