#!/usr/bin/ruby
#
# Functor for:
#    (expand <any-expression>)
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

ARITY_expand = 1..1
USAGE_expand = <<END_USAGE.split("\n")
(expand <scalar-expression>)

Expands all variable references in the scalar expression.
Returns a scalar if possible, a vector if not.

Example
   (set $x 17)
   (set $y (q(a b c))

   (expand --value=${x})
      - returns --value=17

   (expand --root=${x}-$y)
      - returns (--root=17-a --root=17-b --root=17-c)


------------------------------------------------------------
(expand <vector-expression>)

Expands all variable references in the top-level of the
vector expression results.  Always returns a vector.
END_USAGE




class VariableExpansion < Tapestry::Build::Interpreter::Function

   @@instance = VariableExpansion.new()

   def VariableExpansion.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = []
      intermediate = processParameter( callDescriptor, 1, "any-expression", localScope, interpreter )

      if interpreter.isVector( intermediate ) then
         intermediate.each do |element|
            if interpreter.isVector( element ) then
               results.append( element )
            else
               results.append( interpreter.expand( element, localScope ))
            end
         end

      else
         results = interpreter.expand( intermediate, localScope )
      end

      return results

   end

end  # VariableExpansion

Function.addBuiltin( "expand", VariableExpansion.getInstance(), ARITY_expand, USAGE_expand )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





