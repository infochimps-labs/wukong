* http://www.tasteofhome.com/Recipes/Fresh-Cherry-Pie
* [Cherry Pie](http://www.foodgeeks.com/recipes/1014) by Zenny on foodgeeks.com

### SERVINGS

6 to 8 servings scale / convert

### INGREDIENTS

#### Buttermilk Crust

3 cups flour
2 tbsp. sugar
1-1/2 tsp. salt
1/2 cup unsalted butter, cut up
6 tbsp. cold vegetable shortening
1/2 cup buttermilk

#### Filling

4 cups tart cherries
1-1/2 cups sugar
1/3 cup cornstarch
1 dash salt
2 tbsp. butter, cut up

### INSTRUCTIONS

### Make crust:

* Combine flour, sugar and salt. 
* Add butter and shortening and mix until mixture resembles coarse crumbs. 
* Gradually add buttermilk. 

* Divide pastry into 2 balls, one slightly larger than the other. 
* Flatten into two disks. 
* Wrap and refrigerate 30 minutes.

### Make filling:

* Drain cherries, reserving 1/2 cup juice. 
* Whisk together sugar, cornstarch and salt in saucepan. 
* Whisk in reserved cherry juice. 
* Bring to boil over medium heat; 
  - boil, stirring, 2 to 30 minutes until slightly thickened. 
* Remove from heat; stir in cherries and butter. 
* Cool.

### Assemble

* On lightly floured surface, roll larger pastry disk into 12-inch circle. 
  - Fit into a 9-inch pie plate, leaving 3/4-inch overhang. 
* Spoon filling into pastry. 
* Roll remaining pastry into a 10-inch circle; place on top of filling. 
* Press edges together; trim and flute. 
* With a small knife, 
  - cut decorations from scraps and place on top of pie. 
  - Cut vents in top. 

### Bake

* Arrange a jelly-roll pan on center rack of oven. 
* Heat oven to 425°. 
* Place pie on jelly-roll pan and bake 15 minutes. 
* Reduce oven temperature to 375°. 
* Bake 55 minutes more until filling is bubbly.
* Remove from oven, cool on a wire rack



__________________________________________________________________________

Below is an example of a simple Rake script to build a C HelloWorld program.

      file 'hello.o' => ['hello.c'] do
        sh 'cc -c -o hello.o hello.c'
      end
      file 'hello' => ['hello.o'] do
        sh 'cc -o hello hello.o'
      end
  
Below is an example of a simple Rake recipe

    namespace :cake do
      desc 'make pancakes'
      task :pancake => [:flour,:milk,:egg,:baking_powder] do
         puts "sizzle"
      end
      task :butter do
        puts "cut 3 tablespoons of butter into tiny squares"
      end
      task :flour => :butter do
        puts "use hands to knead butter squares into 1{{frac|1|2}} cup flour"
      end
      task :milk do
        puts "add 1{{frac|1|4}} cup milk"
      end
      task :egg do
       puts "add 1 egg"
      end
      task :baking_powder do
       puts "add 3{{frac|1|2}} teaspoons baking powder"
      end
    end