


connect('split:top').into('flatten:ingredient')

combine << utensil('bowl') << ingredient('flour') << ingredient('salt') << ingredient('sugar') > ingredient('dough')


task 'package' do
  slot(:docs) << directory('docs')
  slot(:exe)  << action(:compiled)
end
