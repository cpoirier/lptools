#!/usr/bin/ruby
#
# Functor for defining build actions.
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

ARITY_def_action = 3..3
USAGE_def_action = <<END_USAGE.split("\n")
                          ACTIONS

   The build system applies actions to convert source files
into target outputs.  Once the system has identified a 
target to be built, it invokes the action associated with
the target (by the production that found it).

   Actions typically execute external commands to actually
build the target from its source(s).  Each action produces
one target, which will be built from one or more source 
files, as dictated by the data provided by the productions.

   As noted in (def-production), the build system handles 
relocating output to a target directory, if requested.  All
actions are executed within the zone's target directory.  
Target paths will be appropriately adjusted to ensure that
all produced targets fall within the zone's boundaries.

   Once a target has been built, it will not be built again
during the run of the build system.  It can then be used as
a source in another action.


------------------------------------------------------------
(def-action 
   each
   <literal-expression:name>
   <function-call:code>   
)

Creates an action with the given name and code.  "each" 
indicates that your action expects only one source file, and
an error will be incurred if this is not the case.

Available variables
  $source-logical = logical path to source
  $source         = path to source, relative if possible
  $source-file    = bare filename of source

  $target-logical = logical path to target
  $target         = path to target, relative if possible
  $target-file    = bare filename of target

Examples
   create documentation from an lp source file:
      (def-action each lpdoc 
                        (q(lpdoc --output=$target $source)))


------------------------------------------------------------
(def-action 
   all
   <literal-expression:name>
   <function-call:code>   
)

Creates an action with the given name and code.  "all" 
indicates that your action expects a vector of source files.

Available variables
  $sources-logical = logical paths to sources
  $sources         = paths to sources, relative if possible
  $sources-file    = bare filenames of sources

  $target-logical  = logical path to target
  $target          = path to target, relative if possible
  $target-file     = bare filename of target

Examples
   compile a c program from sources:
      (def-action all cc 
               (q($CC $INCLUDES $DEFINES -o $target 
                                (join $sources (space)) )) )
END_USAGE




      
class Actions < Tapestry::Build::Interpreter::Function 

   @@instance = Actions.new()
   def Actions.getInstance()
      return @@instance
   end

   @@styles = [ "each", "all" ]


   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""

      style = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      unless @@styles.member?(style) 
         error = "actions must be \"each\" or \"all\""
         raise createParameterError( function, 1, error, getUsage(function), callDescriptor[1] )
      end

      name = processParameter( callDescriptor, 2, "literal-expression", localScope, interpreter )
      code = processParameter( callDescriptor, 3, "function-call"     , localScope, interpreter )


      #
      # Add the new production rule to the zone.

      zone = interpreter.zone
      zone.registerAction( name, code, style )

      return results

   end


end  # Actions

Function.addBuiltin( "def-action", Actions.getInstance(), ARITY_def_action, USAGE_def_action )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





