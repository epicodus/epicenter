class Pairing < ApplicationRecord
  belongs_to :attendance_record
  belongs_to :pair, class_name: 'Student'
end
