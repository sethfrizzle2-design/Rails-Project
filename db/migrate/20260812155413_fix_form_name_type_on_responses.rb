# The column was created as :String rather than :string, which SQLite accepted
# but the schema dumper cannot express, so db/schema.rb has been unable to dump
# the responses table (and db:schema:load could not recreate it) since.
class FixFormNameTypeOnResponses < ActiveRecord::Migration[6.1]
    def up
        change_column :responses, :form_name, :string
    end

    def down
        # No going back to an untypeable column.
    end
end
