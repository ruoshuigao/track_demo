require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  test "should get index"do
    team = teams(:first_team)
    get :index, params: {team_id: team.id}
    assert_response :success
  end

  test "should retun one team data when just create one team" do
    team = teams(:first_team)
    team_event = events(:first_team)
    team_event.trackable = team
    team_event.team_id   = team.id
    team_event.save!

    get :index, params: {team_id: team.id}

    team_events_hash = assigns(:team_events_hash)
    assert_equal team_events_hash.length, 1
    assert_equal team_events_hash.first[:created_date], team_event.created_at.to_date
    assert_equal team_events_hash.first[:items].length, 1
    assert_equal team_events_hash.first[:items].first[:category], team.title
    assert_equal team_events_hash.first[:items].first[:events].length, 1
    assert_equal team_events_hash.first[:items].first[:events].first[:trackable_id], team.id
    assert_equal team_events_hash.first[:items].first[:events].first[:action], 'create'
  end
end
