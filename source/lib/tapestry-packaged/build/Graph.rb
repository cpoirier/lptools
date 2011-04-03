#!/usr/bin/ruby
#
# The Graph holds and manages dependencies and productions for the entire
# system.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002, 2003.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

require 'tapestry-packaged/build/graphnodes/Node.rb'


module Tapestry
module Build


class Graph

   @@nodes = []   # All the graph nodes, without duplication
   @@graph = {}   # The graph itself, an index of @nodes


 #-----------------------------------------------------------------------------
 # BASIC OPERATIONS


   #
   # Returns the node corresponding to logical or actual location, or nil
   # Location must be an absolute path of a Node.  If you insist, you'll 
   # get a node or an exception. 

   def Graph.find( location, insist = false )

      node = nil

      if exists?(location) then
         node = @@graph[location]
      end

      if node.nil? and insist then
         raise Tapestry::Error( "location error",                           \
            { "details"  => "unable to find named target in build graph"   \
            , "location" => location                                     } )
      end

      return node

   end


   #
   # Returns true if the specified node exists. 

   def Graph.exists?( location )
      return @@graph.member?( location )
   end


   #
   # Returns the node corresponding to location, creating it if it
   # doesn't exist. 

   def Graph.produce( location )

      node = find( location )

      if node.nil? then
         node = create( location )
      end

      return node

   end


   #
   # Adds a node to the graph and returns it.  produce() is safer...

   def Graph.create( location )

      node = GraphNodes::Node.new( location )
      @@nodes.append( node )
      index( node )

      return node

   end


   #
   # Iterates through all the nodes in the graph.  There is no particular
   # order to the nodes.

   def Graph.each()
      @@nodes.each do |node|
         yield( node )
      end
   end


   #
   # Iterates through all the index locations in the graph.  Passes location,
   # node.

   def Graph.each_location()
      @@graph.each_pair do |location, node|
         yield( location, node )
      end
   end



   #
   # Marks the from node as referencing the to node.  Returns true
   # iff the nodes weren't already linked by a reference.  You can pass
   # nil for from and to if you supply nodes.

   def Graph.references( from, to, analyzer = nil, fromNode = produce(from), toNode = produce(to) )
      return fromNode.instance_eval { addReference( toNode, analyzer ) }
   end


   #
   # Marks the from node as referencing those in tos.  Returns true
   # iff the named analyzer hadn't already been run.  You can supply nil
   # for from and tos if you supply nodes.

   def Graph.referencesMany( from, tos, analyzer = nil, fromNode = produce(from), toNodes = tos.map() { |to| produce(to) } )
      return fromNode.instance_eval { addReferences( toNodes, analyzer ) }
   end


   #
   # Marks the component node as a component of the of node.  Returns true iff 
   # the relationship didn't already exist.  You can pass nil for item and of 
   # if you supply nodes.

   def Graph.component( component, of, componentNode = produce(item), ofNode = produce(of) )
      return ofNode.instance_eval { addComponent( componentNode ) }
   end



   #
   # Links two nodes in a source-target relationship.  source and target must
   # be locations.  Returns true iff the nodes weren't already linked.  You can
   # supply nil for source and target if you supply nodes.

   def Graph.link( source, target, action, sourceNode = produce(source), targetNode = produce(target) )

      linkdown = sourceNode.instance_eval { addTarget( targetNode, action ) }
      linkup   = targetNode.instance_eval { addSource( sourceNode, action ) }

      assert( linkdown == linkup, "source-target link out of sync!" )
      return linkdown

   end


   #
   # Clears touched? on all nodes in the graph.

   def Graph.untouch(name)
      each() do |node|
         node.untouch(name)
      end
   end



 #-----------------------------------------------------------------------------
 # SYSTEM AND INTERNAL ROUTINES

   #
   # Tells the graph that all Zones are now known and it is safe to
   # permanently locate all Nodes.  

   def Graph.lockdown()
      @@nodes.each do |node|
         node.lockdown()
      end
   end


   #
   # Adds a node to the index at the specified location.  If a different node
   # already exists at that location, it is a problem.

   def Graph.index( node, location = node.logical )

      current = @@graph[location]
      unless current.nil?
         raise Tapestry::Error( "location error",                                            \
            { "details"  => "unresolvable name collision when adding node to graph index"   \
            , "location" => location                                                      } )
      end

      @@graph[location] = node

   end


   #
   # Clears an index entry.

   def Graph.unindex( location )
      @@graph.delete( location )
   end


end  # Graph


end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__ then


end


