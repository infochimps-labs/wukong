module Hanuman
  module Graphvizzer

    COL_1_WIDTH = 47
    
    class Item
      include Gorillib::Builder

      field :name,  Symbol
      field :label, String, :default => ->{ name }
      field :owner, Item

      def indent(adj=0)
        "  " * (depth + adj)
      end

      def depth
        owner.depth + 1
      end

      def quote(str)        str.to_s.include?('"') ? str : %Q{"#{str}"} ;  end
      def attrib(attr, val) "#{attr}=#{val}"    ; end
      def brace(str)        "#{indent}#{str} {" ; end
      def close_brace()     "#{indent}}"        ; end

      def line(str, attrs={}, term=';')
        if attrs.empty?
          attr_strs = ''
        else
          width = COL_1_WIDTH - indent.length
          str = "%-#{width}s" % str
          attr_strs = attrs.map{|attr, val| attrib(attr, val) }
          attr_strs = "\t[ #{attr_strs.join(", ")} ]"
        end
        [indent, str, attr_strs, term].join
      end
    end

    class Graph < Item
      field :items, Array, :default => []
      field :edges, Array, :default => []

      def to_s
        str = []
        str   << brace("subgraph#{quote("cluster_#{name}")}") ## subgraph "cluster_crust" {
        str   << line(attrib("  label", quote(label)))        ##   label="crust";
        items.each do |item|                                  ##
          str << item.to_s                                    ##   "cherry_pie.crust.small_bowl"        [ shape=Mrecord, label="{small\nbowl}" ];
        end                                                   ##   "cherry_pie.crust.flour"             [ shape=Mrecord, label="{flour}" ];
        edges.each do |edge|                                  ##
          str << edge.to_s                                    ##   "cherry_pie.crust.small_bowl"        -> "cherry_pie.crust.add_to_4";
        end                                                   ##   "cherry_pie.crust.flour"             -> "cherry_pie.crust.add_to_4";
        str << close_brace                                    ## }
        str.join("\n")
      end

      def graph(name, attrs={})
        obj = Graph.new(attrs.merge(:name => name, :owner => self))
        items << obj
        yield(obj) if block_given?
        obj
      end

      def node(name, attrs={})
        obj = Node.new(attrs.merge(:name => name, :owner => self))
        items << obj
        yield(obj) if block_given?
        obj
      end

      def edge(from, into, from_slot=nil, into_slot=nil)
        obj = Edge.new(
          :name => name, :owner => self,
          :from => from, :into => into,
          :from_slot => from_slot, :into_slot => into_slot)
        edges << obj
        yield(obj) if block_given?
        obj
      end
    end

    class Universe < Graph
      field :orient, Symbol, :doc => 'one of :TB, :BT, :LR, :RL', :default => :TB
      field :engine, Symbol, :default => :dot

      def to_s
        str = []
        str << brace("digraph #{name}")         ## digraph Wukong {
        str << line("  rankdir = #{orient}")    ##   rankdir = TB;
        items.each do |item|                    ##   subgraph "cluster_cherry_pie" {
          str << item.to_s                      ##     # ...
        end                                     ##   }
        str << close_brace                      ## }
        str.join("\n")
      end

      def depth() 0; end

      def save(path, type=nil)
        File.open "#{path}.dot", "w" do |f|
          f.puts self.to_s
        end
        system "#{engine} -T#{type} #{path}.dot > #{path}.#{type}" if type
      end
    end

    class Node < Item
      field :inslots,  Array, :default => []
      field :outslots, Array, :default => []
      field :shape, Symbol, :default => :Mrecord

      def to_s
        line(
          quote(name),                            ## "cherry_pie.crust.small_bowl"      [
          :shape => shape,                        ##   shape=Mrecord,
          :label => quote(structured_label),      ##   label="{{<in>sb}|small\nbowl}"
          )                                       ## ];
      end

      def inslots_str
        inslots.map{|slot| "<#{slot}>#{slot[0..0]}"}.join("|")
      end

      def outslots_str
        outslots.map{|slot| "<out_#{slot}>#{slot[0..0]}"}.join("|")
      end

      def label
        super.to_s.gsub(/_\d+$/, '').gsub(/[_\.]+/, "\\n")
      end

      def structured_label
        return label unless shape =~ /record/
        str = "{"
        str << "{" << inslots_str << "}|"  unless inslots.empty?
        str << label
        str << "|{" << outslots_str << "}" unless outslots.empty?
        str << "}"
        str
      end
    end

    class Edge < Item
      field :from, String
      field :into, String

      def to_s
        width = COL_1_WIDTH - indent.length
        "#{indent}%-#{width}s\t-> %-s;" % [ quote(from), quote(into) ] ## "cherry_pie.crust.small_bowl" -> "cherry_pie.crust.add_to_4";
      end
    end

  end
end
