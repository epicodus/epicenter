class SpecialPermission < ApplicationRecord
  belongs_to :student
  belongs_to :code_review
end
