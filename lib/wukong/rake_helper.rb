require 'rake'
require 'wukong'

task :environment => [] do
  Wukong::Runner.run
end
