#!/usr/bin/ruby
#
# An 0-parameter function that can be addressed as a target.  Essentially,
# an action target (think make clean).
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

ARITY_def_macro = 2..3
USAGE_def_macro = <<END_USAGE.split("\n")
(def-macro 
   <literal-expression:name> 
   <function-call:code>
   [<any-expression:dependencies>]
)

Defines a macro which can be addressed as a target.  The action
for a macro is to execute its code.  If you supply dependencies,
the macro will not run until they are successfully built.

Example
   (def-macro clean (do (recursive-rm *.o)))

   > build clean
      - removes all *.o files in the zone


   (def-macro test (system program) (l program))
      - creates a macro that will test program, after it 
        is built

END_USAGE



      
class Macros < Tapestry::Build::Interpreter::Function 

   @@instance = Macros.new()
   def Macros.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""
      zone    = interpreter.zone

      macro   = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      code    = processParameter( callDescriptor, 2, "function-call"     , localScope, interpreter )

      dependencies = nil
      if arity == 3 then
         dependencies = processToVector( callDescriptor, 3, localScope, interpreter )
      end

      zone.registerMacro( macro, code, dependencies )

      return results
   end

end  # Macros

Function.addBuiltin( "def-macro", Macros.getInstance(), ARITY_def_macro, USAGE_def_macro )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





