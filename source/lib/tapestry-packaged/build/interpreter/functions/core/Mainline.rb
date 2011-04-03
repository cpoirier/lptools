#!/usr/bin/ruby
#
# Functor for:
#    (do      <any-expression> [<any-expression>...])
#    (collect <any-expression> [<any-expression>...])
#    (l       <any-expression> [<any-expression>...])
#    (return  <any-expression>)
#    (include <literal-expression:path>)
#    (abort   [<literal-expression:message>] [<integer-expression:rc>])
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

ARITY_do = 0..MAXIMUM_ARITY
USAGE_do = <<END_USAGE.split("\n")
(do <function-call> [<function-call>...])

Interprets each function call, in order, and returns the 
results of the last expression.  Operates in the caller's
local variable scope.

Example
   (set $data 
      (do
         (set $x (random))
         (set $y (random))
         (if (gt $x $y) greater less)
      )
   )
   (print $x $y)

    - sets $data to "greater" or "less", depending on some
      random value
    - note that $x and $y exist in the caller's scope


------------------------------------------------------------
(do <variable-name:vector>)

Obtains the list held in the variable and interprets it as
a function call.  Returns the result.  The function is 
called in the current local variable scope.

Example
   (set $code (q(echo hello world)))
   (do $code)


------------------------------------------------------------
(do)

Effectively a no-op.  Including for completeness.
END_USAGE




ARITY_collect = 1..MAXIMUM_ARITY
USAGE_collect = <<END_USAGE.split("\n")
(collect <any-expression> [<any-expression>])
(l       <any-expression> [<any-expression>])

Returns a vector containing the results of each expression.

Example
   (set $x hello)
   (set $y there)
   (set $list (collect $x $y))

      - $list contains (hello there)
END_USAGE




ARITY_include = 1..MAXIMUM_ARITY
USAGE_include = <<END_USAGE.split("\n")
(include do|collect|l|return <literal-expression:path>)

Loads code from the specified path and executes it as if
it had been supplied directly, as arguments to the 
specified function.  See the particular surrogate functions
for expectations and restrictions.

Author's note: this seems clumsy because it is.  (include) 
should just expand in place and allow the calling scope to 
handle it like normal code.  Unfortunately, the design of
the interpreter won't allow this, and, at this time, it's
just not worth redesigning.  I apologize for any problems 
this causes you.  If you want to contribute a rewrite of
the interpreter, let me know...


Example
   (include do      ~/rules)
   (include collect ~/rules)
   (include l       ~/rules)
   (include return  ~/rules)
END_USAGE




ARITY_return = 1..1
USAGE_return = <<END_USAGE.split("\n")
(return <any-expression>)

Interprets the expression and returns the result.

Example
   (set $x name)
   (set $result
      (do
         (set $y ${x}.o)
         (return $y)
      )
   )

      - $result holds name.o
END_USAGE



ARITY_abort = 0..2
USAGE_abort = <<END_USAGE.split("\n")
(abort 
   [<literal-expression:message>] 
   [<integer-expression:rc>]
)

Aborts build with, including any supplied message and 
return code with the fatal exception.

Example
   (abort "bad things happened", 20)
END_USAGE







