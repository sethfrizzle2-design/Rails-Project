class AddResponseIdToInput < ActiveRecord::Migration[6.1]
  def change
    add_column :inputs, :response_id, :integer
  end
end
