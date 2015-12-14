class AddCloseioDescriptionToPlans < ActiveRecord::Migration
  def change
    add_column :plans, :close_io_description, :string

    Plan.find_by(name: '4-class up-front discount').update(close_io_description: '$3,400 up-front')
    Plan.find_by(name: 'Loan').update(close_io_description: 'Seeking a loan - in process')
    Plan.find_by(name: 'Standard tuition').update(close_io_description: 'Standard Plan - $150 then $850')
  end
end
