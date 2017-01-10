class CreateEvents < ActiveRecord::Migration[5.0]
  def change
    create_table :events do |t|
      t.integer :trackable_id
      t.string  :trackable_type, limit: 50
      t.integer :ancestor_id
      t.string  :ancestor_type,  limit: 50
      t.integer :actor_id
      t.string  :actor_name,     limit: 50
      t.string  :actor_avatar,   limit: 50
      t.string  :action,         limit: 50
      t.text    :data
      t.string  :ip,             limit: 50
      t.string  :user_agent,     limit: 1000
      t.integer :team_id
      t.integer :resource_id

      t.timestamps null: false
    end

    add_index :events, :team_id
    add_index :events, :ancestor_id
    add_index :events, :actor_id
  end
end
