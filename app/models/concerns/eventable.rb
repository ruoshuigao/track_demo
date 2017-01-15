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
  }.freeze

  # 记录发生修改的字段
  CHANGE_SITE = {
    Project: ['status'],
    Todo:    ['status', 'assignee_id', 'due_at']
  }.freeze

  # Action 映射关系
  ACTION_HASH = {
    status:      'status_transition',
    assignee_id: 'assign',
    due_at:      'set_due_at'
  }.freeze

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
      event_type    = self.class.name.to_sym
      resource_id   = SPECIAL_SITES[event_type][:resourceable_id].split(".").inject(self){|obj, met| obj.send(met)}

      ancestor_hash[:ancestor_id]          = SPECIAL_SITES[event_type][:ancestor_id].split(".").inject(self){|obj, met| obj.send(met)}
      ancestor_hash[:ancestor_type]        = SPECIAL_SITES[event_type][:ancestor_type]
      ancestor_hash[:team_id]              = SPECIAL_SITES[event_type][:team_id].split(".").inject(self){|obj, met| obj.send(met)}
      ancestor_hash[:resource_id]          = Resource.find_by(resourceable_id: resource_id)&.id

      meta_hash[:content][:trackable_name] = SPECIAL_SITES[event_type][:trackable_name].split(".").inject(self){|obj, met| obj.send(met)}
      meta_hash[:content][:ancestor_name]  = SPECIAL_SITES[event_type][:ancestor_name].split(".").inject(self){|obj, met| obj.send(met)}
      meta_hash[:content][:priority]       = send("#{SPECIAL_SITES[event_type][:priority]}") if SPECIAL_SITES[event_type][:priority]
      meta_hash[:content][:tag]            = send("#{SPECIAL_SITES[event_type][:tag]}")      if SPECIAL_SITES[event_type][:tag]
      [ancestor_hash, meta_hash]
    end

    def event_record_update
      object_attrs_for_event_with_update.each_pair do |event_update_action, object_attr|
        create_event(event_update_action, object_attr)
      end
    end

    # 发生修改的数据
    def object_attrs_for_event_with_update
      object_attrs_changed = changes.except(*self.event_options[:skip])
      return if object_attrs_changed.empty?

      return unless CHANGE_SITE.keys.include?(self.class.name.to_sym)

      changed_attributes_arr = CHANGE_SITE[self.class.name.to_sym] & changes.keys
      return if changed_attributes_arr.empty?

      changed_hash = {}
      changed_attributes_arr.each do |attribute|
        if attribute == 'assignee_id'
          if changes[:assignee_name]
            changed_hash[ACTION_HASH[attribute.to_sym]] = { prev: changes[:assignee_name].first, after: changes[:assignee_name].last }
          else # 任务分配的责任人同名
            changed_hash[ACTION_HASH[attribute.to_sym]] = { prev: self.assignee_name, after: self.assignee_name }
          end
        else
          changed_hash[ACTION_HASH[attribute.to_sym]] = { prev: changes[attribute.to_sym].first, after: changes[attribute.to_sym].last }
        end
      end

      changed_hash
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
