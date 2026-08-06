class CreateBuses < ActiveRecord::Migration[6.1]
  def change
    create_table :buses do |t|
      t.integer :bus_id
      t.string :location
      t.integer :route_id

      t.timestamps
    end
    
  end
end
