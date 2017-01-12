class EventsController < ApplicationController
  include EventsGroupable

  def index
    current_user_resource_ids = current_user.resource_ids
    team_events               = Event.where(team_id: params[:team_id], resource_id: current_user_resource_ids).order(id: :desc).page(params[:page]).per(50)
    @team_events_hash         = team_events_hash_with(team_events)
  end
end
