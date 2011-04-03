#!/usr/bin/ruby
#
# Analyzers are used to determine general inter-file references.  They
# are run on each file just before it is required for building another
# target.  The references are added to the build graph, and may include
# files in other zones and even in the general filesystem.  See the help
# for def-analyzer (interpreter/functions/operations/Analyzers.rb) for full
# details.
#
# The Analyzer stores and handles a single analyzer descriptor.
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


class AnalyzerRule

   @name          = nil    # A unique name by which the analyzer is known

   @dynamicSource = false  # If true, @source is code to be interpreter, else it's a wildcard expression
   @source        = nil    # An interpreter token or a wildcard, depending on @dynamicSource
   @sourcePattern = nil    # Unless @dynamicSource, a Wildcard pattern against which to match filenames

   @target        = nil    # An interpreter token, the results of which are a list of references

   attr_reader :name


   def initialize( location, name, dynamicSource, source, target )

      @name          = name

      @dynamicSource = dynamicSource
      @source        = source

      unless @dynamicSource
         if source.contains?( File::Separator ) then
            @source = location.offsetHome( source )
         end
         @sourcePattern = Wildcard.compile( source )
      end

      @target        = target

      if System.verbosity > 1 then
         descriptor = @dynamicSource ? "<dynamic>" : @source
         System.puts( "defining analyzer: #{@name.rjust(9)} on #{descriptor}" )
      end
   end


   #
   # Returns true if this analyzer rule applies to the specified file.

   def applies?( node, location, interpreter, localScope = interpreter.globals )

      applies = false

      System.puts( "checking #{@name} analyzer on #{node.logical}" ) if System.verbosity > 2 
      System.puts( "in #{location.current}", 3 )                     if System.verbosity > 3 

      if @dynamicSource then
         setSourceVariables( node, localScope, location )
         applies = interpreter.booleanize( interpreter.interpret(@source, localScope) )

      else
         applies = true & @sourcePattern.match( node.logical )
      end

      System.puts( (applies ? "applies" : "doesn't apply"), 3 ) if System.verbosity > 2

      return applies

   end


   #
   # Runs the analyzer rule and returns a list of files on which the 
   # source is dependent.  The returned names are not necessarily 
   # absolute paths.

   def analyze( node, location, interpreter, localScope = interpreter.globals )

      references = []

      if System.verbosity > 1 then
         System.skip(2)
         System.puts( "analyzing #{node.logical}" ) 
         System.puts( "in #{location.current}", 3 ) if System.verbosity > 2
      end

      setSourceVariables( node, localScope, location )
      references = interpreter.vectorize( interpreter.interpret(@target, localScope) )

      if System.verbosity > 2 then
         references.each do |reference|
            System.puts( "analyzer produced: #{reference}", 3 )
         end
      end

      return references

   end


 private

   def setSourceVariables( node, localScope, location )

      source = location.relativeCurrent( node.actual )

      localScope.set( "source-logical", node.logical,  false )
      localScope.set( "source",         source,        false )
      localScope.set( "source-file",    node.filename, false )

      if System.verbosity > 3 then
         System.puts( "$source-logical = [#{localScope.get("source-logical")}]", 3 )
         System.puts( "$source         = [#{localScope.get("source")}]"        , 3 )
         System.puts( "$source-file    = [#{localScope.get("source-file")}]"   , 3 )
      end


   end

end  # AnalyzerRule

end  # Build
end  # Tapestry




#
# Test the class, if invoked directly.

if $0 == __FILE__


end


