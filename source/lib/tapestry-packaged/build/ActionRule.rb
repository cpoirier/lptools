#!/usr/bin/ruby
#
# Actions are used to build a target from one or more sources.  See the 
# help for def-action (interpreter/functions/operations/Actions.rb) for 
# full details.
#
# The ActionRule stores and handles a single action descriptor.
#
# ------------------------------------------------------------------------
#
# Copyright Chris Poirier 2003.  Contact cpoirier@tapestry-os.org.
# Licensed under the Open Software License, version 1.1
#
# This program is licensed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  Use is ENTIRELY AT YOUR OWN RISK.
#

module Tapestry
module Build


class ActionRule

   @name  = nil   # A unique name by which the action is known
   @code  = nil   # An interpreter token to execute
   @style = nil   # Currently "each" or "all", depending on how many sources the action supports

   attr_reader :name, :style


   def initialize( name, code, style )

      @name  = name
      @code  = code
      @style = style

      if System.verbosity > 1 then
         System.puts( "defining action: #@name" )
      end
   end


   #
   # Returns true if this action can handle the specified number of sources.

   def handles?( sources )

      type_check( sources, Numeric )

      handles = true
      if @style == "each" and sources != 1 then
         handles = false
      end
      return handles

   end



   #
   # Executes the action.  You should chdir() appropriately before
   # calling.  Returns true if the action succeeded.

   def run( sourceNodes, targetNode, location, interpreter, localScope = interpreter.globals )

      success = false

      if handles?( sourceNodes.length ) then

         System.skip(2)
         System.puts( "#@name => #{targetNode.logical}" ) if System.verbosity > 0
         System.puts( " in #{location.current}", @name.length ) if System.verbosity > 2
         if System.verbosity > 1 then
            sourceNodes.each do |sourceNode|
               System.puts( " <= #{sourceNode.logical}", @name.length )
            end
         end

         setSourceVariables( localScope, sourceNodes, location )

         localScope.set( "target-logical", targetNode.logical, false )
         localScope.set( "target"        , location.relativeCurrent( targetNode.actual ), false )
         localScope.set( "target-file"   , targetNode.filename, false )

         if System.verbosity > 3 then
            System.puts( "$target-logical = [#{localScope.get("target-logical")}]", @name.length+1 )
            System.puts( "$target         = [#{localScope.get("target")}]"        , @name.length+1 )
            System.puts( "$target-file    = [#{localScope.get("target-file")}]"   , @name.length+1 )
         end


         success = interpreter.booleanize( interpreter.interpret(@code, localScope) )

      end

      return success

   end


 private

   def setSourceVariables( localScope, sourceNodes, location )

      if @style == "each" then
         node = sourceNodes[0]
         source = location.relativeCurrent( node.actual )
         localScope.set( "source-logical", node.logical, false )
         localScope.set( "source"        , source, false )
         localScope.set( "source-file"   , node.filename, false )

         if System.verbosity > 3 then
            System.puts( "$source-logical = [#{localScope.get("source-logical")}]", @name.length+1)
            System.puts( "$source         = [#{localScope.get("source")}]"        , @name.length+1 )
            System.puts( "$source-file    = [#{localScope.get("source-file")}]"   , @name.length+1 )
         end

      else
         logicals = []
         sources  = []
         files    = []

         sourceNodes.each do |node|
            source = location.relativeCurrent(node.actual)
            logicals.append( node.logical )
            sources.append( source )
            files.append( node.filename )
         end

         localScope.set( "sources-logical", logicals, false )
         localScope.set( "sources"        , sources,  false )
         localScope.set( "sources-file"   , files,    false )

         if System.verbosity > 3 then
            System.puts( "$sources-logical = [#{localScope.get("sources-logical").join(', ')}]", @name.length+1 )
            System.puts( "$sources         = [#{localScope.get("sources").join(', ')}]"        , @name.length+1 )
            System.puts( "$source-files    = [#{localScope.get("source-files").join(', ')}]"   , @name.length+1 )
         end
      end


   end

end  # ActionRule

end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


