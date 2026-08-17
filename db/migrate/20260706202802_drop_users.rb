class DropUsers < ActiveRecord::Migration[6.0]
  def up
    drop_table :users, if_exists: true
  end

  def down
    # Intentionally empty because this migration does not
    # retain the original users table definition.
  end
end