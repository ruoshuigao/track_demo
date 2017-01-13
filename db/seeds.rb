# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

DEFAULT_PASSWORD = '12345678'
CREATED_AT       = DateTime.current - 1.day

def main
  puts 'Seeding data...'

  seed_users_data
  seed_teams_data
  seed_projects_data
  seed_todos_data
  seed_actions_data
  correct_events_data

  puts 'Seed data done.'
end

def seed_users_data
  users = [
    { name: 'ava',     email: 'ava@test.com' },
    { name: 'rainbow', email: 'rainbow@test.com' }
  ]

  puts 'Createing users...'
  users.each do |attributes|
    User.find_or_initialize_by(email: attributes[:email]).tap do |user|
      user.name                  = attributes[:name]
      user.password              = DEFAULT_PASSWORD
      user.password_confirmation = DEFAULT_PASSWORD
      user.save!
    end
  end
  puts 'Create users done.'
end

def seed_teams_data
  user_id = User.first.id

  puts 'Creating teams...'
  Team.find_or_create_by!(title: 'first_team', user_id: user_id)
  puts 'Cread teams done.'
end

def seed_projects_data
  team_id = Team.first.id
  user_id = User.first.id
  projects = [
    {name: 'first_project',  description: 'first project for test'},
    {name: 'second_project', description: 'second project for test'},
  ]
  puts 'Creating projectings...'
  projects.each do |attributes|
    Project.find_or_initialize_by(user_id: user_id, team_id: team_id, name: attributes[:name]).tap do |project|
      project.description = attributes[:description]
      project.save!
    end
  end
  puts 'Creating projectings done.'
end

def seed_todos_data
  first_user       = User.first
  last_user        = User.last
  first_project_id = Project.first.id
  last_project_id  = Project.last.id

  puts 'Creating todos...'
  10.times do |n|
    Todo.find_or_initialize_by(name: "todo_#{n+1}").tap do |todo|
      if n <= 5
        if n.even?
          todo.priority = '!!!'
          todo.tag      = 'API'
        end
        todo.project_id = last_project_id
        todo.user_id    = last_user.id
        todo.user_name  = last_user.name
      else
        todo.project_id = first_project_id
        todo.user_id    = first_user.id
        todo.user_name  = first_user.name
      end
      todo.save!
    end
  end
  puts 'Creating todos done.'
end

def seed_actions_data
  first_user = User.first
  last_user  = User.last
  first_todo = Todo.first
  last_todo  = Todo.last
  project    = Project.last

  puts 'Creating actions...'
  # 修改任务状态
  first_todo.do_running!  if first_todo.may_do_running?
  first_todo.do_pause!    if first_todo.may_do_pause?
  last_todo.do_completed! if last_todo.may_do_completed?
  last_todo.do_reorder!   if last_todo.may_do_reorder?
  # 为任务分配责任人与完成时间
  last_todo.update_attributes(assignee_id: last_user.id, assignee_name: last_user.name)
  last_todo.update_attributes(assignee_id: first_user.id, assignee_name: first_user.name)
  first_todo.update_attribute(:due_at, (DateTime.current + 2.days))
  first_todo.update_attribute(:due_at, (DateTime.current + 3.days))

  # 为任务添加评论
  3.times do |n|
    if n.even?
      Comment.create(commentable: first_todo, user_id: last_user.id, user_name: last_user.name, content: 'comment first todo')
    else
      Comment.create(commentable: last_todo, user_id: last_user.id, user_name: last_user.name, content: 'comment first todo')
    end
  end

  # 删除评论
  comment = Comment.first
  comment.destroy

  # 项目归档
  project.do_archived! if project.may_do_archived?
  # 项目重新激活
  project.do_unarchived! if project.may_do_unarchived?

  puts 'Creating actions done.'
end

# 由于event中操作者被指定为User.first，event中记录的操作者与实际数据不符，对event中操作者进行纠正
def correct_events_data
  puts 'Bein corret events data...'

  # 修改 team 与 第一个 project 的创建时间，使数据显示更真实
  team = Team.first
  team.update_column(:created_at, CREATED_AT)
  team_event = Event.find_by(trackable: team)
  team_event.update_column(:created_at, CREATED_AT) if team_event

  project = Project.first
  project.update_column(:created_at, CREATED_AT)
  project_event = Event.find_by(trackable: project)
  project_event.update_column(:created_at, CREATED_AT) if project_event

  # 纠正 event 数据操作者，使数据更真实
  Event.all.each do |event|
    event_trackable = event.trackable
    event.update_columns(actor_id: event_trackable.user_id, actor_name: event_trackable&.user_name) unless event.actor_id == event_trackable.user_id
  end

  puts 'Corret events data done.'
end

# 调用主执行方法
main
