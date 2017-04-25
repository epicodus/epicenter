class SeedNewPaymentPlans < ActiveRecord::Migration
  def up
    Plan.create(name: "Up-front Discount ($6,900 up-front)", close_io_description: "2018 - Up-front Discount ($6,900 up-front)", description: "2018 rates", upfront_amount: 690000, upfront: true, start_date: Time.new(2017, 9, 5).to_date)
    Plan.create(name: "Pay As You Go (4 payments of $2,125)", close_io_description: "2018 - Pay As You Go (4 payments of $2,125)", description: "2018 rates", upfront_amount: 10000, first_day_amount: 202500, standard: true, start_date: Time.new(2017, 9, 5).to_date)
    Plan.create(name: "Loan ($100 enrollment fee)", close_io_description: "2018 - Loan ($100 enrollment fee)", description: "2018 rates", upfront_amount: 10000, loan: true, start_date: Time.new(2017, 9, 5).to_date)
    Plan.create(name: "Evening intro class ($600)", close_io_description: "2018 - Evening intro class ($600)", description: "2018 rates", upfront_amount: 60000, parttime: true, start_date: Time.new(2017, 9, 5).to_date)
  end

  def down
    Plan.rates_2018.destroy_all
  end
end
