#!/usr/bin/ruby
#
# Functor for:
#    (scalar  <any-expression>)
#    (vector  <any-expression>)
#    (boolean <any-expression>)
#    (integer <any-expression>)
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

ARITY_scalar = 1..1
USAGE_scalar = <<END_USAGE.split("\n")
(scalar <any-expression>)

Returns a scalar representation of any value.  Scalars are
passed through unchanged.  Vectors are reduced to their
length.
END_USAGE



ARITY_vector = 1..1
USAGE_vector = <<END_USAGE.split("\n")
(vector <any-expression>)

Returns a vector representation of any value.  Vectors are
passed through unchanged.  Scalars are wrapped in a vector.
END_USAGE



ARITY_boolean = 1..1
USAGE_boolean = <<END_USAGE.split("\n")
(boolean <any-expression>)

Returns a boolean respresentation of any value.  Of scalars,
the empty string (nil), false, and 0 are false.  Of vectors,
the empty list is false.  All other values are true.
END_USAGE



ARITY_integer = 1..1
USAGE_integer = <<END_USAGE.split("\n")
(integer <any-expression>)

....+....1....+....2....+....3....+....4....+....5....+....6....+....7....+....8....+....9....+....A....+....
Returns an integer representation of any value.  Vectors are
reduced to their length.  Non-integer scalars are considered
0.
END_USAGE



class Conversions < Tapestry::Build::Interpreter::Function

   @@instance = Conversions.new()

   def Conversions.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      value = processParameter( callDescriptor, 1, "any-expression", localScope, interpreter )

      results = ""
      case function
       when "scalar"
         results = interpreter.scalarize( value )

       when "vector"
         results = interpreter.vectorize( value )

       when "boolean"
         results = interpreter.booleanize( value )

       when "integer"
         results = interpreter.integerize( value )

      end

      return results

   end

end  # Conversions

Function.addBuiltin( "scalar" , Conversions.getInstance(), ARITY_scalar , USAGE_scalar  )
Function.addBuiltin( "vector" , Conversions.getInstance(), ARITY_vector , USAGE_vector  )
Function.addBuiltin( "boolean", Conversions.getInstance(), ARITY_boolean, USAGE_boolean )
Function.addBuiltin( "integer", Conversions.getInstance(), ARITY_integer, USAGE_integer )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





