#!/usr/bin/ruby
#
# Functor for:
#    (scalar? <any-expression>)
#    (vector? <any-expression>)
#    (eq? <any-expression> <any-expression>)
#    (gt? <any-expression> <any-expression>)
#    (lt? <any-expression> <any-expression>)
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

ARITY_scalar_ = 1..1
USAGE_scalar_ = <<END_USAGE.split("\n")
(scalar? <any-expression>)

Returns a boolean indicating if the expression is a scalar.
END_USAGE




ARITY_vector_ = 1..1
USAGE_vector_ = <<END_USAGE.split("\n")
(vector? <any-expression>)

Returns a boolean indicating if the expression is a vector.
END_USAGE




ARITY_eq_ = 2..2
USAGE_eq_ = <<END_USAGE.split("\n")
(eq? <any-expression> <any-expression>)

Returns a boolean indicating if the two expression have the
same value.
END_USAGE




ARITY_gt_ = 2..2
USAGE_gt_ = <<END_USAGE.split("\n")
(gt? <any-expression> <any-expression>)

Returns a boolean indicating if the first expression's 
integer value is greater than the second's.
END_USAGE




ARITY_lt_ = 2..2
USAGE_lt_ = <<END_USAGE.split("\n")
(lt? <any-expression> <any-expression>)

Returns a boolean indicating if the first expression's
integer value is less than the second's.
END_USAGE




class Tests < Tapestry::Build::Interpreter::Function

   @@instance = Tests.new()

   def Tests.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      result = false

      case function
       when "scalar?", "vector?"
         result = handleTypeTest( callDescriptor, localScope, interpreter, function )

       when "eq?", "gt?", "lt?"
         result = handleComparison( callDescriptor, localScope, interpreter, function )

      end

      return interpreter.scalarize( result )

   end


   def handleTypeTest( callDescriptor, localScope, interpreter, function )

      result = false
      value  = processParameter( callDescriptor, 1, "any-expression", localScope, interpreter )

      case function
       when "scalar?"
         result = interpreter.isScalar( value )

       when "vector?"
         result = interpreter.isVector( value )

      end

      return result

   end



   def handleComparison( callDescriptor, localScope, interpreter, function )

      result = false
      first  = processParameter( callDescriptor, 1, "any-expression", localScope, interpreter )
      second = processParameter( callDescriptor, 2, "any-expression", localScope, interpreter )

      case function
       when "eq?"
         result = (first == second)

       when "gt?"
         result = (interpreter.integerize(first) > interpreter.integerize(second))

       when "lt?"
         result = (interpreter.integerize(first) < interpreter.integerize(second))

      end

      return result

   end



end  # Tests

Function.addBuiltin( "scalar?", Tests.getInstance(), ARITY_scalar_, USAGE_scalar_ )
Function.addBuiltin( "vector?", Tests.getInstance(), ARITY_vector_, USAGE_vector_ )
Function.addBuiltin( "eq?"    , Tests.getInstance(), ARITY_eq_    , USAGE_eq_     )
Function.addBuiltin( "gt?"    , Tests.getInstance(), ARITY_gt_    , USAGE_gt_     )
Function.addBuiltin( "lt?"    , Tests.getInstance(), ARITY_lt_    , USAGE_lt_     )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





