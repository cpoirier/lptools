#!/usr/bin/ruby
#
# Functor for user defined functions.  
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

ARITY_def_function = 3..4
USAGE_def_function = <<END_USAGE.split("\n")
(def-function 
   <literal-expression:name> 
   <vector:parameters>
   <function-call:code> 
   [<any-expression:usage>]
)

Defines a new function with the specified name.  Each 
element of the parameter list must have the form $name
or $name:type.  

For the following types, tokens are not interpreted:
   literal       - a scalar containing no variables
   scalar        - a scalar
   variable-name - a variable name, including the $ sign
   vector        - a vector
   function-call - a vector with at least one element
   any           - any token

For the following types, tokens are interpreted in the 
caller's context before validation:
   literal-expression - a scalar containing no variables
   scalar-expression  - any scalar
   vector-expression  - any vector
   any-expression     - any of the above expressions

If you do not include a type, any-expression is used.

If usage is supplied, it will be included in any errors 
generated when the function is called.

Returns the new function name.


Example
   (def-function cat ($file:literal-expression)
      (system cat $file)
      (l "(cat literal-expression:file)"
         ""
         "Echos out the named file." ) )
END_USAGE



      
class UserDefined < Tapestry::Build::Interpreter::Function 

   @@instance = UserDefined.new()   # Provides deffun
   def UserDefined.getInstance()
      return @@instance
   end

   #
   # If called as deffun, we create a new UserDefined function.  Otherwise,
   # we process an existing UserDefined function.

   def dispatch( callDescriptor, localScope, interpreter, function, arity )

      results = ""
      if function == "def-function" then
         results = handleDefine( callDescriptor, localScope, interpreter, function, arity )
      else
         results = handleCall( callDescriptor, localScope, interpreter, function, arity )
      end

      return results

   end


   #
   # These instance variables are used to create user defined functions.

   @inputs     = nil   # A list of variable names for the parameters
   @inputTypes = nil   # A list of the types for the parameters
   @code       = nil   # A function token to be executed

   def initialize( name, inputs, inputTypes, code, usage=nil )

      arity       = inputs.length
      @inputs     = inputs
      @inputTypes = inputTypes
      @code       = code

      describe( name, arity, usage )

   end


   #
   # Processes a call to a user defined function

   def handleCall( callDescriptor, callersLocalScope, interpreter, function, arity )

      results = ""

      #
      # Create a new variable scope and fill in the input parameters

      localScope = Tapestry::Build::Interpreter::NameScope.new()
      @inputs.each_index do |index|
         name = @inputs[index]
         type = @inputTypes[index]

         value = processParameter( callDescriptor, index + 1, type, callersLocalScope, interpreter )
         localScope.set( name, value, false )
      end


      #
      # Then, run the function code and return the results

      results = interpreter.interpret( @code, localScope )
      return results
   
   end


   #
   # Processes a (def-function) call to produce a new user defined function.

   def handleDefine( callDescriptor, localScope, interpreter, function, arity )

      nameToDefine = processParameter( callDescriptor, 1, "literal-expression", localScope, interpreter )

#
# We are ditching this constaint, for a trial period, at least.
#
#      if interpreter.functorDefined?(nameToDefine) then
#         raise interpreter.createFunctionError( "function already defined", callDescriptor, "runtime error" )
#      end


      parameters = processParameter( callDescriptor, 2, "vector" , localScope, interpreter )
      code       = processParameter( callDescriptor, 3, "function-call"     , localScope, interpreter )

      usage = nil
      if arity == 4 then
         usage = processToVector( callDescriptor, 4, localScope, interpreter )
      end


      #
      # First, process the parameter list.  Each parameter must be in the form
      # $name:type, and we will use process() to validate each.

      inputs     = []
      inputTypes = []

      error = createParameterError( function, 2, "", getUsage(function), callDescriptor[2] )

      parameters.each_index do |index|
         error.set( "subparameter", index+1 )

         descriptor = processToken( parameters[index], "scalar", localScope, interpreter, error )

         name = ""
         type = "any-expression"
         if descriptor.include?(":") then
            (namepart, typepart) = descriptor.split( /:/, 2 )
            name = processToken( namepart, "variable-name", localScope, interpreter, error )
            type = processToken( typepart, "literal"      , localScope, interpreter, error )
         else
            name = processToken( descriptor, "variable-name", localScope, interpreter, error )
         end

         unless @@supportedTypes.member?(type)
            error.set( "details", "invalid type: " + type.to_s )
            raise error
         end

         inputs.append( name )
         inputTypes.append( type )
      end


      #
      # Finally, create the new UDF and register it with the interpreter

      functor = UserDefined.new( nameToDefine, inputs, inputTypes, code, usage )
      interpreter.registerFunctor( nameToDefine, functor )

      return nameToDefine

   end


end  # UserDefined

Function.addBuiltin( "def-function", UserDefined.getInstance(), ARITY_def_function, USAGE_def_function )


end  # Functions
end  # Interpreter
end  # Build
end  # Tapestry





