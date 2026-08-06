class AddQuestionIdToInput < ActiveRecord::Migration[6.1]
  def change
    add_column :inputs, :question_id, :Integer
  end
end
