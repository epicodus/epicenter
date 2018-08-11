class SeedNewPaymentPlansForCrmSync < ActiveRecord::Migration[5.2]
  def up
    Plan.create(name: 'Loan (Climb)', close_io_description: 'Climb', short_name: 'loan-climb', upfront_amount: 100_00, loan: true)
    Plan.create(name: 'Loan (SkillsFund)', close_io_description: 'SkillsFund', short_name: 'loan-skillsfund', upfront_amount: 100_00, loan: true)
    Plan.create(name: 'Loan (in process)', close_io_description: 'Seeking a loan - in process', short_name: 'loan-in-process', upfront_amount: 100_00, loan: true)
    Plan.create(name: 'Special (3rd-party grant)', close_io_description: '3rd-party grant', short_name: 'special-grant', upfront_amount: 0, upfront: true)
    Plan.create(name: 'Special (GI Bill recipient)', close_io_description: 'GI Bill recipient', short_name: 'special-gi-bill', upfront_amount: 0, upfront: true)
    Plan.create(name: 'Special (other special arrangement)', close_io_description: 'Other - Special arrangement', short_name: 'special-other', upfront_amount: 0, upfront: true)
  end
end
