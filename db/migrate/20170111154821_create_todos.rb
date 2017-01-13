class CreateTodos < ActiveRecord::Migration[5.0]
  def change
    create_table :todos do |t|
      t.integer  :project_id
      t.integer  :user_id
      t.string   :user_name,     limit: 20
      t.string   :user_avatar,   limit: 50
      t.string   :name,          limit: 20,  null: false
      t.string   :description,   limit: 1000
      t.string   :status,        limit: 50
      t.datetime :due_at
      t.integer  :comments_count, default: 0
      t.string   :priority,       limit: 10
      t.integer  :assignee_id
      t.string   :assignee_name,  limit: 20
      t.string   :tag,            limit: 20
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :todos, :project_id
    add_index :todos, :status
    add_index :todos, :assignee_id
    add_index :todos, :deleted_at
  end
end
