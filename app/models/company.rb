class Company < User
  has_many :internships

  accepts_nested_attributes_for :internships
end
