class Admin < User
  belongs_to :current_cohort, class_name: 'Cohort'
end
