class CreateBuilders < ActiveRecord::Migration[6.1]
  def change
    create_table :builders do |t|

      t.timestamps
    end
  end
end
