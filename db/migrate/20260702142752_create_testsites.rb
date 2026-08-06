class CreateTestsites < ActiveRecord::Migration[6.1]
  def change
    create_table :testsites do |t|
      t.string :pages
      t.string :one
      t.string :two
      t.string :three
      t.string :four

      t.timestamps
    end
  end
end
