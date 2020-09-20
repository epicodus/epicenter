class CodeReviewsController < ApplicationController
  authorize_resource

  def new
    @code_review = CodeReview.new
    @course = Course.find(params[:course_id])
    3.times { @code_review.objectives.build }
    if @course.parttime?
      @code_review.visible_date = DateTime.current.beginning_of_week + 3.days + 17.hours
      @code_review.due_date = DateTime.current.beginning_of_week + 10.days + 17.hours
    else
      @code_review.visible_date = DateTime.current.beginning_of_week + 4.days + 8.hours
      @code_review.due_date = DateTime.current.beginning_of_week + 4.days + 17.hours
    end
  end

  def create
    @code_review = CodeReview.new(code_review_params)
    if params[:always_visible]
      @code_review.visible_date = nil
      @code_review.due_date = nil
    end
    @course = Course.find(params[:course_id])
    if @code_review.save
      redirect_to course_code_review_path(@course, @code_review), notice: "Code review has been saved!"
    else
      render 'new'
    end
  end

  def show
    @code_review = CodeReview.find(params[:id])
    @submission = @code_review.submission_for(current_student) || Submission.new(code_review: @code_review)
  end

  def edit
    @code_review = CodeReview.find(params[:id])
    @course = @code_review.course
    if @code_review.due_date.nil?
      if @course.parttime?
        @code_review.visible_date = DateTime.current.beginning_of_week + 3.days + 17.hours
        @code_review.due_date = DateTime.current.beginning_of_week + 10.days + 17.hours
      else
        @code_review.visible_date = DateTime.current.beginning_of_week + 4.days + 8.hours
        @code_review.due_date = DateTime.current.beginning_of_week + 4.days + 17.hours
      end
    end
  end

  def update
    @code_review = CodeReview.find(params[:id])
    @course = @code_review.course
    if @code_review.update(code_review_params)
      if params[:always_visible]
        @code_review.visible_date = nil
        @code_review.due_date = nil
        @code_review.save
      end
      redirect_to course_code_review_path(@course, @code_review), notice: "Code review updated."
    else
      render 'edit'
    end
  end

  def destroy
    @code_review = CodeReview.find(params[:id])
    course = @code_review.course
    if @code_review.destroy
      redirect_to course_path(course), alert: "#{@code_review.title} has been deleted."
    else
      @submission = @code_review.submission_for(current_student) || Submission.new(code_review: @code_review)
      render 'show'
    end
  end

  def update_multiple
    CodeReview.update(params[:code_reviews].keys, params[:code_reviews].values)
    flash[:notice] = 'Order has been saved.'
    redirect_back(fallback_location: root_path)
  end

private

  def code_review_params
    params.require(:code_review).permit(:course_id, :title, :section, :url, :submissions_not_required, :github_path,
                                        :content, :visible_date, :due_date, objectives_attributes: [:id, :number, :content, :_destroy])
  end
end
