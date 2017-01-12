class CreateAccesses < ActiveRecord::Migration[5.0]
  def change
    create_table :accesses do |t|
      t.integer :user_id
      t.integer :resource_id
    end
  end
end
