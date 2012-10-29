# module Hanuman
#   module Graphvizzer
#     include Gorillib::Builder

#     class Item
#       include Gorillib::Builder
#       alias_method :configurate, :receive!

#       field :name,  Symbol
#       field :label, String, :default => ->{ name }
#       field :owner, Item

#       def initialize(attrs={}, &block)
#         receive!(attrs, &block)
#       end

#       def depth
#         owner.depth + 1
#       end

#       def indent(adj=0)
#         "  " * (depth + adj)
#       end

#       def quote(str)
#         return str if str.to_s.include?('"')
#         %Q{"#{str}"}
#       end

#       def line(str, attrs={}, term=';')
#         if attrs.empty?
#           attr_strs = ''
#         else
#           width = 40 - indent.length
#           str = "%-#{width}s" % str
#           attr_strs = attrs.map{|attr, val| attrib(attr, val) }
#           attr_strs = "[ #{attr_strs.join(",")} ]"
#         end
#         [indent, str, attr_strs, term].join
#       end

#       def attrib(attr, val)
#         "#{attr} = #{val}"
#       end

#       def brace(str)
#         "#{indent}#{str} {"
#       end
#       def close_brace
#         "#{indent}}"
#       end

#       def pad_with_attributes(text, attrs=nil)
#         width = 40 - (2 * graph.depth)
#         if attrs then
#           attr_strs = attrs.map{|attr, val| attribute_str(attr, val) }
#           "%-#{width}s [ %s ]" % [text, attr_strs.join(',')]
#         else
#           text
#         end
#       end
#     end

#     class Node < Item
#       field :inslots,  Array, :default => []
#       field :outslots, Array, :default => []
#       field :shape, Symbol, :default => :Mrecord

#       def graph_attribs
#         {
#           :shape => shape,
#           :label => quote(shape =~ /record/ ? structured_label : label),
#           # :fixedsize => true, :width => "1.0",
#         }
#       end

#       def inslots_str
#         inslots.map{|slot| "<#{slot}>#{slot[0..0]}"}.join("|")
#       end

#       def outslots_str
#         outslots.map{|slot| "<out_#{slot}>#{slot[0..0]}"}.join("|")
#       end

#       def label
#         super.to_s.gsub(/_\d+$/, '').gsub(/[_\.]+/, "\\n")
#       end

#       def structured_label
#         str = "{"
#         str << "{" << inslots_str << "}|"  unless inslots.empty?
#         str << label
#         str << "|{" << outslots_str << "}" unless outslots.empty?
#         str << "}"
#       end

#       def to_s
#         str = []
#         str << line(quote(name), graph_attribs)
#         str.join("\n")
#       end
#     end

#     class Edge < Item
#       magic :from, String
#       magic :into, String

#       def to_s
#         str = ""
#         str << quote(from)
#         str << " -> "
#         str << quote(into)
#         line(str)
#       end
#     end

#     class Graph < Item
#       field :items, Array, :default => []
#       field :edges, Array, :default => []

#       def graph(name, attrs={})
#         obj = Graph.new(attrs.merge(:name => name, :owner => self))
#         items << obj
#         yield(obj) if block_given?
#         obj
#       end

#       def node(name, attrs={})
#         obj = Node.new(attrs.merge(:name => name, :owner => self))
#         items << obj
#         yield(obj) if block_given?
#         obj
#       end

#       def edge(from, into, from_slot=nil, into_slot=nil)
#         obj = Edge.new(
#           :name => name, :owner => self,
#           :from => from, :into => into,
#           :from_slot => from_slot, :into_slot => into_slot)
#         edges << obj
#         yield(obj) if block_given?
#         obj
#       end

#       def to_s
#         str = []
#         str << brace("subgraph #{quote("cluster_#{name}")}")
#         str << line(attrib("  label", quote(label)))
#         items.each do |item|
#           str << item.to_s
#         end
#         edges.each do |edge|
#           str << edge.to_s
#         end
#         str << close_brace
#         str.join("\n")
#       end
#     end

#     class Universe < Graph
#       field :orient, Symbol, :doc => 'one of :TB, :BT, :LR, :RL', :default => :TB
#       field :engine, Symbol, :default => :dot

#       def to_s
#         str = []
#         str << brace("digraph #{name}")
#         str << line("  rankdir = #{orient}")
#         items.each do |item|
#           str << item.to_s
#         end
#         str << close_brace
#         str.join("\n")
#       end

#       def depth() 0; end

#       def save(path, type=nil)
#         File.open "#{path}.dot", "w" do |f|
#           f.puts self.to_s
#         end
#         system "#{engine} -T#{type} #{path}.dot > #{path}.#{type}" if type
#       end
#     end
#   end
# end
