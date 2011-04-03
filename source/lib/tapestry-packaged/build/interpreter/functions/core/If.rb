#!/usr/bin/ruby
#
# Functor for:
#    (if <any-expression > <any-expression> [<any-expression>])
#
# See USAGE below for details.
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

ARITY_if = 2..3
USAGE_if = <<END_USAGE.split("\n")
(if 
   <any-expression:condition> 
   <any-condition:if-true> 
   [<any-condition:if-false>]
)

Evaluates the condition as a boolean.  If true, returns the
result of the if-true clause.  If false, returns the result
of the if-false clause, or (nil).  Only the appropriate 
clauses are evaluated.

Example
   (set $names (read names.txt))
   (set $random (if $names (my-random-selector $names) default-name))

      if names.txt contains any names, $random will be set to one
      otherwise, $random will be set to "default-name"
END_USAGE



class If < Tapestry::Build::Interpreter::Function

   @@instance = If.new()

   def If.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      condition = processToBoolean( callDescriptor, 1, localScope, interpreter )

      results = ""
      if condition then
         results = processParameter( callDescriptor, 2, "any-expression", localScope, interpreter )

      else
         if arity == 3 then
            results = processParameter( callDescriptor, 3, "any-expression", localScope, interpreter )
         end
      end

      return results

   end

end  # If

Function.addBuiltin( "if", If.getInstance(), ARITY_if, USAGE_if )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





