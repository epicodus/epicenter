class RegistrationsController < Devise::RegistrationsController
  def new
    if request.env["devise.mapping"] == Devise.mappings[:company]
      super
    else
      flash[:alert] = "Sign up is only allowed via invitation."
      redirect_to root_path
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
