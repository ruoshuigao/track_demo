class EventsController < ApplicationController
  include EventsGroupable

  def index
    team_events       = Event.where(team_id: params[:team_id]).order(id: :desc)
    @team_events_hash = team_events_hash_with(team_events)
  end
end
