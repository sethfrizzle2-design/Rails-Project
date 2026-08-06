class AddFormIdToResponse < ActiveRecord::Migration[6.1]
  def change
    add_column :responses, :form_id, :integer
  end
end
