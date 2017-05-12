class Student < User
  scope :with_activated_accounts, -> { where('sign_in_count > ?', 0 ) }

  validate :primary_payment_method_belongs_to_student
  validates :plan_id, presence: true, if: ->(student) { student.invitation_accepted_at? }
  before_update :validate_plan_id, if: ->(student) { student.plan_id_changed? && student.course.present? }
  after_update :update_starting_cohort_crm, if: ->(student) { student.starting_cohort_id_changed? }

  belongs_to :plan
  has_many :enrollments
  has_many :courses, through: :enrollments
  has_many :bank_accounts
  has_many :credit_cards
  has_many :payments
  has_many :attendance_records
  has_many :submissions
  has_many :payment_methods
  has_many :ratings
  has_many :internships, through: :ratings
  has_many :interview_assignments
  belongs_to :primary_payment_method, class_name: 'PaymentMethod'
  has_many :signatures
  has_one :internship_assignment

  acts_as_paranoid

  accepts_nested_attributes_for :ratings

  NUMBER_OF_RANDOM_PAIRS = 5
  TARDY_WEIGHT = 0.5

  def attendance_score(filtered_course)
    absences_penalty = attendance_records_for(:absent, filtered_course)
    tardies_penalty = attendance_records_for(:tardy, filtered_course) * TARDY_WEIGHT
    left_earlies_penalty = attendance_records_for(:left_early, filtered_course) * TARDY_WEIGHT
    100 - (((absences_penalty + tardies_penalty + left_earlies_penalty) / filtered_course.number_of_days_since_start) * 100)
  end

  def absences(filtered_course)
    absences_penalty = attendance_records_for(:absent, filtered_course)
    tardies_penalty = attendance_records_for(:tardy, filtered_course) * TARDY_WEIGHT
    left_earlies_penalty = attendance_records_for(:left_early, filtered_course) * TARDY_WEIGHT
    absences_penalty + tardies_penalty + left_earlies_penalty
  end

  def solos(filtered_course)
    attendance_records.where(pair_id: nil, ignore: nil).where("date between ? and ?", filtered_course.try(:start_date), filtered_course.try(:end_date)).select { |ar| !ar.date.friday? }.count
  end

  def internship_course
    courses.find_by(internship_course: true)
  end

  def other_courses
    Course.where.not(id: courses.map(&:id))
  end

  def courses_withdrawn
    enrollments.only_deleted.select { |enrollment| !courses.include? enrollment.course }.map {|enrollment| enrollment.course }.compact.sort
  end

  def courses_with_withdrawn
    course_ids = enrollments.with_deleted.map {|enrollment| enrollment.course.id }
    Course.where(id: course_ids).order(:start_date)
  end

  def course
    if course_in_session
      course_in_session
    elsif next_course
      next_course
    else
      courses.last
    end
  end

  def course_id
    course.try(:id)
  end

  def course=(new_course)
    if new_course.nil?
      # do nothing
    elsif new_course.class == Course
      courses.push(new_course)
    else
      new_course = Course.find(new_course)
      courses.push(new_course)
    end
  end

  def course_id=(new_course_id)
    courses.push(Course.find(new_course_id))
  end

  def submission_for(code_review)
    submissions.find { |submission| submission.code_review_id == code_review.id }
  end

  def pair_on_day(day)
    Student.find_by(id: attendance_record_on_day(day).try(:pair_id)) # using find_by so that nil is returned instead of raising exception if there is no pair
  end

  def attendance_record_on_day(day)
    attendance_records.find_by(date: day)
  end

  def random_pairs
    distance_until_end = similar_grade_students.length - random_starting_point
    if distance_until_end >= NUMBER_OF_RANDOM_PAIRS
      similar_grade_students[random_starting_point, NUMBER_OF_RANDOM_PAIRS]
    else
      (similar_grade_students[random_starting_point, NUMBER_OF_RANDOM_PAIRS] + similar_grade_students[0, NUMBER_OF_RANDOM_PAIRS - distance_until_end]).uniq
    end
  end

  def latest_total_grade_score
    @latest_total_grade_score ||= most_recent_submission_grades.try(:inject, 0) { |score, grade| score += grade.score.value }
  end

  def close_io_lead_exists?
    lead = close_io_client.list_leads('email:' + email)
    lead.total_results == 1
  end

  def get_crm_status
    begin
      lead = close_io_client.list_leads('email:' + email)
      lead['data'].first['status_label']
    rescue NoMethodError
      nil
    end
  end

  def update_close_email(new_email)
    if close_io_lead_exists?
      contact = close_io_client.list_leads('email:' + email).data.first.contacts.first
      updated_emails = contact.emails.unshift(Hashie::Mash.new({ type: "office", email: new_email }))
      result = close_io_client.update_contact(contact.id, emails: updated_emails)
      if result['field-errors']
        raise CrmError, "Invalid email address."
      end
    elsif !close_io_lead_exists?
      raise CrmError, "The student record for #{email} was not found."
    end
  end

  def update_close_io(update_fields)
    if close_io_lead_exists?
      lead_id = close_io_client.list_leads('email:' + email).data.first.id
      close_io_client.update_lead(lead_id, update_fields)
    elsif !close_io_lead_exists?
     raise "The Close.io lead for #{email} was not found."
    end
  end

  def signed?(signature_model)
    if signature_model.nil?
      true
    else
      signatures.where(type: signature_model, is_complete: true).count == 1
    end
  end

  def signed_main_documents?
    if course && course.office.name == "Seattle"
      signed?(CodeOfConduct) && signed?(RefundPolicy) && signed?(ComplaintDisclosure) && signed?(EnrollmentAgreement) && demographics?
    else
      signed?(CodeOfConduct) && signed?(RefundPolicy) && signed?(EnrollmentAgreement) && demographics?
    end
  end

  def stripe_customer
    if stripe_customer_id
      customer = Stripe::Customer.retrieve(stripe_customer_id)
    else
      customer = Stripe::Customer.create(email: email)
      update(stripe_customer_id: customer.id)
      customer
    end
  end

  def payment_methods_primary_first_then_pending
    (payment_methods.not_verified_first - [primary_payment_method]).unshift(primary_payment_method).compact
  end

  def upfront_payment_due?
    plan.upfront_amount > 0 && payments.without_failed.count == 0
  end

  def upfront_amount_with_fees
    plan.upfront_amount + primary_payment_method.calculate_fee(plan.upfront_amount)
  end

  def total_paid
    payments.without_failed.sum(:amount) - payments.without_failed.sum(:refund_amount)
  end

  def signed_in_today?
    attendance_records.select { |attendance_record| attendance_record.date == Time.zone.now.to_date }.any? # needs to be refactored; this is more efficient than using the today scope for attendance records, but not an ideal solution
  end

  def signed_out_today?
    if signed_in_today?
      attendance_records.today.first.signed_out_time != nil
    end
  end

  def make_upfront_payment
    payments.create(amount: plan.upfront_amount, payment_method: primary_payment_method)
  end

  def class_in_session?
    if courses.any?
      course.start_date <= Time.zone.now.to_date && course.end_date >= Time.zone.now.to_date
    else
      false
    end
  end

  def class_over?
    Time.zone.now.to_date > course.end_date
  end

  def completed_internship_course?
    internship_course = courses.find_by(internship_course: true)
    internship_course && Time.zone.now.to_date > internship_course.end_date ? true : false
  end

  def passed_all_code_reviews?
    passed = true;
    courses.each do |course|
      course.code_reviews.each do |cr|
        if cr.status(self) != 'Met requirements'
          passed = false
        end
      end
    end
    passed
  end

  def attendance_records_for(status, start_course=nil, end_course=nil)
    attributes = { tardy: { tardy: true },
                   left_early: { left_early: true },
                   on_time: { tardy: false, left_early: false },
                   all: {}
                 }[status]
    results = attendance_records.where(attributes)
    if start_course && end_course
      filtered_results = results.where("date between ? and ?", start_course.try(:start_date), end_course.try(:end_date))
    else
      filtered_results = results.where("date between ? and ?", start_course.try(:start_date), start_course.try(:end_date))
    end
    if start_course && end_course && status == :absent
      filtered_results = results.where("date between ? and ?", start_course.try(:start_date), end_course.try(:end_date))
      total_number_of_course_days(start_course, end_course) - filtered_results.count
    elsif start_course && status == :absent
      filtered_results = results.where("date between ? and ?", start_course.try(:start_date), start_course.try(:end_date))
      start_course.number_of_days_since_start - filtered_results.count
    elsif start_course
      filtered_results.count
    elsif status == :absent
      total_number_of_course_days - attendance_records.count
    else
      results.count
    end
  end

  def find_rating(internship)
    ratings.where(internship_id: internship.id).first
  end

  def valid_plans
    first_course = courses.order(:start_date).first
    if first_course
      filtered_plans = course.parttime? ? Plan.active.parttime : Plan.active.fulltime
      if first_course.start_date < Time.new(2017, 5, 22).to_date
        return filtered_plans.rates_2016
      elsif first_course.start_date < Time.new(2017, 9, 5).to_date
        return filtered_plans.rates_2017
      else
        return filtered_plans.rates_2018
      end
    else
      return Plan.active
    end
  end

  def get_status
    if deleted?
      "Archived"
    elsif courses_with_withdrawn.empty?
      "Not enrolled"
    elsif courses.empty?
      "Incomplete"
    elsif completed_internship_course?
      "Graduate"
    elsif course.parttime?
      if Time.zone.now.to_date < course.start_date
        "Part-time (future)"
      elsif class_over?
        "Part-time (past)"
      else
        "Part-time (current)"
      end
    elsif course.end_date < Time.new(2016, 1, 1).to_date
      "Pre-2016"
    elsif class_over?
      "Incomplete"
    elsif course.start_date > Time.zone.now.to_date
      "Future student"
    else
      "Current student"
    end
  end

