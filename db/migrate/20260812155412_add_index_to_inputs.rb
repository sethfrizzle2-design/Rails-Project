class AddIndexToInputs < ActiveRecord::Migration[6.1]
    def change
        add_index :inputs, %i[question_id answer]
    end
end
