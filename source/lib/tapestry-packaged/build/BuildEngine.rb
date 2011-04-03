#!/usr/bin/ruby
#
# The BuildEngine does the actual work of building targets on behalf of
# the Zone.
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

require 'tapestry-packaged/build/AnalyzerRule.rb'
require 'tapestry-packaged/build/ActionRule.rb'

module Tapestry
module Build


class BuildEngine

   @analyzers   = nil    # A hash of AnalyerRules, keyed on name.
   @actions     = nil    # A hash of ActionRules, keyed on name.

   @zone        = nil    # The Zone owner of this engine
   @location    = nil    # The LocationManager, cached from the Zone
   @interpreter = nil    # The Interpreter, cached from the Zone

   def initialize( zone )
      @analyzers = {}
      @actions   = {}

      @zone        = zone
      @location    = zone.location
      @interpreter = zone.interpreter
   end


   #
   # Adds a new AnalyzerRule to the engine.  We are now using the last
   # defined analyzer of a particular name.

   def addAnalyzer( name, dynamicSource, source, target )

      analyzer = AnalyzerRule.new( @location, name, dynamicSource, source, target )
      @analyzers[name] = analyzer
      return true

   end


   #
   # Adds a new ActionRule to the engine.  We are now using the last defined
   # version of an action.

   def addAction( name, code, style )

      action = ActionRule.new( name, code, style )
      @actions[name] = action
      added = true

   end



 #-----------------------------------------------------------------------------
 # LOOKUP FUNCTIONALITY


 #-----------------------------------------------------------------------------
 # PROCESSING 

   #
   # Attempts to build the supplied target node.  If the node is already built,
   # it won't be again.  Returns the number of nodes actually built in response.
   # Tapestry Errors are caught and added to the supplied ErrorSet.

   def build( node, errorSet = Tapestry::ErrorSet(1), localScope = @interpreter.globals )

      #
      # We start by analyzing our own references.  This information is
      # needed to build this node, except in the case that we *know* we are
      # an end target *only*.  Unfortunately, the cost of figuring that out
      # is more than it is worth...  We run analyzers independently of
      # build because (build-target) may have caused this node to be built
      # before all analyzers were defined.  We untouch("analyzer") during
      # node.lockdown(), allowing any additional analyzers to be run.

      analyze( node, localScope ) unless node.touched?("analyzer")


      #
      # If this node has already been built, we are done.

      return 0 if node.touched?("build")

      System.puts( "building #{node.logical}" ) if System.verbosity > 2

      successful = true


      #
      # Currently, we assume that once a node is touched, it, and everything
      # "behind" it stays touched and never needs to be again.  If it becomes
      # desirable to allow the built flag to be cleared, we will need to
      # recurse in spite of node.touched?, which we do not now.  Anyway, we
      # set the touched flag immediately to allow resolvable dependency cycles.  

      count = 0
      node.touch("build")
      node.lockdown() unless System.locked?


      #
      # So, we build our references.  We buffer bufferable errors, in an 
      # attempt to build everything we can.  However, we're done here if any
      # of them fail.

      node.each_reference do |referenceNode|
         buildSuccess, buildCount = callBuild( referenceNode, errorSet, localScope )
         successful = false unless buildSuccess
         count += buildCount
      end
      raise errorSet if !successful or errorSet.cause?





      #
      # And only if our node is a buildable target do we need to do 
      # anything more.

      if node.target? then

         #
         # First, we build our components.  We buffer bufferable errors, in
         # an attempt to build everything we can.   However, we're done here
         # if any of them fail.

         node.each_component do |componentNode|
            buildSuccess, buildCount = callBuild( componentNode, errorSet, localScope )
            successful = false unless buildSuccess
            count += buildCount
         end
         raise errorSet if !successful or errorSet.cause?
   
   
         #
         # Decision time: are we up to date with respect to our components and
         # their references?  We assume yes, and stop looking when we learn
         # otherwise.
   
         upToDate = true
         modified = node.modified
         
         node.each_component do |componentNode|
            if componentNode.newer?( modified, true ) then
               upToDate = false
               break
            end
         end
   
   
         #
         # All that's left to do is build our output.
   
         if not upToDate then
   
            #
            # First, we get the action and verify that it is adequate.
            #
            # We enforce that all our sources produce us with the same action in
            # the ProductionEngine.  If it ever becomes necessary to allow other
            # entry points to this information, we will need to do the sanity 
            # check here.  

            unless @actions.member?(node.byAction)
               raise_buildError( "specified build action not found", node.logical, node.byAction )
            end
   
            action = @actions[node.byAction]
   
            unless action.handles?( node.sources.length )
               raise_buildError( "action does not support source count", node.logical, action.name, action.style )
            end
   
   
            #
            # Everything is okay, so build the target.

            begin
               @location.chdirTargets()
               success = action.run( node.sources, node, @location, @interpreter, localScope )
               if not success then
                  raise_buildError( "action failed", node.logical, action.name, nil, false )
               end

            rescue Tapestry::ErrorSet => error
               errorSet.merge( error )   
               raise errorSet

            rescue Tapestry::Error => error
               errorSet.add( error )
               raise errorSet

            end


            #
            # Update count and we are done.

            node.setBuilt
            count += 1

         end

      end

      return count

   end


   #
   # Runs the appropriate analyzers on a node.  Returns true if any analyzers
   # were actually run.  Before running the analyzer, we chdir() to the zone
   # home for raw sources and unbuildable nodes, or the zone target for 
   # targets.  

   def analyze( node, localScope = @interpreter.globals )

      analyzed = false

      if node.target? then
         @location.chdirTargets()
      else
         @location.chdirHome()
      end

      @analyzers.each_pair do |name, analyzer|
         if not node.analyzed?(analyzer) and analyzer.applies?( node, @location, @interpreter, localScope ) then
            analyzed = true

            references = analyzer.analyze( node, @location, @interpreter, localScope )
            references.map! {|path| @location.offsetCurrent(path)}

            Graph.referencesMany( nil, references, name, node )
         end
      end

      return analyzed

   end



 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private


   #
   # Finds the engine that applies to the specified node, defaulting
   # to ourself if the node isn't in a zone.

   def getBuildEngine( node )
      engine = node.zone(@zone).instance_eval { @builder }
      return engine
   end


   #
   # Calls build() on a node and handle bufferable errors.  Returns 
   # [success, count].  If success is false, bufferable errors were added 
   # to errorSet.

   def callBuild( node, errorSet, localScope )

      success = false
      count   = 0

      begin
         engine  = getBuildEngine( node )
         count   = engine.build( node, errorSet, localScope )
         success = true

      rescue Tapestry::ErrorSet => error
         errorSet.merge( error )  # Raises if errorSet.cause?

      rescue Tapestry::Error => error
         errorSet.add( error )    # Raises if errorSet.cause?

      end

      return success, count

   end



   #
   # Used to raise errors in the build process.

   def raise_buildError( details, target, action, data = nil, fatal = true )
      raise Tapestry::Error( "build error", \
         { "details" => details             \
         , "target"  => target              \
         , "action"  => action              \
         , "data"    => data                \
         , "zone"    => @zone.home          }, fatal )
   end


end  # BuildEngine
   

end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


