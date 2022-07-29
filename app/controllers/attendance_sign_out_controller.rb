class AttendanceSignOutController < ApplicationController

  def new
    @student = current_student
    authorize! :read, @student
    if @student.signed_in_today?
      render :new
    else
      redirect_back(fallback_location: root_path, alert: "You haven't signed in yet today.")
    end
  end

  def create
    attendance_record = AttendanceRecord.find_by(date: Time.zone.now.to_date, student: current_student)
    authorize! :update, attendance_record
    attendance_record.signing_out = true
    if attendance_record.save
      if in_classroom?
        email_pair_feedback_link if signed_in_with_pairs?
        redirect_to root_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
      elsif signed_in_with_pairs?
        redirect_to pair_feedback_path, notice: "Your attendance record has been updated."
      else
        redirect_to root_path, notice: "Goodbye #{attendance_record.student.name}. Your attendance record has been updated."
      end
    else
      redirect_back(fallback_location: root_path, alert: attendance_record.errors.full_messages.join(", "))
    end
  end

private
  def in_classroom?
    IpLocation.is_local_computer_portland?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
  end

  def signed_in_with_pairs?
    current_student.pairs_without_feedback_today.any?
  end

  def email_pair_feedback_link
    today = Time.zone.now.to_date
    EmailJob.perform_later(
      { :from => current_student.course.admin.email,
        :to => current_student.email,
        :subject => 'Pair feedback form for ' + today.strftime("%A %B ") + today.day.ordinalize,
        :text => "If you wish to submit pair feedback for " + today.strftime("%A %B ") + today.day.ordinalize + ", please visit https://epicenter.epicodus.com/pair_feedback before midnight."
      }
    )
  end
end
