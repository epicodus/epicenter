class Student < User
  scope :with_activated_accounts, -> { where('sign_in_count > ?', 0 ) }

  validate :primary_payment_method_belongs_to_student

  before_create :assign_payment_plan
  after_create :update_plan_in_crm, if: ->(student) { student.plan.present? }
  after_update :update_plan_in_crm, if: :saved_change_to_plan_id
  after_update :update_probation_in_crm, if: :saved_change_to_probation
  before_destroy :archive_enrollments

  belongs_to :plan, optional: true
  belongs_to :starting_cohort, class_name: :Cohort, optional: true
  belongs_to :ending_cohort, class_name: :Cohort, optional: true
  belongs_to :cohort, optional: true
  belongs_to :office, optional: true
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
  belongs_to :primary_payment_method, class_name: 'PaymentMethod', optional: true
  has_many :signatures
  has_one :internship_assignment
  has_many :cost_adjustments
  has_many :daily_submissions
  has_many :evaluations_of_peers, class_name: :PeerEvaluation, foreign_key: :evaluator
  has_many :evaluations_by_peers, class_name: :PeerEvaluation, foreign_key: :evaluatee

  acts_as_paranoid

  accepts_nested_attributes_for :ratings

  NUMBER_OF_RANDOM_PAIRS = 5
  TARDY_WEIGHT = 0.5

  def self.invite(attributes)
    Rails.logger.info "Invitation: creating Epicenter account"
    email = attributes[:email]
    crm_lead = CrmLead.new(email)
    cohort = crm_lead.cohort
    student = Student.invite!(email: email, name: crm_lead.name, course: cohort.courses.first) do |u|
      u.skip_invitation = true
    end
    cohort.courses.each do |course|
      if course.internship_course? && !crm_lead.work_eligible?
        student.courses << Course.find_by(description: 'Internship Exempt')
      else
        student.courses << course unless student.courses.include?(course)
      end
    end
    student.update(office: student.course.office, ending_cohort: cohort)
    crm_lead.update_now({ Rails.application.config.x.crm_fields['INVITATION_TOKEN'] => student.raw_invitation_token, Rails.application.config.x.crm_fields['EPICENTER_ID'] => student.id })
    student
  end

  def parttime?
    ending_cohort.try(:description).try('include?', 'Part-')
  end

  def fidgetech?
    ending_cohort.try(:description) == 'Fidgetech'
  end

  def fulltime?
    ending_cohort && !parttime? && !fidgetech?
  end

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

  def solos(filtered_course = nil)
    if filtered_course
      attendance_records.where(pair_id: nil, ignore: nil).where("date between ? and ?", filtered_course.try(:start_date), filtered_course.try(:end_date)).select { |ar| !ar.date.friday? }.count
    else
      attendance_records.where(pair_id: nil, ignore: nil).select { |ar| !ar.date.friday? }.count
    end
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
    course_ids = enrollments.with_deleted.map {|enrollment| enrollment.course.try(:id) }
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

  def pairs
    attendance_records.map {|s| s.pair_id}.compact.sort
  end

  def latest_total_grade_score
    @latest_total_grade_score ||= most_recent_submission_grades.try(:inject, 0) { |score, grade| score += grade.score.value }
  end

  def signed?(signature_model)
    if signature_model.nil?
      true
    else
      signatures.where(type: signature_model.name, is_complete: true).count == 1
    end
  end

  def signed_main_documents?
    documents_required.all? { |doc| signed?(doc) } && demographics?
  end

  def documents_required
    if course == Course.find_by(description: 'Fidgetech')
      documents = [CodeOfConduct, EnrollmentAgreement]
    else
      documents = [CodeOfConduct, RefundPolicy, EnrollmentAgreement]
    end
    documents << ComplaintDisclosure if office.try(:name) == 'Seattle'
    documents
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

  def total_owed
    plan.student_portion + cost_adjustments.sum(:amount)
  end

  def total_remaining_owed
    total_owed - total_paid
  end

  def upfront_amount_owed
    plan.standard? ? plan.upfront_amount + cost_adjustments.sum(:amount) - total_paid : total_owed - total_paid
  end

  def upfront_amount_with_fees
    upfront_amount_owed + primary_payment_method.calculate_fee(upfront_amount_owed)
  end

  def upfront_payment_due?
    plan.nil? || upfront_amount_owed > 0
  end

  def make_upfront_payment
    payments.create(amount: upfront_amount_owed, payment_method: primary_payment_method, category: 'upfront')
  end

  def total_paid
    payments.without_failed.sum(:amount) - payments.without_failed.sum(:refund_amount)
  end

  def total_paid_online
    payments.without_failed.online.sum(:amount) - payments.without_failed.online.sum(:refund_amount)
  end

  def total_paid_offline
    payments.without_failed.offline.sum(:amount) - payments.without_failed.offline.sum(:refund_amount)
  end

  def signed_in_today?
    attendance_records.select { |attendance_record| attendance_record.date == Time.zone.now.to_date }.any? # needs to be refactored; this is more efficient than using the today scope for attendance records, but not an ideal solution
  end

  def signed_out_today?
    if signed_in_today?
      attendance_records.today.first.signed_out_time != nil
    end
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
    passed = true
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
      [0, total_number_of_course_days(start_course, end_course) - filtered_results.count].max
    elsif start_course && status == :absent
      filtered_results = results.where("date between ? and ?", start_course.try(:start_date), start_course.try(:end_date))
      [0, start_course.number_of_days_since_start - filtered_results.count].max
    elsif start_course
      filtered_results.count
    elsif status == :absent
      [0, total_number_of_course_days - attendance_records.count].max
    else
      results.count
    end
  end

  def find_rating(internship)
    ratings.where(internship_id: internship.id).first
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

  def crm_lead
    CrmLead.new(email)
  end

  def calculate_starting_cohort
    # 1st FT cohort ever enrolled in if exists; else first PT cohort
    # if student switches from PT -> FT will replace starting cohort with FT one
    # if student switches from FT -> PT will remain FT cohort
    courses_with_withdrawn.fulltime_courses.first.try(:cohorts).try(:first) || courses_with_withdrawn.parttime_courses.first.try(:cohorts).try(:first)
  end

  def calculate_current_cohort
    # current FT cohort if student enrolled in internship course; else current PT cohort
    # always ignores withdrawn courses, cuz we're interested in *current* cohort
    if courses.internship_courses.any?
      fulltime_courses = courses.fulltime_courses.where.not(description: 'Internship Exempt')
      last_unique_course = fulltime_courses.select { |course| course.cohorts.count == 1 }.last
      last_unique_course.try(:cohorts).try(:first)
    else
      courses.parttime_courses.last.try(:cohorts).try(:first)
    end
  end

  def really_destroy
    crm_lead.update({ Rails.application.config.x.crm_fields['EPICENTER_ID'] => nil, Rails.application.config.x.crm_fields['INVITATION_TOKEN'] => nil })
    really_destroy!
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

  def primary_payment_method_belongs_to_student
    if primary_payment_method && primary_payment_method.student != self
      errors.add(:primary_payment_method, 'must belong to you.')
    end
  end

  def archive_enrollments
    enrollments.each { |enrollment| enrollment.destroy }
  end

  def assign_payment_plan
    if course.try(:description) == 'Fidgetech'
      self.plan = Plan.active.find_by(short_name: 'special-other')
    elsif course.try(:parttime?) && !course.try(:language).try(:name).try(:downcase).try('include?', 'part-time track')
      self.plan = Plan.active.find_by(short_name: 'parttime-intro')
    end
  end

  def update_plan_in_crm
    crm_lead.update({ Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => plan.try(:close_io_description) })
  end

  def update_probation_in_crm
    crm_lead.update({ Rails.application.config.x.crm_fields['PROBATION'] => probation ? 'Yes' : nil })
  end
end
