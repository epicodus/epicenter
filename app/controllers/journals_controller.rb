class JournalsController < ApplicationController
  before_action { redirect_to root_path, alert: 'You are not authorized to access this page.' unless current_admin }

  def index
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
  end
end
