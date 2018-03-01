require File.expand_path('../config/application', __FILE__)

Rails.application.load_tasks

# Load tasks in app/tasks
Dir[Rails.root.join('app', 'tasks', '**', '*.rake')].each { |task_file| load task_file }
