require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  setup do
    @current_user = RequestStore.store[:current_user] ||= users(:ava)
    @project = projects(:first_project)
  end

  test 'should create an event when create a new project' do
    project = Project.create(team_id: teams(:second_team).id, name: 'test project', user_id: @current_user.id)
    event = Event.last
    assert_equal event.trackable_id, project.id
    assert_equal event.trackable_type, 'Project'
    assert_equal event.ancestor_id, project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'create'
    assert_equal event.team_id, project.team_id
    assert_equal event.data['content']['trackable_name'], project.name
    assert_equal event.data['content']['ancestor_name'], project.name
  end

  test 'should create an event when destroy project' do
    @project.destroy
    event = Event.last
    assert_equal event.trackable_id, @project.id
    assert_equal event.trackable_type, 'Project'
    assert_equal event.ancestor_id, @project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'destroy'
    assert_equal event.team_id, @project.team_id
    assert_equal event.data['content']['trackable_name'], @project.name
    assert_equal event.data['content']['ancestor_name'], @project.name
  end

  test 'should create an event when archived project' do
    @project.do_archived!

    assert @project.status_archived?
    event = Event.last
    assert_equal event.trackable_id, @project.id
    assert_equal event.trackable_type, 'Project'
    assert_equal event.ancestor_id, @project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, @project.team_id
    assert_equal event.data['content']['trackable_name'], @project.name
    assert_equal event.data['content']['ancestor_name'], @project.name
    assert_equal event.data['content']['after'], 'status_archived'
  end

  test 'should create an event when unarchived project' do
    project = projects(:second_project)
    project.do_unarchived!

    assert project.status_unarchived?
    event = Event.last
    assert_equal event.trackable_id, project.id
    assert_equal event.trackable_type, 'Project'
    assert_equal event.ancestor_id, project.id
    assert_equal event.ancestor_type, 'Project'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'status_transition'
    assert_equal event.team_id, project.team_id
    assert_equal event.data['content']['trackable_name'], project.name
    assert_equal event.data['content']['ancestor_name'], project.name
    assert_equal event.data['content']['after'], 'status_unarchived'
  end

  test 'should not create an event when update project' do
    assert_no_difference('Event.count') do
      @project.update(name: 'change name')
    end
  end

  test 'should create access for team creator when create a new team' do
    team    = teams(:first_team)
    project = Project.create(user_id: @current_user.id, team_id: team.id, name: 'access project')
    assert @current_user.resources.exists?(resourceable_id: project.id, team_id: team.id)
  end
end
