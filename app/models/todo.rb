class Todo < ApplicationRecord
  include AASM
  include Eventable

  acts_as_paranoid
  has_event skip: [:created_at, :updated_at]

  belongs_to :project
  belongs_to :user
  belongs_to :assignee, class_name: 'User'

  # 任务状态机
  aasm column: :status, no_direct_assignment: true do
    state :status_fresh, initial: true # 新建
    state :status_running              # 开始处理
    state :status_pause                # 暂停
    state :status_completed            # 完成
    state :status_reorder              # 重新打开

    # 开始处理
    event :do_running do
      transitions from: [:status_fresh, :status_pause, :status_reorder], to: :status_running
    end

    # 暂停
    event :do_pause do
      transitions from: :status_running, to: :status_pause
    end

    # 完成
    event :do_completed do
      transitions from: [:status_fresh, :status_running, :status_pause, :status_reorder], to: :status_completed
    end

    # 重新打开
    event :do_reorder do
      transitions from: :status_completed, to: :status_reorder
    end
  end
end