class Mainline < Tapestry::Build::Interpreter::Function

   @@instance = Mainline.new()

   def Mainline.getInstance()
      return @@instance
   end


   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""
      if function == "return" then
         results = handleReturn( callDescriptor, localScope, interpreter )

      elsif function == "collect" or function == "l" then
         results = handleCollect( callDescriptor, localScope, interpreter, arity )

      elsif function == "do" then

         #
         # If the arity is 1, we test to see if the parameter is a variable name.
         # If it is, we use the interpretive do.  Otherwise, we run the regular do.

         if arity == 1 and processParameter( callDescriptor, 1, "variable-name", localScope, interpreter, true ) then
            results = handleInterpretiveDo( callDescriptor, localScope, interpreter )

         else
            results = handleRegularDo( callDescriptor, localScope, interpreter, arity )
         end

      elsif function == "include" then
         results = handleInclude( callDescriptor, localScope, interpreter, function )


      elsif function == "abort" then
         results = handleAbort( callDescriptor, localScope, interpreter, arity )

      end

      return results

   end

   #
   # In the regular do form, we ask processParameter to enforce our rule that
   # all parameters must be function calls.  We then process the call and
   # return the results.

   def handleRegularDo( callDescriptor, localScope, interpreter, arity )

      results = ""
      (1..arity).each do |index|

                   processParameter( callDescriptor, index, "function-call",  localScope, interpreter )
         results = processParameter( callDescriptor, index, "any-expression", localScope, interpreter )
            
      end

      return results

   end


   #
   # return simply returns the results of its only parameter

   def handleReturn( callDescriptor, localScope, interpreter )
      return processParameter( callDescriptor, 1, "any-expression", localScope, interpreter )
   end


   #
   # return an array of results from the parameters

   def handleCollect( callDescriptor, localScope, interpreter, arity )

      results = []
      (1..arity).each do |index|
         results.append( processParameter( callDescriptor, index, "any-expression", localScope, interpreter ))
      end

      return results

   end


   #
   # The interpretive do obtains a vector from a variable and interprets it
   # as a function call.  The results are returned.  An exception is raised
   # if the variable does not contain a list.

   def handleInterpretiveDo( callDescriptor, localScope, interpreter )

      suppliedCallDescriptor = processParameter( callDescriptor, 1, "vector-expression", localScope, interpreter )
      return interpreter.interpret( suppliedCallDescriptor, localScope )

   end


   #
   # Tokenizes the specified file and passes it to the appropriate routine
   # for processing.

   @@includeStyles = [ "do", "collect", "l", "return" ]
   
   def handleInclude( callDescriptor, localScope, interpreter, function )

      handler = processToScalar( callDescriptor, 1, localScope, interpreter )
      unless @@includeStyles.member?(handler) 
         error = "include must use one of the mainline functions: #{@@includeStyles.join(", ")}"
         raise createParameterError( function, 1, error, getUsage(function), callDescriptor[1] )
      end


      #
      # Load and tokenize the file

      filename = interpreter.zone.offsetHome( processToScalar(callDescriptor, 2, localScope, interpreter) )
      begin
         file   = File.open( filename )
         tokens = interpreter.tokenizer.process( file, filename )
         tokens.prepend( interpreter.tokenizer.createStringToken(handler, callDescriptor.file, callDescriptor.line, callDescriptor.position))
         interpreter.stripComments( tokens ) 

      rescue SystemCallError
         interpreter.zone.raise_instructionsFileError( filename, callDescriptor )
      ensure
         file.close unless file.nil?
      end


      #
      # If we are still here, pass the token off for processing.

      return interpreter.interpret( tokens, localScope )

   end


   #
   # Aborts the system.

   def handleAbort( callDescriptor, localScope, interpreter, arity )

      message = nil
      if arity > 0 then
         message = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )
      end

      rc = 10
      if arity > 1 then
         rc = processToInteger( callDescriptor, 2, localScope, interpreter )
      end

      error = Tapestry::Error( "abort", { "details", message, "token", nil } )
      error.rc = rc

      raise error

   end


end  # Mainline

Function.addBuiltin( "do"     , Mainline.getInstance(), ARITY_do     , USAGE_do      )
Function.addBuiltin( "collect", Mainline.getInstance(), ARITY_collect, USAGE_collect )
Function.addBuiltin( "l",       Mainline.getInstance(), ARITY_collect, USAGE_collect )
Function.addBuiltin( "return" , Mainline.getInstance(), ARITY_return , USAGE_return  )
Function.addBuiltin( "include", Mainline.getInstance(), ARITY_include, USAGE_include )
Function.addBuiltin( "abort"  , Mainline.getInstance(), ARITY_abort  , USAGE_abort   )

end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





