require 'test_helper'

class TeamTest < ActiveSupport::TestCase
  test 'should create an event when create a new team' do
    team = Team.create(title: 'test team')
    event = Event.last
    assert_equal event.trackable_id, team.id
    assert_equal event.trackable_type, 'Team'
    assert_equal event.ancestor_id, team.id
    assert_equal event.ancestor_type, 'Team'
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
end
