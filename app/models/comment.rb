class Comment < ApplicationRecord
  include Eventable

  acts_as_paranoid

  has_event on: [], skip: [:created_at, :updated_at]

  belongs_to :commentable, polymorphic: true

  after_create   :generate_create_event
  before_destroy :generate_destroy_event

  private

  def generate_create_event
    commentable.create_event(:create_comment, { comment_content: content })
  end

  def generate_destroy_event
    commentable.create_event(:destroy_comment, { comment_content: content })
  end
end
