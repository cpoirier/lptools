#!/usr/bin/ruby
#
# The ProductionEngine does the actual work of tracking and building 
# targets on behalf of the Zone.
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

require 'tapestry-packaged/build/ProductionRule.rb'

module Tapestry
module Build


class ProductionEngine

   @rules       = nil    # A hash of priority sorted lists of ProductionRules
   @queue       = nil    # A list of locations awaiting processing -- process()
                         # automatically filters out duplicates and merges multiple sources

   @order       = nil    # An ordering of rule series as specified by the user
   @fullOrder   = nil    # A cache of @order + (@rules.keys - @order)

   @zone        = nil    # The Zone owner of this engine
   @location    = nil    # The LocationManager, cached from the Zone
   @interpreter = nil    # The Interpreter, cached from the Zone

   @processing  = false  # Held true while process() is running -- prevents recursion


   def initialize( zone )
      @rules = {}
      @queue = []
      @order = []
      @fullOrder = []

      @zone        = zone
      @location    = zone.location
      @interpreter = zone.interpreter

      @processing  = false
   end


   #
   # Adds a new ProductionRule to the engine.  We now allow the most
   # recent rules of a particular name and priority to override older ones.

   def addRule( name, priority, dynamicSource, source, dynamicTarget, target, action, supplement )

      rule = ProductionRule.new( @location, name, priority, dynamicSource, source, dynamicTarget, target, action, supplement )

      if @rules.member?(name) then
         @rules[name].priority_insert!( rule, false )
      else
         @rules[name] = [ rule ]
      end

      @fullOrder = @order + (@rules.keys - @order)

   end



   #
   # Adds a rule ordering instruction.

   def setOrdering( ordering )

      clean = ordering.uniq
      clean.each do |name|
         unless @rules.member?(name)
            raise_orderingError(name)
         end
      end
      @order = clean
      @fullOrder = @order + (@rules.keys - @order)

   end



   #
   # Runs the productions on a series of source files.  If code is supplied,
   # it is executed before the engine is run on the added files.

   def process( localScope = @interpreter.globals, sources = nil, code = nil )

      unless sources.nil?
         sources.each do |source|
            absolute = addWork(@location.offsetHome(source))
            @zone.notifyAddRawSource(absolute)

            unless code.nil?
               sourceNode = Graph.produce(absolute)
               localScope.set( "source",      sourceNode.logical,  false )
               localScope.set( "source-file", sourceNode.filename, false )
               @interpreter.interpret(code, localScope) 
            end
         end
      end

      if !@processing then 
         begin
            @processing = true
            until @queue.empty?
               step( localScope )
            end
         ensure
            @processing = false
         end
      end

   end



 #-----------------------------------------------------------------------------
 # PRIVATE METHODS

 private

   #
   # Adds an entry to the @queue.  Returns the absolute path of the added work.

   def addWork( absolute )
      @queue.append( absolute )
      return absolute
   end


   #
   # Processes the top item on the @queue, possibly altering the @graph
   # and/or adding new work to the @queue.

   def step( localScope )

      assert( !@queue.empty?, "ProductionEngine queue must not be empty on entry to step()" )

      start      = Time.now
      location   = @queue.remove_head()
      sourceNode = Graph.produce( location )

      #
      # During this pass, the node's touched flag is used to indicate if the node 
      # has been processed by a ProductionEngine.  If it hasn't, we do it now.

      unless sourceNode.touched?("production")
         sourceNode.touch("production")


         #
         # We search each series for a first applicable production rule, which we
         # run and add its results to the graph.
         #
         # Two rule-based problems must be handled:
         #  - all sources for a given target must build it with the same action
         #    (or else we would have to run to actions, and one would overwrite
         #    the other)
         #  - only one series may produce a particular target from a particular 
         #    source -- this is a problem because series are run in an arbitrary
         #    order, and so there is no predictability about which series will
         #    win

         @fullOrder.each do |name|
            series = @rules[name]
            @location.chdirHome()

            #
            # For each series, only the first applicable rule is run.  Once we
            # have results, we ask our zone to apply any target path policies,
            # check for our two problems (mentioned above), and either raise
            # an exception or link the source and targets.

            series.each do |rule|
             begin
               if rule.applies?( sourceNode, @interpreter, localScope ) then

                  targets = rule.produce( sourceNode, @interpreter, localScope )
                  targets.each do |target|
                     target = @zone.enforceLogicalTargetPolicy(target)
                     targetNode = Graph.produce( target )

                     existingLink = ( sourceNode.extended? ? sourceNode.actionFor(targetNode) : nil )
                     unless existingLink.nil?
                        error = "a second rule series produced an existing source-target production"
                        raise_productionRuleError( error, rule, sourceNode, targetNode, existingLink )
                     end

                     sourcesAction = ( targetNode.target? ? targetNode.byAction : nil )
                     unless sourcesAction.nil? or sourcesAction == rule.action
                        error = "each target can be built from sources using only one action"
                        raise_productionRuleError( error, rule, sourceNode, targetNode, sourcesAction )
                     end

                     targetNode.notify( @zone )
                     addWork( targetNode.logical )

                     linked = Graph.link( nil, nil, rule.action, sourceNode, targetNode )
                     assert( linked, "what does this mean?" )

                     rule.runSupplement( sourceNode, targetNode, @interpreter, localScope )

                  end

                  #
                  # We are done with this series

                  break

               end

             rescue Tapestry::Error => error
               error.set( "production-rule", rule.to_s() ) unless error.member?("production-rule")
               error.set( "token",           nil         ) unless error.member?("token")
               raise error
             end
            end

            true

         end
      end


      duration = Time.now - start
      if duration > 0.1 and System.verbosity > 0 then
         location = System.relativeStart(sourceNode.logical)
         duration = duration.to_s()[0, 5]
         System.puts( "long production: #{duration}s for #{location}" )
      end

   end



   def raise_productionRuleError( details, rule, sourceNode, targetNode, action )

      error = Tapestry::Error(  "production rule error",       \
                 { "details",         details                  \
                 , "production-rule", rule.to_s                \
                 , "source",          sourceNode.logical       \
                 , "target",          targetNode.logical       \
                 , "action",          action                   \
                 , "token",           nil                      },  true )

      error.keyorder = [ "production-rule", "source", "target", "action" ]

      raise error

   end


   def raise_orderingError( name )

      error = Tapestry::Error( "production rule error",         \
                 { "details", "production series doesn't exist" \
                 , "series", name                               }, true )
      raise error

   end


end  # ProductionEngine
   

end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


