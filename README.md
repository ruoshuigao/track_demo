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
