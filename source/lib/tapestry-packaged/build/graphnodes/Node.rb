#!/usr/bin/ruby
#
# The basic Node for the Graph.  Handles references and related operations 
# for a single file.
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

require 'tapestry-packaged/build/graphnodes/ProductionExtension.rb'

module Tapestry
module Build
module GraphNodes


#
# Each node lives at a certain location in the graph, referred to as its
# logical location.  For zones that have no alternate target directory, 
# the logical location and the actual location will be the same.

class Node

   @logical    = nil     # The preferred way to locate a node
   @actual     = nil     # The actual physical location of the node, considering zone targets
   @filename   = nil     # The base filename, for convenience

   @production = false   # False until makeProduction() is called
   @touched    = {}      # A hash of flags indicating if this node has been touched by a particular operation

   attr_reader :logical, :actual, :filename


   @references = nil     # Nodes which this node references, internally in the file (like headers from source)
   @attributes = nil     # A set of name/value pairs

   @analyzers  = nil     # A list of analyzers already run on this node
   @interested = nil     # A list of zones interested in significant events in this node's life

   @zone       = nil     # The zone that owns this node, if known


   def initialize( location, zone = nil )

      @logical    = location
      @actual     = location
      @filename   = File.basename(location)

      @extended   = false

      @touched         = {}
      @touched.default = false

      @references = {}

      @attributes = {}
      @attributes.default = ""
      
      @analyzers  = []
      @interested = []

      @zone = zone    
      lockdown() if System.locked?

   end



 #-----------------------------------------------------------------------------
 # INFORMATION ROUTINES

   #
   # Returns true iff the node's file exists.

   def exists?()
      return File.exist?(@actual)
   end


   #
   # Returns the last modified date of the node's file (as a Time object).
   # Returns missing if the file doesn't exist.

   def modified( missing = Time.epoch )

      modified = missing
      begin
         modified = File.ctime(@actual)
      rescue SystemCallError
      end
      return modified

   end


   #
   # Returns true if this node's file is newer than the specified date.
   # It checks it references, if requested, but not its components.

   def newer?( basetime, references = false, path = [] )

      newer = modified() > basetime

      if !newer and references then
         each_reference() do |node|
            next if path.member?(node)
            newer = node.newer?( basetime, true, [node].concat(path) )
            break if newer
         end
      end

      return newer

   end


   #
   # Returns the node's effective zone, given a valid default.
   # Works even before Graph.lockdown(), but not necessarily 
   # accurately.

   def zone( default )

      type_check( default, Tapestry::Build::Zone )

      zone = @zone
      if @zone.nil? and not System.locked? then
         zone = Zone.find( @logical )
      end

      return ( zone.nil? ? default : zone )

   end


   #
   # If true, the node has the ProductionExtension

   def extended?()
      return @extended
   end




 #-----------------------------------------------------------------------------
 # DEPENDENCY ROUTINES

   #
   # Returns true if the named analyzer has already been run on this node.
   # If you call it without a name, returns true if any analyzers have been
   # run.

   def analyzed?( analyzer = nil )

      analyzed = false
      if analyzer.nil? then
         analyzed = (@analyzers.length > 1)
      else
         analyzed = @analyzers.member?(analyzer)
      end
      return analyzed

   end


   #
   # Iterates through all the references for the node.  Passes the current 
   # reference node to the block.

   def each_reference()

      @references.keys.each do |node|
         yield( node )
      end

   end



 #-----------------------------------------------------------------------------
 # STATUS ROUTINES

   #
   # Returns true iff this node is a buildable target?  OVERRIDDEN.

   def target?()
      return false
   end


   #
   # Returns true iff this node has been touched since last untouched()

   def touched?( name )
      return @touched[name]
   end


   #
   # For unbuildable nodes, this is equivalent to touched?().  OVERRIDDEN.

   def built?()
      return touched?( "build" )
   end


   #
   # Marks the node touched.

   def touch( name )
      @touched[name] = true
   end


   #
   # Marks the node untouched.

   def untouch( name )
      @touched[name] = false
   end


   #
   # Requests that the specified zone be notified of when sources and
   # targets are added to the node.

   def notify( zone )
      unless @interested.member?(zone)
         @interested.append(zone)
      end
   end



 #-----------------------------------------------------------------------------
 # SYSTEM AND SPECIAL ROUTINES

   #
   # Sets @zone permanently, and alters @actual appropriately.

   def lockdown()

      assert( @actual == @logical, "at lockdown, actual was different from logical -- the ramifications of this have not been fully considered" )

      @zone = Zone.find( @logical )
      unless @zone.nil? 
         if self.target? then
            @actual = @zone.enforceActualTargetPolicy( @logical )
         end
      end

   end

   


 #-----------------------------------------------------------------------------
 # ATTRIBUTES

   def getAttribute( name )
      return @attributes[name]
   end

   def setAttribute( name, value )
      @attributes[name] = value
   end

   def attribute?( name )
      return @attributes.member?(name)
   end



 #-----------------------------------------------------------------------------
 # PRIVATE ROUTINES

 private


   #
   # Upgrades this node to a production node.  Returns true if the
   # node was upgraded, false otherwise.  OVERRIDDEN by the extension.

   def loadExtension()

      extended = false

      unless @extended
         extend( Tapestry::Build::GraphNodes::ProductionExtension )
         initializeExtension()

         @extended = true
         extended  = true
      end

      return true
   end


   # 
   # When called, extends the node and enters the OVERRIDDEN call.  
   # Returns true if the source was added.

   def addSource( node, action )

      added = false
      if loadExtension() then
         added = addSource( node, action )
      end
      return added

   end


   # 
   # When called, extends the node and enters the OVERRIDEN call.
   # Returns true if the target was added.

   def addTarget( node, action )

      added = false
      if loadExtension() then
         added = addTarget( node, action )
      end
      return added

   end


   #
   # When called, extends the node and enters the OVERRIDDEN call.
   # Returns true if the component was added.

   def addComponent( node )

      added = false
      if loadExtension() then
         added = addComponent( node )
      end
      return added

   end


   #
   # Adds a set of references as a result of an analyzer.  Used by Graph.
   # Returns true iff the named analyzer hasn't already been run.

   def addReferences( nodes, analyzer )

      added = false

      unless @analyzers.member?(analyzer)
         added = true
         @analyzers.push( analyzer )
         nodes.each do |node|
            addReference( node )
         end
      end

      return added

   end


   #
   # Adds a reference to the node.  Used by Graph.  Returns true iff the
   # named reference wasn't already in the list.  If analyzer is supplied,
   # it is also checked for existence before adding the reference.

   def addReference( node, analyzer = nil )

      added = false

      unless @analyzers.member?(analyzer)
         @analyzers.append(analyzer) unless analyzer.nil?
         unless @references.member?(node) or node.id == self.id
            added = true
            @references[node] = true
         end
      end

      return added
      
   end


end  # Node
   

end  # GraphNodes
end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


