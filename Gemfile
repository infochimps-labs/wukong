source 'http://rubygems.org'

gemspec

gem 'gorillib',    :path => '../gorillib'

group :development do
end

group :docs do
  gem 'RedCloth',    ">= 4.2",   :require => "redcloth"
  gem 'redcarpet',   ">= 2.1",   :platform => [:mri, :rbx]
  gem 'kramdown',                :platform => :jruby
end

# Gems for testing and coverage
group :test do
  gem 'simplecov',   ">= 0.5",   :platform => :ruby_19
  #
  gem 'oj',          ">= 1.2",   :platform => [:mri, :rbx]
  gem 'json',                    :platform => :jruby
end

# Gems you would use if hacking on this gem (rather than with it)
group :support do
  gem 'pry'
  gem 'perftools.rb',            :platform => :mri
  #
  gem 'guard',       ">= 1.0",   :platform => :ruby_19
  gem 'guard-rspec', ">= 0.6",   :platform => :ruby_19
  gem 'guard-yard',              :platform => :ruby_19
  if RUBY_PLATFORM.include?('darwin')
    gem 'rb-fsevent', ">= 0.9",  :platform => :ruby_19
  end
end
