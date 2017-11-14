class CrmLead
  def initialize(email)
    @email = email
  end

  def update(update_fields)
    update_lead(update_fields.except(:email))
    update_email(update_fields[:email])
  end

  def status
    lead.try(:status_label)
  end

  def name
    lead.try(:contacts).try(:first).try(:name) || raise_error("Name not found in CRM")
  end

  def cohort
    Cohort.find_by(office: office, start_date: start_date, track: track) || raise_error("Cohort not found in Epicenter") unless parttime?
  end

  def first_course
    if parttime?
      course = Course.parttime_courses.find_by(office: office, start_date: start_date)
    else
      course = cohort.courses.first
    end
    course || raise_error("Course not found in Epicenter")
  end

  def update_internship_class(course)
    if course && course.description == "Internship Exempt"
      description = "Internship Exempt"
    elsif course
      location = course.office.name
      location = 'PDX' if location == 'Portland'
      location = 'SEA' if location == 'Seattle'
      description = "#{location} #{course.description.split.first} #{course.start_date.strftime('%b %-d')} - #{course.end_date.strftime('%b %-d')}"
    else
      description = nil
    end
    update({ ENV['CRM_INTERNSHIP_CLASS_FIELD'] => description })
  end

private

  def lead
    return @lead if @lead
    leads = close_io_client.list_leads('email:' + @email)
    if leads.total_results == 1
      return @lead = leads.data.first
    else
      raise_error("The Close.io lead for #{@email} was not found.")
    end
  end

  def update_lead(update_fields)
    return unless update_fields.any?
    crm_response = close_io_client.update_lead(lead.id, update_fields)
    errors = crm_response.try('field-errors').try(:values).try(:join, '; ')
    raise_error(errors) if errors.present?
  end

  def update_email(new_email)
    return unless new_email.present?
    contact = lead.contacts.first
    updated_emails = contact.emails.unshift(Hashie::Mash.new({ type: "office", email: new_email }))
    crm_response = close_io_client.update_contact(contact.id, emails: updated_emails)
    raise_error("Invalid email address.") if crm_response['field-errors']
  end

  def what_class_are_you_interested_in
    lead.try(:custom).try('What class are you interested in?') || raise_error("What class are you interested in not found in CRM")
  end

  def office
    Office.find_by(name: what_class_are_you_interested_in.split[1])
  end

  def start_date
    year = what_class_are_you_interested_in.split[0].to_i
    month = Date::MONTHNAMES.index(what_class_are_you_interested_in.split[2])
    day = what_class_are_you_interested_in.split[3].to_i
    Time.new(year, month, day).to_date
  end

  def parttime?
    what_class_are_you_interested_in.downcase.include?('part-time')
  end

  def track
    Track.find_by(description: what_class_are_you_interested_in.split(': ').last.split(' ').first) || raise_error("Track not found in Epicenter") unless parttime?
  end

  def raise_error(message)
    raise CrmError, message
  end

  def close_io_client
    @close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  end
end
