class AttendanceRecord < ApplicationRecord
  attr_accessor :signing_out, :pair_ids
  default_scope { order(:date) }
  scope :today, -> { where(date: Time.zone.now.to_date) }

  validates :student_id, presence: true, uniqueness: { scope: :date }
  validates :date, presence: true
  validate :course_in_session?

  before_validation :set_date, if: ->(record) { record.date.nil? }
  before_validation :sign_in, if: ->(record) { record.tardy.nil? }
  before_update :sign_out, if: :signing_out
  before_save :update_pairings, if: :pair_ids

  belongs_to :student
  has_many :pairings, dependent: :destroy

  accepts_nested_attributes_for :pairings, allow_destroy: true

  def self.paired_only
    includes(:pairings).where.not(pairings: {id: nil})
  end

  def self.all_before_2021_and_paired_only_starting_2021
    records_with_pairings = includes(:pairings).where.not(pairings: {id: nil})
    friday_records = includes(:pairings).where("extract(dow from date) = ?", 5)
    legacy_records = includes(:pairings).where('date < ?', Date.parse('2021-01-01'))
    records_with_pairings.or(friday_records).or(legacy_records)
  end

  def self.todays_totals_for(course, status)
    student_ids = course.students(&:id)
    attributes = { tardy: { student_id: student_ids, tardy: true },
                   left_early: { student_id: student_ids, left_early: true },
                   on_time: { student_id: student_ids, tardy: false, left_early: false }
                 }[status]
    results = today.where(attributes)
    if status == :absent
      course.students.count - today.where(student_id: student_ids).count
    else
      results.count
    end
  end

  def status
    if tardy && left_early
      "Tardy and Left early"
    elsif tardy
      "Tardy"
    elsif left_early
      "Left early"
    else
      "On time"
    end
  end

private

  def course_in_session?
    errors.add(:attendance_record, "sign in not required.") unless student.is_class_day?(date)
  end

  def set_date
    self.date = Time.zone.now.to_date
  end

  def sign_in
    current_time = Time.zone.now.in_time_zone(student.course.office.time_zone)
    self.tardy = current_time >= student.course.start_time_today + 16.minutes
    self.left_early = true
  end

  def sign_out
    current_time = Time.zone.now.in_time_zone(student.course.office.time_zone)
    self.left_early = current_time < (student.course.end_time_today - 15.minutes) || current_time > (student.course.end_time_today + 31.minutes)
    self.signed_out_time = current_time
  end

  def update_pairings
    pairings.delete_all
    Student.where(id: pair_ids).each do |pair|
      pairings << Pairing.new(pair: pair)
    end
  end
end
