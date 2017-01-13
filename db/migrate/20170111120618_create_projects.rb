class CreateProjects < ActiveRecord::Migration[5.0]
  def change
    create_table :projects do |t|
      t.integer :user_id
      t.integer :team_id
      t.string  :name,        limit: 20,  null: false
      t.string  :description, limit: 1000
      t.integer :category,    default: 0
      t.string  :status,      limit: 50
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :projects, :team_id
    add_index :projects, :deleted_at
  end
end
