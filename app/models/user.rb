class User < ActiveRecord::Base
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :lockable

  validates :name, presence: true

  def authenticate_with_github(uid)
    if github_uid?
      github_uid == uid
    else
      update(github_uid: uid)
    end
  end
end
