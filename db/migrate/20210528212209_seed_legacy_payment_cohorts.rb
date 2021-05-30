class SeedLegacyPaymentCohorts < ActiveRecord::Migration[5.2]
  def up
    Payment.all.each do |payment|
      cohort = payment.student.try(:ending_cohort)
      payment.update_columns(cohort_id: cohort.try(:id))
    end
  end

  def down
    Payment.update_all(cohort_id: nil)  
  end
end
