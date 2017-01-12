require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  setup do
    @current_user = RequestStore.store[:current_user] ||= users(:ava)
  end

  test 'should create an event when create a new comment' do
    todo    = todos(:fresh_todo)
    comment = Comment.create(commentable: todo, user_id: @current_user.id, user_name: @current_user.name, content: 'first todo comment')
    event   = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project_id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'create_comment'
    assert_equal event.team_id, todo.project.team_id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_equal event.data['content']['comment_content'], comment.content
  end

  test 'should not create an event when destroy a comment' do
    todo    = todos(:fresh_todo)
    comment = comments(:todo_first_comment)
    comment.commentable = todo
    comment.save
    comment.destroy
    event   = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project_id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'destroy_comment'
    assert_equal event.team_id, todo.project.team_id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_equal event.data['content']['comment_content'], comment.content
  end

  test 'should not create an event when update comment content' do
    comment = comments(:todo_first_comment)
    assert_no_difference('Event.count') do
      comment.update_attribute(:content, 'change content')
    end
  end
end
