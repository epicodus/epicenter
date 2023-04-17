class Student < User
  scope :with_activated_accounts, -> { where('sign_in_count > ?', 0 ) }

  validate :primary_payment_method_belongs_to_student

  before_create :assign_payment_plan
  before_update :reset_upfront_amount_on_plan_change, if: :will_save_change_to_plan_id?
  after_create :update_plan_in_crm, if: ->(student) { student.plan.present? }
  after_update :update_plan_in_crm, if: :saved_change_to_plan_id
  after_update :update_legal_name_in_crm, if: :saved_change_to_legal_name
  after_update :update_pronouns_in_crm, if: :saved_change_to_pronouns
  after_update :handle_probation, if: :probation_updated?
  after_update :update_cohorts_in_crm, if: :cohorts_updated?
  before_destroy :archive_enrollments

  belongs_to :plan, optional: true
  belongs_to :parttime_cohort, class_name: :Cohort, optional: true
  belongs_to :starting_cohort, class_name: :Cohort, optional: true
  belongs_to :cohort, optional: true
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
  has_many :daily_submissions
  has_many :evaluations_of_peers, class_name: :PeerEvaluation, foreign_key: :evaluator
  has_many :evaluations_by_peers, class_name: :PeerEvaluation, foreign_key: :evaluatee
  has_many :evaluations_of_pairs, class_name: :PairFeedback, foreign_key: :student
  has_many :evaluations_by_pairs, class_name: :PairFeedback, foreign_key: :pair

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
    student.parttime_cohort = student.calculate_parttime_cohort
    student.starting_cohort = student.calculate_starting_cohort
    student.cohort = student.calculate_current_cohort
    student.save if student.changed?
    crm_lead.update_now({ Rails.application.config.x.crm_fields['INVITATION_TOKEN'] => student.raw_invitation_token, Rails.application.config.x.crm_fields['EPICENTER_ID'] => student.id })
    student
  end

  def attendance_records_for(status, start_course=nil, end_course=nil)
    attributes = { tardy: { tardy: true },
                   left_early: { left_early: true },
                   on_time: { tardy: false, left_early: false },
                   all: {}
                 }[status]
    if status == :all
      results = attendance_records.where(attributes)
    else
      results = attendance_records.all_before_2021_and_paired_only_starting_2021.where(attributes)
    end
    if start_course
      results = results.where("date between ? and ?", start_course.start_date, end_course.try(:end_date) || start_course.end_date)
    end
    if status == :absent
      past_class_days = start_course ? days_so_far(start_course, end_course || start_course) : days_since_start_of_program
      absences = past_class_days - results.map {|ar| ar.date}
      absences_count = absences.count + absences.select {|date| date.sunday?}.count
      [0, absences_count].max
    else
      results.count
    end
  end

  def total_attendance_score
    100 - ((absences_cohort / days_since_start_of_program.count) * 100)
  end

  def absences(filtered_course)
    absences_penalty = attendance_records_for(:absent, filtered_course)
    tardies_penalty = attendance_records_for(:tardy, filtered_course) * TARDY_WEIGHT
    left_earlies_penalty = attendance_records_for(:left_early, filtered_course) * TARDY_WEIGHT
    absences_penalty + tardies_penalty + left_earlies_penalty
  end

  def absences_cohort
    (latest_cohort.try(:courses) || courses).current_and_previous_courses.non_internship_courses.sum { |c| absences(c) }
  end

  def allowed_absences
    course.parttime? ? 20 : 10 # for this purpose PT is intro & full-stack
  end

  def solos(filtered_course = nil)
    solo_records = attendance_records.includes(:pairings).where(pairings: {id: nil})
    if filtered_course
      filtered_records = solo_records.where("date between ? and ?", filtered_course.start_date, filtered_course.end_date)
    else
      cohort_courses = course.cohort.courses
      filtered_records = solo_records.where("date between ? and ?", cohort_courses.first.start_date, cohort_courses.last.end_date)
    end
    filtered_records.reject {|ar| ar.date.friday?}.count
  end

  def days_since_start_of_program
    (latest_cohort.try(:courses) || courses).non_internship_courses.map(&:class_days).flatten.select {|day| day <= Time.zone.now.to_date}
  end

  def enrolled_fulltime_cohorts
    Cohort.where(id: courses.cirr_fulltime_courses.pluck(:cohort_id))
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
      courses.order(:start_date).last || courses.last
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

  def pair_ids(course=nil)
    selected_attendance_records = course ? attendance_records.where("date between ? and ?", course.start_date, course.end_date) : attendance_records
    selected_attendance_records.joins(:pairings).pluck(:pair_id).sort
  end

  def pairs_on_day(day)
    Student.where(id: attendance_record_on_day(day).try(:pairings).try('pluck', 'pair_id'))
  end

  def pairs_today
    pairs_on_day(Time.zone.now.to_date)
  end

  def inverse_pairs_on_day(day)
    Student.where(id: AttendanceRecord.where(date: day).joins(:pairings).where(pairings: { pair_id: id }).pluck(:student_id))
  end

  def inverse_pairs_today
    inverse_pairs_on_day(Time.zone.now.to_date)
  end

  def orphan_pairs_on_day(day) # extra pairs this student nonreciprocally claimed
    pairs_on_day(day).where.not(id: inverse_pairs_on_day(day))
  end

  def orphan_pairs_today
    orphan_pairs_on_day(Time.zone.now.to_date)
  end

  def inverse_orphan_pairs_on_day(day) # students who nonreciprocally claimed this student as a pair
    inverse_pairs_on_day(day).where.not(id: pairs_on_day(day))
  end

  def inverse_orphan_pairs_today
    inverse_orphan_pairs_on_day(Time.zone.now.to_date)
  end

  def pairs_without_feedback_today
    pairs_today.where.not(id: evaluations_of_pairs.today.pluck(:pair_id))
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
    elsif location == 'SEA'
      documents = [CodeOfConduct, RefundPolicy, EnrollmentAgreement, ComplaintDisclosure]
    else
      documents = [CodeOfConduct, RefundPolicy, EnrollmentAgreement]
    end
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

  def upfront_amount
    super || plan.upfront_amount
  end

  def upfront_amount_owed
    upfront_amount - total_paid
  end

  def upfront_amount_with_fees
    upfront_amount_owed + primary_payment_method.calculate_fee(upfront_amount_owed)
  end

  def upfront_payment_due?
    plan.nil? || upfront_amount_owed > 0
  end

  def make_upfront_payment
    payments.create(amount: upfront_amount_owed, payment_method: primary_payment_method, category: 'upfront', cohort: latest_cohort)
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

  def is_class_day?(date = Time.zone.now.to_date)
    courses.find_by('class_days LIKE ?', "%#{date}%").try(:class_days).try('include?', date)
  end

  def is_classroom_day?(date = Time.zone.now.to_date)
    (is_class_day?(date) && !date.friday?) || ENV['ATTENDANCE_TEST_MODE'] == 'true'
  end

  def completed_internship_course?
    internship_course = courses.find_by(internship_course: true)
    internship_course && Time.zone.now.to_date > internship_course.end_date ? true : false
  end

  def passed_all_fulltime_code_reviews?
    passed = true
    courses.cirr_fulltime_courses.each do |course|
      course.code_reviews.where(journal: nil).or(course.code_reviews.where(journal: false)).each do |cr|
        if cr.status(self) != 'Met requirements'
          passed = false
        end
      end
    end
    passed
  end

  def find_rating(internship)
    ratings.where(internship_id: internship.id).first
  end

  def enrolled?
    cohort.present? || parttime_cohort.present?
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

  def location
    locations = {
      'WA' => 'SEA',
      'Washington' => 'SEA',
      'OR' => 'PDX',
      'Oregon' => 'PDX'
    }
    locations[crm_lead.state] || 'WEB'
  end

  def calculate_starting_cohort
    # cohorts to include: FT,  PT full-stack
    # cohorts to ignore: PT intro, PT JS/React
    # include withdrawn courses
    # 1st FT cohort or PT full-stack cohort ever enrolled in
    courses_with_withdrawn.cirr_fulltime_courses.first.try(:cohort)
  end

  def calculate_current_cohort
    # cohorts to include: FT, PT full-stack
    # cohorts to ignore: PT intro, PT JS/React
    # ignore withdrawn courses
    # current or last completed FT *or* PT full-stack cohort
    # student must be enrolled in internship course
    # ignore _which_ internship course for determining current cohort
    if courses.internship_courses.any?
      courses.cirr_fulltime_courses.non_internship_courses.last.try(:cohort)
    end
  end

  def calculate_parttime_cohort
    # cohorts to include: PT intro, PT JS/React
    # cohorts to ignore: FT, PT full-stack
    # ignore withdrawn courses
    # current or last completed PT intro or PT JS/React cohort
    courses.cirr_parttime_courses.last.try(:cohort)
  end

  def possible_cirr_cohorts
    Cohort.where(id: courses.cirr_fulltime_courses.pluck(:cohort_id))
  end

  def all_cohorts
    Cohort.where(id: courses.pluck(:cohort_id))
  end

  def latest_cohort
    Cohort.where(id: [cohort, parttime_cohort]).reorder(:end_date).last
  end

  def really_destroy
    crm_lead.update({ Rails.application.config.x.crm_fields['EPICENTER_ID'] => nil, Rails.application.config.x.crm_fields['INVITATION_TOKEN'] => nil })
    really_destroy!
  end

