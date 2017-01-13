class CreateResources < ActiveRecord::Migration[5.0]
  def change
    create_table :resources do |t|
      t.integer :resourceable_id
      t.string  :resourceable_type, limit: 50
      t.integer :team_id

      t.timestamps null: false
    end
  end
end
