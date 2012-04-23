require 'wukong/job'
require 'wukong/rails_compat'

Wukong.job(:accounts) do

  # Before this task is run, the `:depends => :environment` dependency invokes the
  # `:environment` rake task from Rails (thus loding the Rails runtime
  # environment)
  task :email_expiring, :depends => :environment do
    desc "Email expiring accounts to let them know"
    date = ENV['from'] ? Date.parse(ENV['from']) : Date.today
    Account.notify_expiring(date)
  end

  task :database_credentials do
    #
    directory('config')
    # * `create` -- runs if missing, does nothing if exists
    # * `delete` --
    # * `update` -- Move an existing one out of the way
    #
    file('config/database.yml') do
      desc      ''
      cp        'config/database.example.yml', 'config/database.yml'
    end
  end

end
