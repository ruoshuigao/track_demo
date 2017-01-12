# 构造 events 数据结构
module EventsGroupable
  extend ActiveSupport::Concern

  # 构造 events 数据 hash
  def team_events_hash_with(events)
    structure_data_arr     = []
    grouped_events_by_date = grouped_events_by_date(events)
    grouped_events_by_date.each_pair do |created_date, events_arr|
      structure_data_arr.push({ created_date: created_date, items: events_day_hash_with(events_arr) })
    end
    structure_data_arr
  end

  private

  def events_day_hash_with(grouped_events)
    grouped_events.map do |events_arr|
      {
        category:      events_arr.first.data['content']['ancestor_name'],
        ancestor_id:   events_arr.first.ancestor_id,
        ancestor_type: events_arr.first.ancestor_type,
        events:        events_hash_with(events_arr)
      }
    end
  end

  def events_hash_with(events_arr)
    events_arr.map do |event|
      {
        trackable_id:    event.trackable_id,
        trackable_type:  event.trackable_type,
        trackable_name:  event.data['content']['trackable_name'],
        action:          event.action,
        actor_id:        event.actor_id,
        actor_name:      event.actor_name,
        actor_avatar:    event.actor_avatar,
        created_at:      event.created_at.strftime('%R'),
        prev:            event.data['content']['prev'],
        after:           event.data['content']['after'],
        comment_content: event.data['content']['comment_content'],
        priority:        event.data['content']['priority'],
        tag:             event.data['content']['tag']
      }
    end
  end

  # 根据 event 生成的日期，对 events 分组
  def grouped_events_by_date(events)
    # 按 events 生成的日期分组
    grouped_events_by_date = events.group_by {|event| event.created_at.to_date}
    # 对分组后的数据进行重组，value 值为根据祖先分后数据
    grouped_events_by_date.each_pair do |created_date, events_arr|
      grouped_events_by_date[created_date] = grouped_events_by_ancestor(events_arr)
    end

    grouped_events_by_date
  end

  # 根据 event 生成的时间及 event 祖先，对 event 进行分组
  # 数据返回格式举例： [[1,1,1], [2,2], [1]]
  def grouped_events_by_ancestor(events)
    events.reduce([]) do |group_arr, event|
      if consecutive?(group_arr.flatten.last, event)
        (group_arr.last << event; group_arr)
      else
        group_arr.push([event])
      end
    end
  end

  # 根据 event 数据祖先类型及祖先 id 判断 event 数据是否连续
  def consecutive?(prev_event, event)
    prev_event&.ancestor_id == event.ancestor_id && prev_event&.ancestor_type == event.ancestor_type
  end
end
