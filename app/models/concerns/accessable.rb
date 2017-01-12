# 创建资源并为创建者设置可访问此资源的权限

module Accessable
  extend ActiveSupport::Concern

  included do
    after_create :set_accesses

    private

    def set_accesses
      team_id =
        case self
        when Team
          self.id
        else
          self.team_id
        end

      resource = Resource.create(resourceable: self, team_id: team_id)
      Access.create(user_id: self.user_id, resource_id: resource.id)
    end
  end
end
