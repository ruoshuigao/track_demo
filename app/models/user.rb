class User < ApplicationRecord
  has_secure_password

  has_many :teams
  has_many :assigned_todos, class_name: 'Todo', foreign_key: 'assignee_id'
  has_many :resources, through: :accesses
  has_many :accesses
end
