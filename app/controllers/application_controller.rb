class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  # FIXME 无实际登录用户，用户数据硬编码
  def current_user
    RequestStore.store[:current_user] ||= User.first
  end
end
