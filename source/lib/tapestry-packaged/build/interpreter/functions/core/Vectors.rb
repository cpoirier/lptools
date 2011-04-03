#!/usr/bin/ruby
#
# Functor for:
#    (at      <vector-expression> <scalar-expression>)
#    (join    <vector-expression> <scalar-expression>)
#    (diff    <vector-expression> <vector-expression>)
#    (flatten <vector-expression>)
#    (merge   <any-expression> <any-expression>)
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

ARITY_at = 2..2
USAGE_at = <<END_USAGE.split("\n")
(at <vector-expression> <any-expression:position(s)>)

Returns the element(s) of the vector at the specified 
position(s).  Negative indices are counted from the
end.  

Example
   (set $list (q(x y z))

   (at $list 2)
      - returns z

   (at $list (q(1 -1))
      - returns (y z)
END_USAGE





ARITY_join = 2..2
USAGE_join = <<END_USAGE.split("\n")
(join <vector-expression:pieces> <scalar-expression:glue>)

Returns a scalar built by glueing the pieces together.
END_USAGE




ARITY_diff = 2..2
USAGE_diff = <<END_USAGE.split("\n")
(diff 
   <vector-expression:minuend> 
   <vector-expression:subtrahend>
)

Returns a vector built by removing any elements in minuend
that are in subtrahend.

Example
   (diff (' 1 2 3 4) (' 2 3))
      - return (1 4)
END_USAGE





ARITY_flatten = 1..1
USAGE_flatten = <<END_USAGE.split("\n")
(flatten <vector-expression>)

Returns a one-level vector containing all leaves in the 
expression.

Example
   (set $nested (q(a b (c d (e f) g) h))
   (set $flattened (flatten $nested))
      - $flattened holds (a b c d e f g h)
END_USAGE





ARITY_merge = 2..2
USAGE_merge = <<END_USAGE.split("\n")
(merge <any-expression:first> <any-expression:second>)

Returns a vector made from the elements of first and second.
Scalar expressions are vectorized before use.

Example
   (merge 10 11)
      - returns (10 11)

   (merge 10 (11 12))
      - returns (10 11 12)

   (merge (10 11) (12 13))
      - returns (10 11 12 13)

   (merge (10 11) 12)
      - returns (10 11 12)
END_USAGE




ARITY_reverse = 1..1
USAGE_reverse = <<END_USAGE.split("\n")
(reverse <vector-expression>)

Returns a reversed copies of the supplied vector.

Example
   (reverse (q(1 2 3))
      - returns (3 2 1)
END_USAGE




ARITY_member_ = 2..2
USAGE_member_ = <<END_USAGE.split("\n")
(member? <vector-expression> <any-expression:value>)

Returns true if value is a member of the supplied vector.
END_USAGE





class Vectors < Tapestry::Build::Interpreter::Function

   @@instance = Vectors.new()

   def Vectors.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""
      case function
       when "at"
         list      = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         positions = processParameter( callDescriptor, 2, "any-expression",    localScope, interpreter )

         if interpreter.isVector( positions ) then
            results = []
            positions.each do |position|
               results.append( list[interpreter.integerize(position)] )
            end
         else
            results = list[interpreter.integerize(positions)]
         end


       when "join"
         list = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         glue = processParameter( callDescriptor, 2, "scalar-expression", localScope, interpreter )
         results = list.join(glue)


       when "diff"
         minuend    = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         subtrahend = processParameter( callDescriptor, 2, "vector-expression", localScope, interpreter )
         results = minuend.to_a - subtrahend.to_a


       when "flatten"
         list = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         results = list.flatten()


       when "merge"
         first  = processToVector( callDescriptor, 1, localScope, interpreter )
         second = processToVector( callDescriptor, 2, localScope, interpreter )
         results = first + second


       when "reverse"
         list = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         results = list.reverse()


       when "member?"
         list  = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
         value = processParameter( callDescriptor, 2, "any-expression",    localScope, interpreter )
         results = list.member?(value)

      end

      return results

   end

end  # Vectors

Function.addBuiltin( "flatten", Vectors.getInstance(), ARITY_flatten, USAGE_flatten )
Function.addBuiltin( "merge"  , Vectors.getInstance(), ARITY_merge,   USAGE_merge   )
Function.addBuiltin( "diff"   , Vectors.getInstance(), ARITY_diff,    USAGE_diff    )
Function.addBuiltin( "join"   , Vectors.getInstance(), ARITY_join,    USAGE_join    )
Function.addBuiltin( "at"     , Vectors.getInstance(), ARITY_at,      USAGE_at      )
Function.addBuiltin( "reverse", Vectors.getInstance(), ARITY_reverse, USAGE_reverse )
Function.addBuiltin( "member?", Vectors.getInstance(), ARITY_member_, USAGE_member_ )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





