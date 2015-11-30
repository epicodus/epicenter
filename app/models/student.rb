class Student < User
  scope :recurring_active, -> { where(recurring_active: true) }
  scope :with_actived_accounts, -> { where('sign_in_count > ?', 0 ) }
  default_scope { order(:name) }

  validates :plan_id, presence: true
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
  belongs_to :primary_payment_method, class_name: 'PaymentMethod'
  has_many :signatures

  accepts_nested_attributes_for :ratings

  NUMBER_OF_RANDOM_PAIRS = 5

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

  def update_close_io
    if close_io_lead_exists? && enrollment_complete?
      id = close_io_client.list_leads('email:' + email).data.first.id
      close_io_client.update_lead(id, { status: 'Enrolled', 'custom.Amount paid': total_paid / 100 })
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
      customer = Stripe::Customer.create(description: email)
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

  def recurring_amount_with_fees
    plan.recurring_amount + primary_payment_method.calculate_fee(plan.recurring_amount)
  end

  def upfront_amount_with_fees
    plan.upfront_amount + primary_payment_method.calculate_fee(plan.upfront_amount)
  end

  def ready_to_start_recurring_payments?
    plan.recurring_amount > 0 && !recurring_active && !upfront_payment_due?
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

  def next_payment_date
    payments.without_failed.last.created_at + 1.month if recurring_active
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

  def start_recurring_payments
    payment = payments.create(amount: plan.recurring_amount, payment_method: primary_payment_method)
    update!(recurring_active: true) if payment.persisted?
    payment
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
      course.number_of_days_since_start - attendance_records.count
    else
      results.count
    end
  end

  def find_rating(internship)
    ratings.where(internship_id: internship.id).first
  end

  def self.find_students_by_interest(internship, interest_level)
    internship.students.select { |student| student.try(:find_rating, internship).try(:interest) == interest_level }
  end

  def internships_sorted_by_interest
    course.internships_sorted_by_interest(self)
  end

private

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
    course.students.where.not(id: id)
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

  def close_io_lead_exists?
    lead = close_io_client.list_leads('email:' + email)
    lead.total_results == 1
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
