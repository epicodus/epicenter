class SubmissionsController < ApplicationController
  def index
    @submissions = Submission.all
    authorize! :read, @submissions
  end

  def new
    @submission = Submission.new
    authorize! :create, @submission
  end

  def create
    @submission = Submission.new(submission_params)
    if @submission.save
      redirect_to submissions_url, notice: "Submission added!"
    else
      render 'new'
    end
    authorize! :create, @submission
  end

  def show
    @submission = Submission.find(params[:id])
    authorize! :read, @submission
  end

  def edit
    @submission = Submission.find(params[:id])
    authorize! :update, @submission
  end

  def update
    @submission = Submission.find(params[:id])
    if @submission.update(submission_params)
      redirect_to submissions_url, notice: "Submission updated!"
    else
      render 'new'
    end
    authorize! :update, @submission
  end

  def destroy
    authorize! :destroy, @submission
  end

private

  def submission_params
    params.require(:submission).permit(:title, :section, :url)
  end

end
