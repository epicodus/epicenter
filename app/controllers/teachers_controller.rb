class TeachersController < ApplicationController
  def index
    week = params[:week] || Date.today.to_s
    @start_date = Date.parse(week).beginning_of_week
    @teachers = Admin.teachers.select { |admin| admin.reviews.where('created_at BETWEEN ? AND ?', @start_date.beginning_of_day, (@start_date + 6.days).end_of_day).any? }
    authorize! :manage, CodeReview
  end

  def show
    @admin = Admin.find(params[:id])
    day_input = params[:day] || Date.today.to_s
    @day = Date.parse(day_input)
    @reviews = @admin.reviews.where('created_at BETWEEN ? AND ?', @day.beginning_of_day, @day.end_of_day).select {|review| review.submission.try(:student) && review.submission.try(:code_review)}
    authorize! :manage, CodeReview
  end
end
