class Team < ApplicationRecord
  include Eventable
  include Accessable

  has_event on: [:create], skip: [:created_at, :updated_at]

  has_many   :projects
  belongs_to :user
end