private

  def total_number_of_course_days(start_course=nil, end_course=nil)
    if start_course
      filtered_courses = courses.where('start_date >= ? AND end_date <= ?', start_course.start_date, end_course.end_date)
      filtered_courses.non_internship_courses.where.not(description: "* Placement Test").map(&:class_days).flatten.count
    else
      courses.non_internship_courses.map(&:class_days).flatten.count
    end
  end

  def next_course
    @next_course ||= courses.where('start_date > ?', Time.zone.now.to_date).first
  end

  def course_in_session
    @course_in_session ||= courses.where('start_date <= ? AND end_date >= ?', Time.zone.now.to_date, Time.zone.now.to_date).first
  end

  def random_starting_point
    begin
      Time.zone.today.day.to_i % similar_grade_students.count
    rescue ZeroDivisionError
      0
    end
  end

  def similar_grade_students
    @similar_grade_students ||= same_course.to_a.keep_if { |student| similar_grades?(student) || latest_total_grade_score == nil }
  end

  def same_course
    course.students.order(:name).where.not(id: id)
  end

  def most_recent_submission_grades
    submissions.last.try(:reviews).try(:first).try(:grades)
  end

  def similar_grades?(student)
    begin
      student.latest_total_grade_score.try(:between?, 0.9 * latest_total_grade_score, 1.1 * latest_total_grade_score)
    rescue TypeError
      true
    end
  end

  def enrollment_complete?
    signatures.where(is_complete: true).count > 2 && total_paid > 0
  end

  def close_io_client
    @close_io_client ||= Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
  end

  def primary_payment_method_belongs_to_student
    if primary_payment_method && primary_payment_method.student != self
      errors.add(:primary_payment_method, 'must belong to you.')
    end
  end

  def self.pull_info_from_crm(email)
    response = { errors: [] }
    if Student.only_deleted.find_by(email: email)
      response[:errors].push("Student exists in Epicenter but has been archived.")
    elsif User.find_by(email: email)
      response[:errors].push("Email already used in Epicenter")
    else
      close_io_client = Closeio::Client.new(ENV['CLOSE_IO_API_KEY'], false)
      lead = close_io_client.list_leads('email:' + email)
      if lead.total_results > 0
        name = lead.data.first.contacts.first.name
        course = Course.find_by(description: lead.data.first.custom.Class)
        name && name != "" ? response[:name] = name : response[:errors].push("Name not found")
        course ? response[:course_id] = course.id : response[:errors].push("Valid course not found")
      else
        response[:errors].push("Email not found")
      end
    end
    response
  end

  def validate_plan_id
    valid_plans.include? plan
  end

  def update_starting_cohort_crm
    description = starting_cohort_id ? Course.find(starting_cohort_id).description : nil
    update_close_io({ 'custom.Starting Cohort': description })
  end
end
