#!/usr/bin/ruby
#
# Functor for:
#    (interpreter-test)
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

ARITY_interpreter_test = 0..0
USAGE_interpreter_test = <<END_USAGE.split("\n")
(interpreter-test)

Outputs interpreter information.
END_USAGE



class InterpreterTest < Tapestry::Build::Interpreter::Function

   @@instance = InterpreterTest.new()

   def InterpreterTest.getInstance()
      return @@instance
   end

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      globals = interpreter.getGlobals()
      scope   = (localScope == globals ? "global" : "local")

      puts( "-" * 60 )
      puts( PRODUCT + " " + VERSION )
      puts( " | (interpreter-test) invoked in " + scope + " scope" )
      puts( " | command interpreter operating correctly" )
      puts( " | " )

      if scope == "local" then
         puts( " +- local variables " )
         displayVariables( localScope, " |  +- " )
         puts( " | " )
      end

      puts( " +- global variables " )
      displayVariables( globals )

      return ""
   end


   #
   # Pretty prints the variables in the specified NameScope

   def displayVariables( scope, indent = "    +- " )

      names = scope.names().sort()

      longest = 0
      names.each do |name|
         longest = name.length if name.length > longest
      end

      names.each do |name|
         puts( indent + name.ljust(longest) + "=[" + scope.get(name).to_s() + "]" )
      end

   end

end  # InterpreterTest

Function.addBuiltin( "interpreter-test", InterpreterTest.getInstance(), ARITY_interpreter_test, USAGE_interpreter_test )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry

