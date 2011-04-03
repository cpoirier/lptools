#!/usr/bin/ruby
#
# Productions are used to determine what targets can be produced from a 
# source file, and which Action does the transformation.  See the
# help for def-production (interpreter/functions/operations/Productions.rb)
# for full details.
#
# The ProductionRule stores and handles a single production rule.
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


class ProductionRule

   @name          = nil    # The rule series this rule belongs to
   @priority      = 0      # The priority of this rule within that series

   @dynamicSource = false  # If true, @source must be interpreted for each file
   @source        = nil    # A wildcard expression or a function call
   @sourcePattern = nil    # Unless @dynamicSource, holds @source compiled as a Regexp

   @dynamicTarget = false  # If true, @target must be interpreted for each file
   @target        = nil    # If @dynamicTarget, any-expression.  Otherwise, a file extension.

   @action        = nil    # The name of the action to associate with build
                           # relationships produced by this production rule

   @supplement    = nil    # Code to be executed after a production


   attr_reader :name, :priority, :action


   #
   # Two source modes are supported:
   #    - dynamic source, in which source is an interpretable token,
   #      the output of which will indicate if the rule applies to a 
   #      particular filename
   #    - static source, in which source is a file name or a simple
   #      wildcard expression (a * followed by some text).  
   #
   # Two target modes are supported:
   #    - dynamic target, in which target is an interpretable token,
   #      the output of which are the target filenames produced from
   #      a particular source filename
   #    - static target, in which target is a file name or a simple
   #      wildcard expression (a * followed by some text).
   #
   # A static target may only be used with a static source.

   def initialize( location, name, priority, dynamicSource, source, dynamicTarget, target, action, supplement = nil )

      assert( ((not dynamicSource) or dynamicTarget), "attempt to use a static target with a dynamic source" )

      @name          = name
      @priority      = priority

      @dynamicSource = dynamicSource
      @source        = source

      unless @dynamicSource
         if source.contains?( File::Separator ) then
            @source = location.offsetHome( source )
         end
         @sourcePattern = Wildcard.compile( @source )
      end

      @dynamicTarget = dynamicTarget
      @target        = target

      @action        = action

      @supplement    = supplement


      if System.verbosity > 1 then
         sourceDescriptor = @dynamicSource ? "<dynamic>" : @source.rjust(9)
         targetDescriptor = @dynamicTarget ? "<dynamic>" : @target.ljust(9)

         System.puts( "defining production #{self.to_s.ljust(12)}: #{sourceDescriptor} ==#{@action.center(8)}==> #{targetDescriptor}" )
      end
   end


   #
   # Returns true if this production rule applies to the specified file name.
   # For a dynamic source, this means executing some code in the interpreter.
   # For a static source, this means comparing to a regular expression.

   def applies?( node, interpreter, localScope = interpreter.globals )

      applies = false

      if System.verbosity > 3 then
         System.skip(1)
         System.puts( "Checking production rule #{self.to_s} on [#{node.logical}]" )
      end


      if @dynamicSource then
         localScope.set( "source",          node.logical,  false )
         localScope.set( "source-file",     node.filename, false )

         if System.verbosity > 3 then
            System.puts( "$source      = [#{localScope.get("source")}]"     , 3 )
            System.puts( "$source-file = [#{localScope.get("source-file")}]", 3 )
         end

         applies = interpreter.booleanize( interpreter.interpret(@source, localScope) )

      else
         applies = true & @sourcePattern.match( node.logical )

      end


      if System.verbosity > 3 then
         System.puts( applies ? "...applies" : "...doesn't apply" )
      end


      return applies

   end


   #
   # Runs the production rule and returns a list of targets that can be
   # derived from the source.  For a dynamic target, this means executing
   # some code in the interpreter.  For a static target, this means doing
   # some pattern replacement.  The action property contains the name of
   # the action to use.  

   def produce( node, interpreter, localScope = interpreter.globals )

      produced = []

      if System.verbosity > 2 then
         System.skip(1)
         System.puts( "Running production rule #{self.to_s} on [#{node.logical}]" )
      end


      if @dynamicTarget then
         localScope.set( "source",          node.logical,  false )
         localScope.set( "source-file",     node.filename, false )

         if System.verbosity > 3 then
            System.puts( "$source      = [#{localScope.get("source")}]"     , 3 )
            System.puts( "$source-file = [#{localScope.get("source-file")}]", 3 )
         end

         produced = interpreter.vectorize( interpreter.interpret(@target, localScope) )

      else
         target = @sourcePattern.splice( @target, node.logical )
         produced = [target]

      end


      if System.verbosity > 3 then
         produced.each do |name|
            System.puts("...produced #{name}")
         end
      end


      return produced

   end


   #
   # Runs the supplement code.  To be called after a successful production.

   def runSupplement( sourceNode, targetNode, interpreter, localScope = interpreter.globals )

      unless @supplement.nil?
         if System.verbosity > 2 then
            System.skip(1)
            System.puts( "Running production rule #{self.to_s} supplement" )
         end
   
         localScope.set( "source",      sourceNode.logical,  false )
         localScope.set( "source-file", sourceNode.filename, false )
         localScope.set( "target",      targetNode.logical,  false )
         localScope.set( "target-file", targetNode.filename, false )
   
         if System.verbosity > 3 then
            System.puts( "$source      = [#{localScope.get("source")}]"     , 3 )
            System.puts( "$source-file = [#{localScope.get("source-file")}]", 3 )
            System.puts( "$target      = [#{localScope.get("target")}]"     , 3 )
            System.puts( "$target-file = [#{localScope.get("target-file")}]", 3 )
         end
   
         interpreter.interpret(@supplement, localScope) 
      end

   end



   def to_s()
      return @name + "[" + @priority.to_s + "]"
   end


end  # ProductionRule

end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


