class ReportsController < ApplicationController
  def index
    authorize! :manage, CodeReview
  end
end
