class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string   :name,            limit: 20
      t.string   :email,           limit: 100, null: false
      t.string   :avatar,          limit: 50
      t.string   :password_digest, limit: 180
      t.datetime :deleted_at

      t.timestamps null: false
    end

    add_index :users, :email,      unique: true
    add_index :users, :deleted_at, unique: true
  end
end
