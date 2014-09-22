# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever


set :environment, :development

# path-to-bundler를 자신의 경로로 변경해야 함.
set :bundler_path, "path-to-bundler"

set :output, {:error => 'log/error.log', :standard => 'log/cron.log'}

job_type :runner, "cd :path && :bundler_path/bundle exec rails runner -e :environment ':task' :output"

every 1.minute do
  runner "Cron::TestRunner.show_me"
end
