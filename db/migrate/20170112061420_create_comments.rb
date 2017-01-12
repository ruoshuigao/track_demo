class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.integer  :commentable_id
      t.string   :commentable_type, limit: 50
      t.string   :content,          limit: 1000, null: false
      t.integer  :user_id
      t.string   :user_name,        limit: 20
      t.string   :user_avatar,      limit: 50
      t.integer  :likes_count,      default: 0
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :comments, :commentable_id
    add_index :comments, :deleted_at
  end
end
