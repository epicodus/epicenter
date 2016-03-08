class RegistrationsController < Devise::RegistrationsController
  def new
    if request.env["devise.mapping"] == Devise.mappings[:company]
      super
    else
      redirect_to root_path, alert: 'Sign up is only allowed via invitation.'
    end
  end

  def create
    internship_params = sign_up_params.delete(:internships_attributes)
    @internship = Internship.new(internship_params)
    if @internship.save
      super do |user|
        if user.persisted?
          user.internships << @internship
        else
          @internship.destroy
        end
      end
    else
      render 'devise/registrations/new'
    end
  end

private

  def build_resource(sign_up_params)
    user_params = sign_up_params.except!(:internships_attributes)
    super
  end
end
