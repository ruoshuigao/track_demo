require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  setup do
    @current_user = RequestStore.store[:current_user] ||= users(:ava)
  end

  test "should get index"do
    team = teams(:first_team)
    get :index, params: {team_id: team.id}
    assert_response :success
  end

  test "should retun one team data when just create one team" do
    team = teams(:first_team)
    team_event = events(:first_team_event)

    get :index, params: {team_id: team.id, user_id: @current_user.id}

    team_events_hash = assigns(:team_events_hash)
    assert_equal team_events_hash.length, 1
    assert_equal team_events_hash.first[:created_date], team_event.created_at.to_date
    assert_equal team_events_hash.first[:items].length, 1
    assert_equal team_events_hash.first[:items].first[:category], team.title
    assert_equal team_events_hash.first[:items].first[:events].length, 1
    assert_equal team_events_hash.first[:items].first[:events].first[:trackable_id], team.id
    assert_equal team_events_hash.first[:items].first[:events].first[:action], 'create'
  end

  test "should retun current user events belongs to this team" do
    team = teams(:second_team)

    get :index, params: {team_id: team.id, user_id: @current_user.id}

    team_events_hash = assigns(:team_events_hash)
    assert_equal team_events_hash.length, 2

    # 第一个节点数据
    assert_equal team_events_hash.first[:created_date], events(:second_team_event).created_at.to_date
    assert_equal team_events_hash.first[:items].length, 2

    assert_equal team_events_hash.first[:items].first[:category], events(:first_project_event).data['content']['ancestor_name']
    assert_equal team_events_hash.first[:items].first[:events].length, 1
    assert_equal team_events_hash.first[:items].first[:events].first[:trackable_id], projects(:first_project).id
    assert_equal team_events_hash.first[:items].first[:events].first[:action], 'create'

    assert_equal team_events_hash.first[:items].last[:category], team.title
    assert_equal team_events_hash.first[:items].last[:events].length, 1
    assert_equal team_events_hash.first[:items].last[:events].first[:trackable_id], teams(:second_team).id
    assert_equal team_events_hash.first[:items].last[:events].first[:action], 'create'

    # 第二个节点数据
    assert_equal team_events_hash.last[:created_date], Date.current
    assert_equal team_events_hash.last[:items].length, 3

    assert_equal team_events_hash.last[:items].first[:category], events(:first_project_event).data['content']['ancestor_name']
    assert_equal team_events_hash.last[:items].first[:events].length, 2
    assert_equal team_events_hash.last[:items].first[:events].first[:trackable_id], todos(:fresh_todo).id
    assert_equal team_events_hash.last[:items].first[:events].first[:action], 'create'
    assert_equal team_events_hash.last[:items].first[:events].last[:trackable_id], todos(:fresh_todo).id
    assert_equal team_events_hash.last[:items].first[:events].last[:action], 'status_transition'

    assert_equal team_events_hash.last[:items][1][:events].length, 1
    assert_equal team_events_hash.last[:items][1][:events].first[:trackable_id], projects(:second_project).id
    assert_equal team_events_hash.last[:items][1][:events].first[:action], 'create'

    assert_equal team_events_hash.last[:items].last[:events].length, 1
    assert_equal team_events_hash.last[:items].last[:events].first[:trackable_id], todos(:fresh_todo).id
    assert_equal team_events_hash.last[:items].last[:events].first[:action], 'status_transition'
  end
end
