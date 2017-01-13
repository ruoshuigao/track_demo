require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  setup do
    @current_user = RequestStore.store[:current_user] ||= users(:ava)
  end

  test 'should create an event when create a new team' do
    team  = Team.create(title: 'test team', user_id: @current_user.id)
    event = Event.last
    assert_equal event.trackable_id, team.id
    assert_equal event.trackable_type, 'Team'
    assert_equal event.ancestor_id, team.id
    assert_equal event.ancestor_type, 'Team'
    assert_equal event.actor_id, @current_user.id
    assert_equal event.actor_name, @current_user.name
    assert_equal event.action, 'create'
    assert_equal event.team_id, team.id
    assert_equal event.data['content']['trackable_name'], team.title
    assert_equal event.data['content']['ancestor_name'], team.title
  end

  test 'should not create an event when destroy team' do
    team = teams(:second_team)
    assert_no_difference('Event.count') do
      team.destroy
    end
  end

  test 'should not create an event when update team' do
    team = teams(:second_team)
    assert_no_difference('Event.count') do
      team.update(title: 'change title')
    end
  end

  test 'should create access for team creator when create a new team' do
    team = Team.create(title: 'access team', user_id: @current_user.id)
    assert @current_user.resources.exists?(resourceable_id: team.id, team_id: team.id)
  end
end
