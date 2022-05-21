class OtpController < ApplicationController
  before_action :authenticate_user!

  def new
    cookies.delete :setup_2fa
    if current_user.otp_required_for_login
      render :disable_2fa
    else
      generate_two_factor_secret_if_missing!
      @qr = RQRCode::QRCode.new(two_factor_qr_code_uri).as_svg(viewbox: "0 0 100 100", svg_attributes: {width: '60%'})
    end
  end

  def create
    if current_user.valid_password?(enable_2fa_params[:password]) && enable_2fa_params[:disable_2fa]
      disable_two_factor!
      return redirect_to root_path, alert: 'Two Factor Authentication disabled.'
    elsif current_user.valid_password?(enable_2fa_params[:password]) && current_user.validate_and_consume_otp!(enable_2fa_params[:code])
      enable_two_factor!
      return redirect_to root_path, notice: 'Successfully enabled two factor authentication. Thanks!'
    else
      return redirect_to new_otp_path, alert: 'Incorrect password or code'
    end
  end

private
  def enable_2fa_params
    params.require(:two_fa).permit(:code, :password, :disable_2fa)
  end

  def two_factor_qr_code_uri
    issuer = 'Epicodus'
    label = "Epicenter (#{current_user.name.split.first})"
    current_user.otp_provisioning_uri(label, issuer: issuer)
  end

  def generate_two_factor_secret_if_missing!
    current_user.otp_secret ||= User.generate_otp_secret
    current_user.save!
  end

  def enable_two_factor!
    current_user.otp_required_for_login = true
    current_user.save!
  end

  def disable_two_factor!
    current_user.otp_required_for_login = false
    current_user.otp_secret = nil
    current_user.save!
  end
end
