#!/usr/bin/ruby
#
# Extends the basic Node (its an instance extension, not a class 
# extension), by adding production abilities and data structures.  
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2002.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

module Tapestry
module Build
module GraphNodes


module ProductionExtension

   @components = []     # The set of nodes which are involved in building this node -- a superset of @sources
   @sources    = []     # The set of nodes from which this node is built
   @targets    = {}     # The set of node which are built from this node, action as value
   @action     = nil    # The action used to build us from our sources -- there may be only one
   @built      = false  # Set true once the node has been successfully built.


   def initializeExtension( )

      @components = []
      @sources    = []
      @targets    = {}
      @built      = false
      @action     = nil

   end



 #-----------------------------------------------------------------------------
 # INFORMATION AND STATUS ROUTINES


   #
   # Returns true iff this node is a target.

   def target?()
      return !@sources.empty?
   end


   #
   # Returns the action by which this node is built, if it is a target,
   # of nil.

   def byAction()
      return @action
   end


   #
   # Returns the action used to produce the specified target from this
   # node, or nil.

   def actionFor( targetNode )
      return @targets[targetNode]
   end


   #
   # Returns the list of targets produced with the specified action.

   def targetsBy( action )
      return @targets.keys.select do |element|
         (@targets[element] == action) ? true : false
      end
   end


   #
   # Returns true iff this node has been successfully built.

   def built?()
      return built
   end


   #
   # Sets/clears the built flag for the node.

   def setBuilt( flag = true )
      @built = true & flag
   end



 #-----------------------------------------------------------------------------
 # ITERATORS

   def each_component()
      @components.each do |node|
         yield( node )
      end
   end


   def each_source()
      @sources.each do |node|
         yield( node )
      end
   end


   def sources()
      return @sources
   end

   def components()
      return @components
   end

   def targets()
      return @targets.keys
   end




 #-----------------------------------------------------------------------------
 # PRIVATE

 private


   #
   # Adds a source to the node.  Used through Graph.  Returns true
   # iff the source was added.  If the source was added, the 
   # interested Zones are notified.  action is the name of the action
   # by which we are created from the source.  All our sources must
   # use the same action in our production...

   def addSource( node, action )

      added = false
      @action = action if @action.nil?
      if @action == action then

         unless @sources.member?( node )
            @sources.append( node )
            added = true

            @interested.each do |zone|
               zone.notifyAddSource( self, @sources.length, @targets.length, action )
            end
         end

         addComponent( node )

      end

      return added

   end


   # 
   # Adds a target to the node.  Used via Graph.  Returns true iff the 
   # target was added.  If the target was added, the interested Zones 
   # are notified.

   def addTarget( node, action )

      added = false

      unless @targets.member?( node )
         @targets[node] = action
         added = true

         @interested.each do |zone|
            zone.notifyAddTarget( self, @sources.length, @targets.length, action )
         end
      end
      return added

   end



   #
   # Adds a component to the node.  Used by Graph.  Returns true iff the
   # named component wasn't already in the list.  

   def addComponent( node )

      added = false
      unless @components.member?(node)
         @components.append(node)
         added = true
      end
      return added

   end



end  # ProductionAuxiliary
   

end  # GraphNodes
end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


