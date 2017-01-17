class EventsController < ApplicationController
  include EventsGroupable

  def index
    current_user_resource_ids = current_user.resource_ids
    @per_page       = 50
    page_num        = params[:page].to_i
    all_team_events = Event.where(team_id: params[:team_id], resource_id: current_user_resource_ids).order(id: :desc)
    @events_count   = all_team_events.count
    team_events =
      if page_num <= 1
        all_team_events.limit(@per_page)
      else
        all_team_events.offset(@per_page * (page_num - 1)).limit(@per_page)
      end
    @team_events_hash = team_events_hash_with(team_events)
    @total_page       = (@events_count / @per_page.to_f).ceil

    if request.xhr?
      render partial: 'team', locals: { team_events_hash: @team_events_hash }
    end
  end
end
