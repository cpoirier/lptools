#!/usr/bin/ruby
#
# Functor for:
#    (set        <variable-name> <any-expression>)
#    (set-global <variable-name> <any-expression>)
#    (def        <variable-name>)
#    (def-global <variable-name>)
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

USAGE_COMMON_set = <<END_USAGE.split("\n")

Sets the named variable to the value of the expression.  
Returns the value assigned.  If (option def-before-set) is
on, the named variable must be defined before it is set.
END_USAGE



ARITY_set = 2..2
USAGE_set = [ "(set <variable-name> <any-expression>)" ] + USAGE_COMMON_set

ARITY_set_global = 2..2
USAGE_set_global = [ "(set-global <variable-name> <any-expression>)" ] + USAGE_COMMON_set





USAGE_COMMON_def = <<END_USAGE.split("\n")

Defines the named variable, and returns (nil).  If 
(option def-before-set) is on, variables must be defined 
before being used.
END_USAGE



ARITY_def = 1..1
USAGE_def = [ "(def <variable-name>)" ] + USAGE_COMMON_def

ARITY_def_global = 1..1
USAGE_def_global = [ "(def-global <variable-name>" ] + USAGE_COMMON_def





class Variables < Tapestry::Build::Interpreter::Function

   @@instance = Variables.new()

   def Variables.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""

      case function
       when "set"
         results = handleSet( callDescriptor, localScope,             localScope, interpreter )

       when "set-global"
         results = handleSet( callDescriptor, interpreter.getGlobals, localScope, interpreter )

       when "def"
         results = handleDef( callDescriptor, localScope,             localScope, interpreter )

       when "def-global"
         results = handleDef( callDescriptor, interpreter.getGlobals, localScope, interpreter )

      end

      return results

   end


   def handleSet( callDescriptor, nameScope, localScope, interpreter )

      name  = processParameter( callDescriptor, 1, "variable-name", localScope, interpreter )
      value = processParameter( callDescriptor, 2, "any-expression", localScope, interpreter )

      nameScope.set( name, value, interpreter.options["def-before-set"] )
      return value

   end


   def handleDef( callDescriptor, nameScope, localScope, interpreter )

      name = processParameter( callDescriptor, 1, "variable-name", localScope, interpreter )
      nameScope.define( name, "", interpreter.options["def-before-set"] )
      return ""

   end

end  # Variables

Function.addBuiltin( "set"       , Variables.getInstance(), ARITY_set,        USAGE_set        )
Function.addBuiltin( "set-global", Variables.getInstance(), ARITY_set_global, USAGE_set_global )
Function.addBuiltin( "def"       , Variables.getInstance(), ARITY_def,        USAGE_def        )
Function.addBuiltin( "def-global", Variables.getInstance(), ARITY_def_global, USAGE_def_global )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





