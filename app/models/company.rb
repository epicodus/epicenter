class Company < ActiveRecord::Base
  validates_presence_of :name, :contact_phone, :contact_email
end