private

  def days_so_far(start_course=nil, end_course=nil)
    filtered_courses = start_course.nil? ? courses : courses.where('start_date >= ? AND end_date <= ?', start_course.start_date, end_course.end_date)
    filtered_courses.non_internship_courses.map(&:class_days).flatten.select {|day| day <= Time.zone.now.to_date}
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
    elsif course.try(:track).try(:description) == 'Part-Time Intro to Programming'
      self.plan = Plan.active.find_by(short_name: 'parttime-intro')
    end
  end

  def reset_upfront_amount_on_plan_change
    self.upfront_amount = nil
  end

  def update_plan_in_crm
    crm_lead.update({ Rails.application.config.x.crm_fields['PAYMENT_PLAN'] => plan.try(:close_io_description) })
  end

  def update_legal_name_in_crm
    crm_lead.update({ Rails.application.config.x.crm_fields['LEGAL_NAME'] => legal_name })
  end

  def update_pronouns_in_crm
    crm_lead.update({ Rails.application.config.x.crm_fields['PRONOUNS'] => pronouns })
  end

  def probation_updated?
    saved_change_to_probation_advisor? || saved_change_to_probation_teacher?
  end

  def handle_probation
    if saved_change_to_probation_advisor? && probation_advisor == true
      set_probation_in_crm('advisor', true)
      update(probation_advisor_count: probation_advisor_count.to_i + 1)
      send_probation_count_webhook
    elsif saved_change_to_probation_advisor
      set_probation_in_crm('advisor', false)
    elsif saved_change_to_probation_teacher? && probation_teacher == true
      set_probation_in_crm('teacher', true)
      update(probation_teacher_count: probation_teacher_count.to_i + 1)
      send_probation_count_webhook
    elsif saved_change_to_probation_teacher?
      set_probation_in_crm('teacher', false)
    end
  end

  def set_probation_in_crm(team, enabled)
    advisor_probation_field = Rails.application.config.x.crm_fields['PROBATION_ADVISOR']
    teacher_probation_field = Rails.application.config.x.crm_fields['PROBATION_TEACHER']
    field = team == 'advisor' ? advisor_probation_field : teacher_probation_field
    value = enabled == true ? 'Yes' : nil
    crm_lead.update({ field => value })
  end

  def send_probation_count_webhook
    WebhookProbation.new(email: email, advisor: probation_advisor_count.to_i, teacher: probation_teacher_count.to_i) # notify about probation count
  end

  def cohorts_updated?
    saved_change_to_cohort_id? || saved_change_to_starting_cohort_id? || saved_change_to_parttime_cohort_id? || will_save_change_to_cohort_id? || will_save_change_to_parttime_cohort_id?
  end

  def update_cohorts_in_crm
    crm_update = {}
    crm_update = crm_update.merge({ Rails.application.config.x.crm_fields['COHORT_PARTTIME'] => parttime_cohort.try(:description) })
    crm_update = crm_update.merge({ Rails.application.config.x.crm_fields['COHORT_STARTING'] => starting_cohort.try(:description) })
    crm_update = crm_update.merge({ Rails.application.config.x.crm_fields['COHORT_CURRENT'] => cohort.try(:description) })
    crm_lead.update(crm_update)
  end
end
