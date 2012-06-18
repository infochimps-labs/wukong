source 'http://rubygems.org'


gem 'gorillib',    :path => '../gorillib'

gem 'home_run',    :platform => :mri, :require=>'date'

gemspec

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  #
  gem 'yard',        ">= 0.7"
  gem 'redcarpet',   ">= 2.1"
  #
  gem 'perftools.rb', :platform => :mri
end

# Gems for testing and coverage
group :test do
  gem 'rspec',       "~> 2.8"
  gem 'simplecov',   ">= 0.5", :platform => :ruby_19
  #
  gem 'guard',       ">= 1.0"
  gem 'guard-rspec', ">= 0.6"
  gem 'guard-yard'
  #
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9"
  end
end
