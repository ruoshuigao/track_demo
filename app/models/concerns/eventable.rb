# 追踪记录团队、项目、任务等各类操作 event

module Eventable
  extend ActiveSupport::Concern

  SPECIAL_SITES = {
    Team: {
      ancestor_id:    'id',
      ancestor_type:  'Team',
      team_id:         'id',
      resourceable_id: 'id',
      trackable_name:  'title',
      ancestor_name:   'title'
    },
    Project: {
      ancestor_id:     'id',
      ancestor_type:   'Project',
      team_id:         'team_id',
      resourceable_id: 'id',
      trackable_name:  'name',
      ancestor_name:   'name'
    },
    Todo: {
      ancestor_id:     'project_id',
      ancestor_type:   'Project',
      team_id:         'project.team_id',
      resourceable_id: 'project_id',
      trackable_name:  'name',
      ancestor_name:   'project.name',
      priority:        'priority',
      tag:             'tag'
    },
    Comment: {
      ancestor_id:     'commentable_id',
      ancestor_type:   'commentable_type',
      team_id:         'commentable.project.team_id',
      resourceable_id: 'commentable.project_id',
      trackable_name:  'content',
      ancestor_name:   'commentable.name'
    }
  }

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
      ancestor_data_hash, meta_data_hash = meta_data
      meta_data_hash[:content].merge!(item_data)
      options = {
        actor_id:      event_actor&.id,
        actor_name:    event_actor&.name,
        actor_avatar:  event_actor&.avatar,
        action:        action.to_s,
        data:          meta_data_hash,
        ip:            event_actor_ip,
        user_agent:    event_actor_user_agent,
        ancestor_id:   ancestor_data_hash[:ancestor_id],
        ancestor_type: ancestor_data_hash[:ancestor_type],
        team_id:       ancestor_data_hash[:team_id],
        resource_id:   ancestor_data_hash[:resource_id]
      }
      events.create!(options)
    end

    private

    def meta_data
      meta_hash     = {content: {}}
      ancestor_hash = {}
      resource_id   = SPECIAL_SITES[self.class.name.to_sym][:resourceable_id].split(".").inject(self){|obj, met| obj.send(met)}

      ancestor_hash[:ancestor_id]          = SPECIAL_SITES[self.class.name.to_sym][:ancestor_id].split(".").inject(self){|obj, met| obj.send(met)}
      ancestor_hash[:ancestor_type]        = SPECIAL_SITES[self.class.name.to_sym][:ancestor_type]
      ancestor_hash[:team_id]              = SPECIAL_SITES[self.class.name.to_sym][:team_id].split(".").inject(self){|obj, met| obj.send(met)}
      ancestor_hash[:resource_id]          = Resource.find_by(resourceable_id: resource_id)&.id

      meta_hash[:content][:trackable_name] = SPECIAL_SITES[self.class.name.to_sym][:trackable_name].split(".").inject(self){|obj, met| obj.send(met)}
      meta_hash[:content][:ancestor_name]  = SPECIAL_SITES[self.class.name.to_sym][:ancestor_name].split(".").inject(self){|obj, met| obj.send(met)}
      meta_hash[:content][:priority]       = send("#{SPECIAL_SITES[self.class.name.to_sym][:priority]}") if SPECIAL_SITES[self.class.name.to_sym][:priority]
      meta_hash[:content][:tag]            = send("#{SPECIAL_SITES[self.class.name.to_sym][:tag]}")      if SPECIAL_SITES[self.class.name.to_sym][:tag]
      [ancestor_hash, meta_hash]
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
        status_changed? ? { prev: changes[:status].first, after: changes[:status].last } : {}
      when Todo
        if status_changed?
          { prev: changes[:status].first, after: changes[:status].last }
        elsif assignee_id_changed?
          # 用户id不同，用户名相同的情况
          if changes[:assignee_name]
            { prev: changes[:assignee_name].first, after: changes[:assignee_name].last }
          else
            { prev: self.assignee_name, after: self.assignee_name }
          end
        elsif due_at_changed?
          { prev: changes[:due_at].first, after: changes[:due_at].last }
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
      else
        'update'
      end
    end

    # FIXME 无实际登录用户，用户数据硬编码
    def event_actor
      RequestStore.store[:current_user] ||= User.first
    end

    def event_actor_ip
      RequestStore.store[:paper_trail][:controller_info][:ip] if RequestStore.store[:paper_trail] && RequestStore.store[:paper_trail][:controller_info]
    end

    def event_actor_user_agent
      RequestStore.store[:paper_trail][:controller_info][:user_agent].try(:truncate, 1000) if RequestStore.store[:paper_trail] && RequestStore.store[:paper_trail][:controller_info]
    end
  end
end
