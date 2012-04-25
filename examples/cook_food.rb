require File.expand_path('cook_food/kitchen', File.dirname(__FILE__))

Wukong.job :cherry_pie do

  pie_tin = cooking_container('pie tin')

  pie_tin.add 'cherries'

  chain(:pie) do
    oven.preheat(400)
    chain(:crust).create
    chain(:filling).create(ingredient('cherries', '1 quart'))

    # put filling in crust
    # seal lid
    # poke holes

    # put pie in oven

    # schedule removal at X oclock
    # turn off oven
    # put pie on cooler

    # slice pie
    # put on plate
    # add ice cream if Settings.ice_cream
    # serve
  end


  pig 'foo.pig', :map_tasks => 7, :cromulence => 12

  chain(:crust) do
    bowl  = cooking_container('medium mixing bowl')
    mixer = utensil('mixer')
    bowl.add ingredient('egg',   '2')
    bowl.add ingredient('flour', '2 cups')
    bowl.add ingredient('sugar', '1 cup')
    mixer.mix bowl, 'pie filling'
    #
    bowl.transfer_contents pie_tin
  end

  chain(:filling) do
    input :crust
    input :fruit
    bowl = utensil('medium bowl')
    bowl.add ingredient(fruit)
    bowl.add ingredient('sugar', '1 cup')
    utensil(:masher).mash bowl
  end

  chain(:soup) do
    stove = cooking_burner('medium')
    pot   = utensil('large sauce pot')
    water = ingredient('water', '1 quart')
    pot.add water
    stove.temperature 'hi'
    pot.put_on stove
    watch(:boiling) do                        # runs until condition met
      stop_when{ water.boiling? }             # delayed evaluation
    end
    chain(:prepare_vegetables) do
      chopped_onions   = ingredient(:onion, 'large').chop('medium dice')
      chopped_potatoes = ingredient(:potato, '3 large').chop('chunks')
    end
    wait_until(watch(:boiling))               # synchronize
    stove.temperature 'med'
    pot.add chopped_onions
    pot.add chopped_potatoes
    pot.add ingredient(:salt, '1 tbsp')
    wait_until timer('30 minutes')
    stove.off!
    pot.put_on utensil('trivet')
  end
end
