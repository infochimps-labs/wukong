module Wukong

  #
  # Let `Wukong::Job`s invoke and depend on `Rake::Task`s.
  #
  # for example, Rails defines the `:environment` task:
  #
  #     task :email_expiring, :depends => :environment do
  #       desc "Email expiring accounts to let them know"
  #       date = ENV['from'] ? Date.parse(ENV['from']) : Date.today
  #       Account.notify_expiring(date)
  #     end
  #
  #
  module RakeCompat
  end
end
