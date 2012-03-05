require File.expand_path('../spec_helper', File.dirname(__FILE__))
require 'wukong'

describe 'auto runner for scripts', :helpers => true do

  context 'at exit hook' do

    it 'defines a hook to run on exit'

    it 'does not run a script twice'

    it 'runs a script based on its invoked name (so that it works with symlinks)'

  end

end

describe 'wukong shell at exit hook' do
  it 'runs pry at correct point'
end
