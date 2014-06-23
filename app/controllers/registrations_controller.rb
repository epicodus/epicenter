class RegistrationsController < Devise::RegistrationsController

  def new
    super
    @subscription = Subscription.new
  end

protected
  def after_sign_up_path_for(resource)
    '/notice.html'
  end
end
