# README

## Install

* Ruby version
    1. `ruby-2.3.1`

* Configuration(copy and edit sample file)
    1. `config/database.yml`
    2. `config/application.yml`

* Database creation
    1. `bundle exec rake db:drop`  (删除数据库, 如果已有数据库)
    1. `bundle exec rake db:setup` (创建数据库, 初始化 Seed 数据)
    1. 或者使用 `bundle exec rake db:reset`, 包含了上面的 `drop` 和 `setup`

* How to run the test suite
    1. `bundle exec rake test test/`

##  Event(操作事件)

* 使用方法
  1. 自动创建`event`
    `include Eventable`
    * 直接引用，不需要过滤指定字段: `has_event`
    * 指定 `action`: `has_event on: [:create]`
    * 过滤指定字段: `has_event skip: [:过滤字段1, :过滤字段 2]`
    * 以上若指定 `action` 则只创建指定 `action` 的 `event` , 否则对 `create`, `update`, `destroy`, `status_transaction` 等自动创建 `event`
  2. 手动创建`event`
    `object.create_event('action', data)`
    * 举例: `@todo.commentable.create_event(:destroy_comment, {comment_content: content})`
