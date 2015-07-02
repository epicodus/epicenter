class AddBeforeHelloSignToUsers < ActiveRecord::Migration
  def change
    add_column :users, :before_hello_sign, :boolean
    User.all.each do |user|
      user.update(before_hello_sign: true)
    end
  end
end
