#!/usr/bin/ruby
#
# Functor for:
#    (q <any-expression>)
#    (' <any-expression>)
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

ARITY_q = 1..MAXIMUM_ARITY
USAGE_q = <<END_USAGE.split("\n")
(q <any-expression>)
(' <any-expression>)

Returns the expression without any interpretation.

Example
   (q(x y (a b c) z))
      - returns a vector: (x y (a b c) z)

   (q(echo $x))
      - returns a vector: (echo $x)

   (q $x)
      - returns a token: $x


------------------------------------------------------------
(q <any-expression> <any-expression> [<any-expression>...])
(' <any-expression> <any-expression> [<any-expression>...])

Returns the expressions without any interpretion, enclosed
in a list.

Example
   (q x y (a b c) z)
      - returns a vector: (x y (a b c) z)

   (q $x $y)
      - returns a vector: ($x $y)

END_USAGE



class Q < Tapestry::Build::Interpreter::Function 

   @@instance = Q.new()

   def Q.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      if arity == 1 then
         return callDescriptor[1]

      else
         return callDescriptor.rest(1)

      end

   end

end  # Q

Function.addBuiltin( "q", Q.getInstance(), ARITY_q, USAGE_q )
Function.addBuiltin( "'", Q.getInstance(), ARITY_q, USAGE_q )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





