class AddQuestionWordsToInputs < ActiveRecord::Migration[6.1]
  def change
    add_column :inputs, :question_words, :text
  end
end
