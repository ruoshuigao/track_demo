class Team < ApplicationRecord
  include Eventable

  has_event on: [:create], skip: [:created_at, :updated_at]
end
