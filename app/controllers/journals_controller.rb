class JournalsController < ApplicationController
  before_action { redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_admin || current_student }

  def index
    if current_admin
      @journals = CodeReview.where(journal: true)
      if params[:cohort_id]
        @cohort = Cohort.find(params[:cohort_id])
        @journals = @journals.where(course: @cohort.courses)
      end
      if params[:title]
        @title = params[:title]
        @journals = @journals.where(title: @title)
        @submissions = Submission.where(code_review: @journals).reorder(created_at: :desc)
      end
      redirect_to cohort_path(@cohort) if @cohort.present? && @title.nil?
    elsif current_student
      valid_journal_titles = CodeReview.where(journal: true).pluck(:title).uniq
      title = params[:title] if valid_journal_titles.include?(params[:title])
      journal = CodeReview.where(journal: true).where(title: title).where(course: current_student.courses).last
      if journal
        redirect_to course_student_path(journal.course, current_student)
      else
        redirect_to root_path, alert: 'You are not authorized to access this page.'
      end
    end
  end
end
