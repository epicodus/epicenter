class Assessment < ActiveRecord::Base
  validates_presence_of :title, :section, :url
end
