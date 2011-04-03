#!/usr/bin/ruby
#
# Functor for defining source files.
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
module Interpreter
module Functions

ARITY_def_sources = 0..MAXIMUM_ARITY
USAGE_def_sources = <<END_USAGE.split("\n")
(def-sources [<any-expression>...])

Informs the zone of its primary source files.  Productions
will be run on these primary sources to produce a map of
all targets that can be produced.  

You can supply vector or scalar expressions, and all will be
added.

It is illegal to use (def-sources) within production rules.
END_USAGE



ARITY_def_source = 1..2
USAGE_def_source = <<END_USAGE.split("\n")
(def-source <literal-expression:file> [function-call:code])

Informs the zone of a primary source file.  If supplied,
code is executed before the production engine is invoked.
Productions will then be run on source to produce a map of
all targets that can be produced.  

It is illegal to use (def-source) within production rules.

Available variables during code
  $source      = absolute path to source
  $source-file = bare filename of source

END_USAGE



      
class Sources < Tapestry::Build::Interpreter::Function 

   @@instance = Sources.new()
   def Sources.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      zone = interpreter.zone
      sources = []
      code = nil

      case function
       when "def-sources"
         (1..arity).each do |index|
            sources.concat( processToVector( callDescriptor, index, localScope, interpreter ) )
         end

       else
         sources.append( processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter ) )
         if arity > 1 then
            code = processParameter( callDescriptor, 2, "function-call", localScope, interpreter )
         end
      end

      zone.registerSources( sources, localScope, code )
      return ""

   end


#
# I don't this is needed anymore.
#
#   def createRecursionError( callDescriptor, interpreter )
#      return interpreter.createFunctionError( \
#         "def-sources cannot be called recursively", callDescriptor, "recursion error" )
#   end


end  # Sources

Function.addBuiltin( "def-sources", Sources.getInstance(), ARITY_def_sources, USAGE_def_sources )
Function.addBuiltin( "def-source",  Sources.getInstance(), ARITY_def_source,  USAGE_def_source  )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





