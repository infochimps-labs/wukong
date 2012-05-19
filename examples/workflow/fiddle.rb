


connect('split:top').into('flatten:ingredient')

combine << utensil('bowl') << ingredient('flour') << ingredient('salt') << ingredient('sugar') > ingredient('dough')


task 'package' do
  slot(:docs) << directory('docs')
  slot(:exe)  << action(:compiled)
end



wukong 'foo.rb', 'x.tsv', 'y.tsv', :reduce_tasks => 0, :min_split_size => '1M' > 'foo_out.tsv'



wukong 'combine.rb', 'x.tsv', 'y.tsv', :reduce_tasks => 0, :min_split_size => '1M' > :raw_pie

pig

wukong 'bake.rb', :raw_pie > :pie
