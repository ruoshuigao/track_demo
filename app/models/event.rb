class Event < ApplicationRecord
  belongs_to :trackable, polymorphic: true

  serialize :data, JSON
end
