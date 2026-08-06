class RemoveFormIdFromResponse < ActiveRecord::Migration[6.1]
  def change
    remove_column :responses, :form_id, :integer
    add_column :responses, :form_name, :String
  end
end
