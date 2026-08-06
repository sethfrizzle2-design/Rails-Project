class CreateQuestions < ActiveRecord::Migration[6.1]
  def change
    create_table :questions do |t|
      t.integer :form_id
      t.string :format
      t.text :words

      t.timestamps
    end
  end
end
