class StaticPagesController < ApplicationController
  before_filter :redirect_if_logged_in

  def index
  end

private
  def redirect_if_logged_in
    redirect_to after_sign_in_path_for(current_user) if current_user
  end
end
