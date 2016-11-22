class Student < User
  scope :with_activated_accounts, -> { where('sign_in_count > ?', 0 ) }

  validates :plan_id, presence: true, if: ->(student) { student.invitation_accepted_at? }
  validate :primary_payment_method_belongs_to_student
  validate :student_has_course

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

  after_update :update_close_io_payment_plan

  accepts_nested_attributes_for :ratings

  NUMBER_OF_RANDOM_PAIRS = 5
  TARDY_WEIGHT = 0.5

  def attendance_score(filtered_course)
    absences_penalty = attendance_records_for(:absent, filtered_course)
    tardies_penalty = attendance_records_for(:tardy, filtered_course) * TARDY_WEIGHT
    left_earlies_penalty = attendance_records_for(:left_early, filtered_course) * TARDY_WEIGHT
    100 - (((absences_penalty + tardies_penalty + left_earlies_penalty) / filtered_course.number_of_days_since_start) * 100)
  end

  def internship_course
    courses.find_by(internship_course: true)
  end

  def other_courses
    Course.where.not(id: courses.map(&:id))
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

  def update_close_io(update_fields)
    if close_io_lead_exists? && enrollment_complete?
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
    signed?(CodeOfConduct) && signed?(RefundPolicy) && signed?(EnrollmentAgreement)
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
    payments.without_failed.sum(:amount)
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

  def attendance_records_for(status, filtered_course=nil)
    attributes = { tardy: { tardy: true },
                   left_early: { left_early: true },
                   on_time: { tardy: false, left_early: false }
                 }[status]
    results = attendance_records.where(attributes)
    filtered_results = results.where("date between ? and ?", filtered_course.try(:start_date), filtered_course.try(:end_date))
    if filtered_course && status == :absent
      filtered_course.number_of_days_since_start - filtered_results.count
    elsif filtered_course
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

private

  def total_number_of_course_days
    courses.non_internship_courses.map(&:class_days).flatten.count
  end

  def update_close_io_payment_plan
    update_close_io({ 'custom.Payment plan': plan.close_io_description }) if plan_id_changed?
  end

  def next_course
    @next_course ||= courses.where('start_date > ?', Time.zone.now.to_date).first
  end

  def course_in_session
    @course_in_session ||= courses.where('start_date <= ? AND end_date >= ?', Time.zone.now.to_date, Time.zone.now.to_date).first
  end

  def student_has_course
    unless course.present?
      errors.add(:course, "cannot be blank")
      false
    end
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
end
