#!/usr/bin/ruby
#
# Functor for:
#    (each   <variable-name> <any-expression:data source> <any-expression>)
#    (select <variable-name> <any-expression:data source> <any-expression>)
#    (map    <variable-name> <any-expression:data source> <any-expression>)
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

ARITY_each = 3..3
USAGE_each = <<END_USAGE.split("\n")
(each 
   <variable-name> 
   <any-expression:data source> 
   <any-expression:body>
)

Interprets the body for each element in the data source, 
after placing the current value in the named variable.

Returns the result of the last body invocation.

Example
   (set $list (q(a b c)))
   (set $extended (each $item $list ${item}.x)))

      $extended holds c.x
END_USAGE



ARITY_map = 3..3
USAGE_map = <<END_USAGE.split("\n")
(map 
   <variable-name> 
   <any-expression:data source> 
   <any-expression:body>
)

Interprets the body for each element in the data source, 
after placing the current value in the named variable.

Returns the collected results of each body invocation in a
vector.

Example
   (set $list (q(a b c)))
   (set $extended (map $item $list ${item}.x)))

      $extended holds (a.x b.x c.x)
END_USAGE



ARITY_select = 3..3
USAGE_select = <<END_USAGE.split("\n")
(select 
   <variable-name> 
   <any-expression:data source> 
   <any-expression:body>
)

Interprets the body for each element in the data source, 
after placing the current value in the named variable.

Returns the subset of data source for which the invoked body
returns true.

Example
   (select $list (q(x.c y.c example.c))
   (select $results (select $item $list   
                          (not (wildcard $item *example*))))

      $results holds (x.c y.c)
END_USAGE



class Loops < Tapestry::Build::Interpreter::Function

   @@instance = Loops.new()

   def Loops.getInstance()
      return @@instance
   end



   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = []

      variable = processParameter( callDescriptor, 1, "variable-name", localScope, interpreter )
      data     = processToVector( callDescriptor, 2, localScope, interpreter ) 

      data.each do |element|
         localScope.set( variable, element, interpreter.options["def-before-set"] )
         value = processParameter( callDescriptor, 3, "any-expression", localScope, interpreter )

         case function
          when "each"
            results = value

          when "map"
            results.append(value)

          when "select"
            results.append(element) if interpreter.booleanize(value)

         end
      end

      return results

   end

end  # Loops

Function.addBuiltin( "each",    Loops.getInstance(), ARITY_each,   USAGE_each   )
Function.addBuiltin( "map",     Loops.getInstance(), ARITY_map,    USAGE_map    )
Function.addBuiltin( "select" , Loops.getInstance(), ARITY_select, USAGE_select )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





