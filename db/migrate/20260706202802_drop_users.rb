class DropUsers < ActiveRecord::Migration[6.1]
  def change
    drop_table(User)
  end
end
