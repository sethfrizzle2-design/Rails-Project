class AddIndexToBuses < ActiveRecord::Migration[6.1]
  def change
    add_index :buses, :bus_id, unique: true
  end
end
