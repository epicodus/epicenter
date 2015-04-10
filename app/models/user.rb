class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :invitable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  validates :name, presence: true

  attr_writer :invitation_instructions

  def deliver_invitation
    if @invitation_instructions.present?
      ::Devise.mailer.send(@invitation_instructions, self).deliver
    else
      super
    end
  end

  def self.invite_student!(attributes={}, invited_by=nil)
    self.invite!(attributes, invited_by) do |invitable|
      invitable.invitation_instructions = :student_invitation_instructions
    end
  end

  def self.invite_admin!(attributes={}, invited_by=nil)
    self.invite!(attributes, invited_by) do |invitable|
      invitable.invitation_instructions = :admin_invitation_instructions
    end
  end

end
