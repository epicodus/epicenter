class User < ApplicationRecord
  devise :invitable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :lockable,
         :two_factor_authenticatable, :otp_secret_encryption_key => ENV['OTP_SECRET_ENCRYPTION_KEY']
  devise :omniauthable, omniauth_providers: %i[github]

  validates :name, presence: true

  def authenticate_with_github(uid)
    if github_uid?
      github_uid == uid
    else
      update(github_uid: uid)
    end
  end
end
