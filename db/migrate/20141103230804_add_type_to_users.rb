class AddTypeToUsers < ActiveRecord::Migration
  class User < ActiveRecord::Base
  end

  def change
    add_column :users, :type, :string

    User.all.each do |user|
      user.update(type: "Student")
    end
  end
end
