class AttendanceSignOutController < ApplicationController
  def new
    if current_student.try(:online?) && current_student.try(:pairs_without_feedback_today).try(:any?)
      redirect_to pair_feedback_path
    elsif current_student.try(:online?)
      redirect_to sign_out_remote_path
    elsif IpLocation.is_local?(request.env['HTTP_CF_CONNECTING_IP'] || request.remote_ip)
      redirect_to sign_out_classroom_path
    else
      redirect_back(fallback_location: root_path, alert: 'Attendance sign out unavailable. If you are an online student, please sign out of attendance through Epicenter.')
    end
  end
end
