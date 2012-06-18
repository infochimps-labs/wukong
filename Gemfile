source          'http://rubygems.org'

gem 'configliere', :path => '../configliere'
gem 'gorillib',    :path => '../gorillib'

gem 'home_run',    :platform => :mri, :require=>'date'

group :profiling do
  gem 'perftools.rb', :platform => :mri
end

group :support do
  gem   'guard',       ">= 1.0"
  gem   'guard-rspec', ">= 0.6"
  gem   'simplecov',   ">= 0.5"
  gem   'pry'
end

gemspec
