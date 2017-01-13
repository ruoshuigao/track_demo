class Resource < ApplicationRecord
  belongs_to :resourceable, polymorphic: true
end
