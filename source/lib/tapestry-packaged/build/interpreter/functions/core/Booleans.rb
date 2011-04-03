#!/usr/bin/ruby
#
# Functor for:
#    (not <any-expression>)
#    (and <any-expression> <any-expression>)
#    (or  <any-expression> <any-expression>)
#    (xor <any-expression> <any-expression>)
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

ARITY_not = 1..1
USAGE_not = <<END_USAGE.split("\n")
(not <any-expression>)

Converts the expression to a boolean a returns its logical
inverse.

The empty string (nil), the empty list, 0, and false are
treated as false, all other values as true.
END_USAGE





ARITY_or = 2..2
USAGE_or = <<END_USAGE.split("\n")
(or <any-expression> <any-expression>)

Converts the expressions to booleans and returns the logical
or.

The empty string (nil), the empty list, 0, and false are
treated as false, all other values as true.
END_USAGE





ARITY_and = 2..2
USAGE_and = <<END_USAGE.split("\n")
(and <any-expression> <any-expression>)

Converts the expressions to booleans and returns the logical
and.

The empty string (nil), the empty list, 0, and false are
treated as false, all other values as true.
END_USAGE





ARITY_xor = 2..2
USAGE_xor = <<END_USAGE.split("\n")
(xor <any-expression> <any-expression>)

Converts the expressions to booleans and returns the logical
exclusive or.

The empty string (nil), the empty list, 0, and false are
treated as false, all other values as true.
END_USAGE




class Booleans < Tapestry::Build::Interpreter::Function

   @@instance = Booleans.new()

   def Booleans.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      first  = processToBoolean( callDescriptor, 1, localScope, interpreter )
      second = ( arity >= 2 ? processToBoolean( callDescriptor, 2, localScope, interpreter ) : nil )

      if System.verbosity > 4 then
         if arity >= 2 then
            System.puts( "(#{function} #{first} #{second})" )
         else
            System.puts( "(#{function} #{first})" )
         end
      end

      result = false
      case function
       when "not"
         result = (not first)

       when "or"
         result = (first or second)

       when "and"
         result = (first and second)

       when "xor"
         result = (first ^ second)

      end

      return interpreter.scalarize( result )

   end

end  # Booleans

Function.addBuiltin( "not", Booleans.getInstance(), ARITY_not, USAGE_not )
Function.addBuiltin( "or" , Booleans.getInstance(), ARITY_or , USAGE_or  )
Function.addBuiltin( "and", Booleans.getInstance(), ARITY_and, USAGE_and )
Function.addBuiltin( "xor", Booleans.getInstance(), ARITY_xor, USAGE_xor )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





