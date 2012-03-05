require File.expand_path('../../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe 'rake compatibility', :helpers => true do
  it 'loads rake'
  it 'warns if the rake DSL is included at global level'

  it 'plays nice with Rails'
end
