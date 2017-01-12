require 'test_helper'

class TodoTest < ActiveSupport::TestCase
  setup do
    travel_to Date.new(2017, 01, 11)
    @current_user = RequestStore.store[:current_user] ||= users(:ava)
  end

  teardown do
    travel_back
  end

  test 'should reate an event when create a new todo' do
    project = projects(:todo_project)
    todo    = Todo.create(user_id: @current_user.id, user_name: @current_user.name, project_id: project.id, name: 'first test todo')
    event   = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'create'
    assert_equal event.team_id, project.team_id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], project.name
    assert_nil   event.data['content']['priority']
    assert_nil   event.data['content']['tag']
  end

  test 'should reate an event when create a new todo with priority and tag' do
    project = projects(:todo_project)
    todo    = Todo.create(user_id: @current_user.id, user_name: @current_user.name, project_id: project.id, name: 'first test todo', priority: '!!!', tag: 'API' )
    event   = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'create'
    assert_equal event.team_id, project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], project.name
    assert_equal event.data['content']['priority'], '!!!'
    assert_equal event.data['content']['tag'], 'API'
  end

  test 'should create an event when running a todo' do
    todo = todos(:fresh_todo)
    todo.do_running!
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should create an event when pause a todo' do
    todo = todos(:running_todo)
    todo.do_pause!
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should create an event when completed a todo' do
    todo = todos(:fresh_todo)
    todo.do_completed!
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should create an event when reorder a todo' do
    todo = todos(:completed_todo)
    todo.do_reorder!
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should create an event when assign a todo to an assignee' do
    todo     = todos(:fresh_todo)
    assignee = users(:rainbow)
    todo.update_attributes(assignee_id: assignee.id, assignee_name: assignee.name)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'assign'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_nil   event.data['content']['prev']
    assert_equal event.data['content']['after'], assignee.name
  end

  test 'should create an event when cancel a todo for an assignee' do
    todo = todos(:assigned_todo)
    todo.update_attributes(assignee_id: nil, assignee_name: nil)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'assign'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_nil   event.data['content']['after']
  end

  test 'should create an event when change a todo to another assignee' do
    todo          = todos(:assigned_todo)
    rainbow       = users(:rainbow)
    todo.update_attributes(assignee_id: rainbow.id, assignee_name: rainbow.name)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'assign'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_equal   event.data['content']['after'], rainbow.name
  end

  test 'should create an event when set due_at for a todo' do
    todo   = todos(:fresh_todo)
    due_at = '2017-01-12'
    todo.update_attributes(due_at: due_at)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'set_due_at'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_equal Date.parse(event.data['content']['after']).to_s, due_at
  end

  test 'should create an event when cancel a due_at' do
    todo = todos(:assigned_todo)
    todo.update_attributes(due_at: nil)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'set_due_at'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_nil   event.data['content']['after']
  end

  test 'should create an event when change due_at for a todo' do
    todo   = todos(:assigned_todo)
    due_at = '2017-01-12'
    todo.update_attributes(due_at: due_at)
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'set_due_at'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
    assert_equal Date.parse(event.data['content']['after']).to_s, due_at
  end

  test 'should create an event when destroy a todo' do
    todo = todos(:fresh_todo)
    todo.destroy
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'destroy'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should create an event when recover a todo' do
    todo = todos(:deleted_todo)
    todo.restore
    todo.create_event(:recover) # 删除后任务重新打开，需要手动添加 event 事件
    event = Event.last

    assert_equal event.trackable_id, todo.id
    assert_equal event.trackable_type, 'Todo'
    assert_equal event.ancestor_id, todo.project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'recover'
    assert_equal event.team_id, todo.project.team.id
    assert_equal event.data['content']['trackable_name'], todo.name
    assert_equal event.data['content']['ancestor_name'], todo.project.name
  end

  test 'should not create event when update todo base info' do
    todo = todos(:fresh_todo)
    assert_no_difference('Event.count') do
      todo.update(name: 'chang name')
    end
  end
end
