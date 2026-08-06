class CreateOptions < ActiveRecord::Migration[6.1]
  def change
    create_table :options do |t|
      t.integer :question_id
      t.string :answer

      t.timestamps
    end
  end
end
