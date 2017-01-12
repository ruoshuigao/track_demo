class Project < ApplicationRecord
  include AASM
  include Eventable

  acts_as_paranoid
  has_event skip: [:created_at, :updated_at]

  # category_normal: 标准类型, category_kanban: 看板类型
  enum category: { category_normal: 0, category_kanban: 1 }

  belongs_to :team
  belongs_to :user
  has_many   :todos, dependent: :destroy

  # 项目状态机
  aasm column: :status, no_direct_assignment: true do
    state :status_fresh, initial: true # 新建
    state :status_archived             # 归档
    state :status_unarchived           # 激活

    # 归档
    event :do_archived do
      transitions from: [:status_fresh, :status_unarchived], to: :status_archived
    end

    # 归档后重新激活
    event :do_unarchived do
      transitions from: :status_archived, to: :status_unarchived
    end
  end
end
