require Pathname.path_to(:examples, 'graph/union_find')
require 'gorillib/model/serialization'

class Airfare
  include Gorillib::Model

  field :from,  String
  field :into,  String
  field :price, Integer
  field :from_name, String
  field :into_name, String
end


airfares = File.open(Pathname.path_to(:data, 'graph/airfares.tsv')).
  readlines.
  map{|line| line.split("\t").map(&:strip) }.
  map{|vals| Airfare.from_tuple(*vals) }

cities = airfares.map(&:from).uniq | airfares.map(&:into)

p cities.sort

mst = Hash.new{|h,k| h[k] = {} }
disjoint_forest = Wukong::Widget::DisjointForest.new

airfares.sort_by(&:price).each do |airfare|
  next if disjoint_forest.find(airfare.from) == disjoint_forest.find(airfare.into)
  disjoint_forest.union(airfare.from, airfare.into)
  mst[airfare.from][airfare.into] = airfare.price
end

p mst
p disjoint_forest
