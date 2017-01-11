# 追踪记录团队、项目、任务等各类操作 event

module Eventable
  extend ActiveSupport::Concern

  included do
    has_many :events, as: :trackable
  end

  module ClassMethods
    def has_event(options = {})
      options[:on]   ||= [:create, :update, :destroy]
      options[:skip] ||= []

      setup_model_for_event(options)
      setup_callbacks_from_options(options[:on])
    end

    def setup_model_for_event(options = {})
      send :include, InstanceMethods

      class_attribute :event_options
      self.event_options = options.dup
    end

    def setup_callbacks_from_options(options_on = [])
      options_on.each do |option|
        send "event_on_#{option}"
      end
    end

    # 创建后，记录 event
    def event_on_create
      after_create { create_event :create }
    end

    # 编辑信息后，记录 event
    def event_on_update
      after_update :event_record_update, unless: Proc.new { object_attrs_for_event_with_update.nil? }
    end

    # 删除信息前，记录 event
    def event_on_destroy
      before_destroy { create_event :destroy }
    end
  end

  module InstanceMethods

    # 手工记录操作事件
    def create_event(action, item_data = {})
      meta_data = {content: {trackable_name: extra_data[:trackable_name], ancestor_name: extra_data[:ancestor_name]}}
      meta_data[:content].merge!(item_data)
      options = {
        actor_id:      event_actor&.id,
        actor_name:    event_actor&.name,
        actor_avatar:  event_actor&.avatar,
        action:        action.to_s,
        data:          meta_data,
        ip:            event_actor_ip,
        user_agent:    event_actor_user_agent,
        ancestor_id:   extra_data[:ancestor_id],
        ancestor_type: extra_data[:ancestor_type],
        team_id:       extra_data[:team_id],
        resource_id: 1
      }
      events.create!(options)
    end

    private

    # TODO 添加权限时补充 resource_id
    def extra_data
      case self
      when Team
        {ancestor_id: self.id, ancestor_type: 'Team', team_id: self.id, trackable_name: self.title, ancestor_name: self.title}
      when Project
        {ancestor_id: self.id, ancestor_type: 'Project', team_id: self.team.id, trackable_name: self.name, ancestor_name: self.name}
      when Todo
        {ancestor_id: self.project.id, ancestor_type: 'Project', team_id: self.project.team.id, trackable_name: self.name, ancestor_name: self.project.name}
      end
    end

    def event_record_update
      create_event(event_update_action, object_attrs_for_event_with_update) unless event_update_action == 'update'
    end

    # 发生修改的数据
    def object_attrs_for_event_with_update
      object_attrs_changed = changes.except(*self.event_options[:skip])
      return if object_attrs_changed.empty?

      case self
      when Team
        {}
      when Project
        status_changed? ? {prev: changes[:status].first, after: changes[:status].last} : {}
      when Todo
        if status_changed? || assignee_id_changed? || due_at_changed?
          {prev: changes.values.first, after: changes.values.last}
        else
          {}
        end
      end
    end

    # 针对 update 请求，转换相应的 action
    def event_update_action
      if self.class.column_names.include?('status') && status_changed?
        'status_transition'
      elsif self.class.column_names.include?('assignee_id') && assignee_id_changed?
        'assign'
      elsif self.class.column_names.include?('due_at') && due_at_changed?
        'set_due_at'
      elsif self.class.column_names.include?('deleted_at') && deleted_at_changed?
        'recover'
      else
        'update'
      end
    end

    def event_actor
      RequestStore.store[:current_user]
    end

    def event_actor_ip
      RequestStore.store[:paper_trail][:controller_info][:ip] if RequestStore.store[:paper_trail] && RequestStore.store[:paper_trail][:controller_info]
    end

    def event_actor_user_agent
      RequestStore.store[:paper_trail][:controller_info][:user_agent].try(:truncate, 1000) if RequestStore.store[:paper_trail] && RequestStore.store[:paper_trail][:controller_info]
    end
  end
end
