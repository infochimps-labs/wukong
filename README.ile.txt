\

To run mapper on its own:
  cat ./wukong.rb | ./examples/word_count.rb --map | more


To have the map or the reduce be just 'cat', instatiate your
Script class with 'nil' as the mapper or reducer class, as
appropriate.


class Script < Wukong::Script
  def reduce_command
    '/usr/bin/uniq'
  end
end
