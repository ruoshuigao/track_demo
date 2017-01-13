class CreateTeams < ActiveRecord::Migration[5.0]
  def change
    create_table :teams do |t|
      t.integer :user_id
      t.string  :title, limit: 50, null: false

      t.timestamps null: false
    end
  end
end
