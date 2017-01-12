module EventsHelper
  # 设置完成日期文案
  def event_due_at_pre(pre_date)
    pre_date.nil? ? '没有截止日期' : Date.parse(pre_date)
  end

  # 设置完成日期文案
  def event_due_at_after(after_date)
    after_date.nil? ? '没有截止日期' : Date.parse(after_date)
  end

  # 指派任务文案
  def event_assign_with(prev, after)
    return "给 #{after} 指派了任务" if prev.nil?
    return "取消了 #{prev} 的任务" if after.nil?
    return "将 #{prev} 的任务指派给 #{after}"
  end

  # 动作名称
  def event_action_name_with(action)
    I18n.t(action, scope: 'activerecord.attributes.event.action_enum', default: '无')
  end

  def event_trackable_type
    {Team: '团队', Project: '项目', Todo: '任务'}
  end
end
