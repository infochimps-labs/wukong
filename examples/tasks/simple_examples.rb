#
# Rake examples -- see http://rake.rubyforge.org/files/doc/rakefile_rdoc.html
#


# --------------------------------------------------------------------------
#
# ## Rules ##
#

directory "tmp"

# explicit

file "a.o" => "tmp" do |t|
  sh "echo 'compiled code for a.c' > 'tmp/a.o'"
end

file "b.o" => "tmp" do |t|
  sh "echo 'compiled code for b.c' > 'tmp/b.o'"
end

# ... or by rule

# rake mycode.o
rule '.c' do |t|
  puts 'rule: ' + t.name
end

rule '.o' => ['.c'] do |t|
  sh "echo cc #{t.source} -c -o #{t.name}"
end

file "prog" => ["tmp", "a.o", "b.o"] do |t|
  sh "echo 'this is the program' > 'tmp/prog'"
end



# --------------------------------------------------------------------------
#
# ## Namespace ##
#

namespace "main" do
  desc "build"
  task :build do |t|
    puts t
  end
end

namespace "samples" do
  desc "build"
  task :build do
    puts t
  end
end

desc "top build"
task :build => ["main:build", "samples:build"]

# --------------------------------------------------------------------------
#
# ## Params ##
#

# rake name[ruby,rails]
# rake name[,radiant]
task :name, [:first_name, :last_name] do |t, args|
  args.with_defaults(:first_name => "John", :last_name => "Dough")
  puts "First name is #{args.first_name}"
  puts "Last  name is #{args.last_name}"
end

# --------------------------------------------------------------------------
#
# ## Programmatic modification ##
#

# rake doit
# rake dont doit
task :doit do
  puts "DONE"
end

task :dont do
  Rake::Task[:doit].clear
end
