# require Pathname.path_to(:examples, 'graph/union_find')
# require 'gorillib/model/serialization'

# class Airfare
#   include Gorillib::Model

#   field :from,  String
#   field :into,  String
#   field :price, Integer
#   field :from_name, String
#   field :into_name, String

#   def undirected_edge
#     [from, into].sort
#   end
# end


# airfares = File.open(Pathname.path_to(:data, 'graph/airfares.tsv')).
#   readlines.
#   map{|line| line.split("\t").map(&:strip) }.
#   map{|vals| Airfare.from_tuple(*vals) }

# # airfares.sort_by(&:undirected_edge).each do |airfare|
# #   puts "%-7s\t%-7s\t%-7s\t%-7s\t%d" % [*airfare.undirected_edge, airfare.from, airfare.into, airfare.price]
# # end

# cities = airfares.map(&:from).uniq | airfares.map(&:into)

# edges   = {}
# airfares.each do |airfare|
#   edge = airfare.undirected_edge
#   edges[edge] = airfare.price unless edges.include?(edge) && edges[edge] <= airfare.price
# end

# mst = Hash.new{|h,k| h[k] = {} }
# forest = Wukong::Widget::DisjointForest.new

# edges.sort_by(&:last).each do |(city_a, city_b), price|
#   forest.add(city_a) if not forest.include?(city_a)
#   forest.add(city_b) if not forest.include?(city_b)
#   next if forest.find(city_a) == forest.find(city_b)
#   forest.union(city_a, city_b)
#   mst[city_a][city_b] = price
# end

# $mst_both = Hash.new{|h,k| h[k] = {} }
# mst.each{|city_a, hsh| hsh.each{|city_b, price|
#     $mst_both[city_a][city_b] = price
#     $mst_both[city_b][city_a] = price
# }}
# def dfs(city, seen)
#   seen << city
#   children = $mst_both[city].keys - seen
#   # [children, children.map{|child| dfs(child, seen) } ]
#   children.map{|child| [ child, dfs(child, seen) ] }
# end
# sorted_cities = ['LAS', dfs('LAS', [])]

# gv_filename = Pathname.path_to(:tmp, 'airfares_mst')
# File.open("#{gv_filename}.dot", 'w') do |gv_file|
#   gv_file.puts "graph AirfareMST {\n  label=\"#{Time.now}\"; height= 800; labelloc = t; mindist = 1.5 ; "
#   # gv_file.puts "mode = hier;"
#   gv_file.puts 'node [ shape = "plaintext" ]; '
#   sorted_cities.flatten.each{|city| gv_file.puts "  #{city};" }
#   mst.sort_by(&:first).each do |from, hsh|
#     hsh.sort_by(&:first).each do |into, price|
#       gv_file.puts " %-7s -- %-7s [ label = \"%d\" ];" % [from, into, price]
#     end
#   end
#   gv_file.puts "}"
# end
# `neato -Tpng #{gv_filename}.dot -o #{gv_filename}.png`
