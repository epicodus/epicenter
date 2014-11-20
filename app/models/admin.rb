class Admin < User
  belongs_to :current_cohort, class_name: 'Cohort'

  before_create :assign_current_cohort

private

  def assign_current_cohort
    self.current_cohort = Cohort.last
  end
end
