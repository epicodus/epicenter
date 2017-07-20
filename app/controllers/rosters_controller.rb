class RostersController < ApplicationController
  before_action :authenticate_admin!

  def show
    @office = Office.find_by(name: params[:office].try(:titlecase)) || Office.first
    @students = AttendanceRecord.where(date: Time.zone.now.to_date, signed_out_time: nil).map { |ar| ar.student }.select { |student| student.course.office == @office }
  end
end
