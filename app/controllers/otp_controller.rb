class OtpController < ApplicationController
  before_action :authenticate_admin!

  def new
    if current_admin.otp_required_for_login
      return redirect_to root_path, alert: 'Two Factor Authentication is already enabled.'
    end
    generate_two_factor_secret_if_missing!
    @qr = RQRCode::QRCode.new(two_factor_qr_code_uri).as_svg(viewbox: "0 0 100 100", svg_attributes: {width: '60%'})
  end

  def create
    if current_admin.valid_password?(enable_2fa_params[:password]) && current_admin.validate_and_consume_otp!(enable_2fa_params[:code])
      enable_two_factor!
      return redirect_to root_path, notice: 'Successfully enabled two factor authentication. Thanks!'
    else
      return redirect_to new_otp_path, alert: 'Incorrect password or code'
    end
  end

private
  def enable_2fa_params
    params.require(:two_fa).permit(:code, :password)
  end

  def two_factor_qr_code_uri
    issuer = 'Epicodus'
    label = "Epicenter (#{current_admin.name.split.first})"
    current_admin.otp_provisioning_uri(label, issuer: issuer)
  end

  def generate_two_factor_secret_if_missing!
    current_admin.otp_secret ||= User.generate_otp_secret
    current_admin.save!
  end

  def enable_two_factor!
    current_admin.otp_required_for_login = true
    current_admin.save!
  end
end
