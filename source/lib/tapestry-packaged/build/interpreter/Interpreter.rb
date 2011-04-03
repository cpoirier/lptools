#!/usr/bin/ruby
#
# Processes the build command language.
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

require "tapestry-packaged/Error.rb"
require "tapestry-packaged/build/interpreter/Tokenizer.rb"
require "tapestry-packaged/build/interpreter/NameScope.rb"
require "tapestry-packaged/build/interpreter/Function.rb"

module Tapestry
module Build
module Interpreter


#
# Each Zone loads its Buildfile and passes the contents to this Interpreter to
# have it processed.  The Zone holds the core data structures the program will
# manipulate.

class Interpreter

   @@tokenizer = Tapestry::Build::Interpreter::Tokenizer.new()
   @@builtins  = Tapestry::Build::Interpreter::Function.getBuiltins()

   def tokenizer()
      return @@tokenizer
   end



   # ----------------------------------------------------------------------
   # The interpreter holds its tokenized instructions, and various language
   # level objects that will be created in response to those instructions.

   @zone         = nil     # The Zone on whose behalf we are running
   @instructions = nil     # The raw tokenized Buildfile program
   @run          = false   # Set true once the @instructions have been run 
   @globals      = nil     # The global variable name scope
   @functors     = nil     # Function objects, held in a name scope

   attr_reader :zone, :globals, :functors

   @options      = nil     # User controllable options
   attr_reader :options


   #
   # You must associate the Interpreter with its Zone, as the Zone holds the data
   # structures the Interpreter manipulates.  The stream has to support each_byte().

   def initialize( zone, stream, file = nil, globals = nil )

      @zone = zone
      @run  = false

      #
      # Tokenize the instructions, wrapping them in the implicit "do"

      @instructions = @@tokenizer.process( stream, file )
      @instructions.prepend( @@tokenizer.createStringToken("do", "", 0, 0) )
      stripComments(@instructions)


      #
      # We initialize globals from the environment, or a supplied NameScope

      @globals = NameScope.new()
      hash = ( globals.nil? ? ENV : globals.to_h )
      hash.keys.each do |key|
         @globals.define( key.clone, hash[key].clone )
      end


      #
      # We initialize the function list from the builtins

      @functors = NameScope.new()
      @@builtins.keys.each do |name|
         registerFunctor( name, @@builtins[name] )
      end


      #
      # And finally, initialize the options

      @options = { "def-before-set"        => false \
                 , "print-separator"       => " "   \
                 , "print-terminator"      => "\n"  \
                 , "report"                => true  \
                 , "report-def-production" => true  \
                 , "report-def-analyzer"   => true  \
                 , "report-def-action"     => true  }

   end



   #---------------------------------------------------------------------------
   # INTERPRETER CONTROL METHODS


   #
   # Executes the script.  The script is declarative, not procedural.  When this
   # method returns, all the declarations will have been processed.  Language 
   # declarations are held internally.  System declarations (productions, analyzers,
   # actions, nodes) are passed to the Zone for handling.  The Zone may immediately
   # call back into the Program in response to such an addition, temporarily 
   # pre-empting the mainline of the program.

   def run()
      interpret( @instructions )
      @run = true
   end

   def run?()
      return @run
   end


   #
   # Interprets the specified token, and returns the results, as follows:
   #   - function call => call()   => returned data
   #   - variable      => expand() => variable value
   #   - literal       => expand() => itself

   def interpret( token, localScope = nil )
      results = nil 

      localScope = @globals if localScope.nil?

      if token.is_a?(Array) then
         results = call( token, localScope )
      elsif token.is_a?(String) then
         results = expand( token, localScope )
      else
         raise ArgumentError.new( "unknown token type: " + token.class.name )
      end

      return results
   end



   #---------------------------------------------------------------------------
   # FUNCTION HANDLING METHODS


   #
   # Processes a single function call, as described by a SetToken.
   # Returns the results produced by the function call.
   # Program.call() is mutually recursive with Function.call()

   def call( token, localScope = @globals )

      #
      # A function call descriptor is always an array...

      unless token.is_a?(Array) 
         raise createTokenError( "syntax error", "expected function call", token )
      end


      #
      # Next, we get the function name, or raise an exception

      unless token.length > 0 then
         raise createTokenError( "syntax error", "function call empty", token )
      end

      name = token[0]


      #
      # Get the named functor, or raise an exception

      unless functorDefined?(name)
         raise createFunctionError( "undefined function", token, "runtime error" )
      end

      functor = getFunctor(name)


      #
      # Next, verify the arity, or raise an exception

      arity = token.length - 1
      arityRange = functor.getArity(name)
      unless arityRange === arity
         raise createFunctionError( "invalid parameter count", token )
      end


      #
      # Finally, we call the functor and return the results

      return functor.call( token, localScope, self )

   end



   #---------------------------------------------------------------------------
   # VARIABLE HANDLING METHODS


   #
   # expand() takes a String and a variable scope and expands all
   # the variable references.  Escaped variable references are left untouched.
   # Variables can take one of two forms: $name or ${name}.  There may be more
   # than one variable embedded in any token.  Substitutions that expand to
   # lists will result in a list of expanded strings, one to each value.  
   # Multiple substitutions involving lists will produce a cross-product of
   # expanded strings.

   @@variablePattern       = /(?:(?:^|[^\\])(\$[{]?(\w[\w-]*)[}]?))/
   @@simpleVariablePattern = /^\$[{]?(\w[\w-]*)[}]?$/

   def expand( string, localScope = nil )

      finished   = []

      if m = @@simpleVariablePattern.match(string) then
        name = m[1]
        finished.append( getVariable( name, localScope ) )

      else
            
         #
         # We process the [[unfinished]] array, one string at a time.  We check
         # each string for a variable reference, and, after substituting its
         # value, place the string back on the [[unfinished]] array for another
         # pass.  If the variable expands to a list, multiple strings will be
         # created and placed back onto [[unfinished]].  When no variable 
         # reference is found in a string, it is moved to the [[finished]] list.
   
         unfinished = [string.dup]  # We use dup, not clone, because we no longer need the Token part
   
         until unfinished.empty?
            element = unfinished.shift()
   
            if m = @@variablePattern.match(element) then
               name = m[2]
               variableValue = getVariable( name, localScope )
   
               if variableValue.is_a?(Array) then
                  values = variableValue.flatten
                  values.each do |value|
                     copy = element.clone
                     copy[m.begin(1)..m.end(1)-1] = escape(value.to_s)
                     unfinished.append( copy )
                  end
               else
                  element[m.begin(1)..m.end(1)-1] = escape(variableValue.to_s)
                  unfinished.append( element )
               end
            else
               finished.append( unescape(element) )
            end
         end
      end
   
      if finished.length > 1 then
         return finished
      else
         return finished[0]
      end
   
   end


   #
   # The $ sign that marks a variable can be escaped with a backslash.  This
   # would typically be done if it was necessary to pass a $ sign to an 
   # external command.  Before doing so, however, the backslash must be 
   # removed.  These methods add and remove slashes appropriately.

   @@escapePattern = /[\\$]/
   def escape( string )
      escaped = string.gsub( @@escapePattern ) do |match|
         match = "\\" + match
      end
      return escaped
   end

   @@unescapePattern = /[\\][\\$]/
   def unescape( string )
      unescaped = string.gsub( @@unescapePattern ) do |match|
         match = chr(match[1])
      end
      return unescaped
   end


   #
   # Gets the value of a variable, with fallback to the global scope, if
   # necessary.

   def getVariable( name, localScope=nil )
      found = false
      value = nil

      unless localScope.nil?
         if localScope.defined?(name) then
            value = localScope.get(name)
            found = true
         end
      end

      unless found
         value = @globals.get(name)
      end

      return value
   end

   def getGlobals()
      return @globals
   end

   

   #---------------------------------------------------------------------------
   # TYPE IDENTIFICATION METHODS


   #
   # Returns true if the token is a vector

   def isVector( token )
      return token.is_a?(Array)
   end


   #
   # Returns true if the token is a scalar

   def isScalar( token )
      return token.is_a?(String)
   end


   #
   # If the token is a simple variable name, returns the name.  Otherwise
   # returns nil.  

   def isSimpleVariable( token )

      name = nil
      if token.is_a?(String) and (m = @@simpleVariablePattern.match(token)) then
         name = m[1]
      end

      return name

   end


   #
   # This method returns true iff the string contains no variable references.

   def isLiteral( token )

      literal = false
      if token.is_a?(String) and not @@variablePattern.match(token) then
         literal = true
      end

      return literal

   end


   #
   # This method returns true iff the string contains wildcard characters

   def isWildcard( token, count=Wildcard.count(token) )
      return (isLiteral(token) and count > 0)
   end


   # 
   # This method returns true iff the string contains one wildcard, a
   # * at the beginning.

   def isSimpleWildcard( token, count=Wildcard.count(token) )
      return (isLiteral(token) and count == 1 and token[0].chr == "*")
   end



   #---------------------------------------------------------------------------
   # RUNTIME SYSTEM TYPE CONVERSIONS


   #
   # Reduces a result to a boolean.  The empty list, the empty string,
   # "false", "0", and Ruby's nil are false.  All others are true.

   FALSE_STRINGS = [ "", "false", "0" ]
   def booleanize( result )

      boolean = true
      if result.is_a?(Array) then
         boolean = false if result.empty?
      else
         boolean = false if FALSE_STRINGS.member?(result.to_s)
      end

      return boolean

   end


   #
   # Reduces a result to an integer.  Lists are reduced to their lengths,
   # Strings to an integer representation (default 0).

   def integerize( result )

      integer = 0
      if result.is_a?(Array) then
         integer = result.length
      else
         integer = result.to_s.to_i
      end

      return integer

   end


   #
   # Converts a Ruby data type to a scalar literal.

   def scalarize( value )

      scalar = ""
      if value.is_a?(TrueClass) then
         scalar = "true"

      elsif value.is_a?(FalseClass) then
         scalar = "false"

      elsif value.is_a?(Integer) then
         scalar = value.to_s

      elsif value.is_a?(String) then
         scalar = value

      elsif value.is_a?(Array) then
         scalar = value.length.to_s

      end

      return scalar

   end


   #
   # Converts a Ruby data type to a list.

   def vectorize( value )

      vector = []
      if value.is_a?(TrueClass) then
         vector = [ "true" ]

      elsif value.is_a?(FalseClass) then
         vector = []

      elsif value.is_a?(String) then
         if booleanize(value) then
            vector = [ value ]
         else
            vector = []
         end

      elsif value.is_a?(Array) then
         vector = value

      end

      return vector

   end



   #---------------------------------------------------------------------------
   # SUPPORT METHODS


   #
   # Strips comments from the tokens, so that arity rules work.  Works 
   # inside the supplied token, which relies on the whole system being
   # enclosed in a (do).
   #
   # Note: this has a bug.  (q(-- test)) probably shouldn't have its 
   # comment stripped.

   def stripComments( token )

      if token.is_a?(Array) then
         token.delete_if do |element|
            element.kind_of?(Array) and element.length > 0 and element[0] == "--"
         end

         token.each do |element|
            stripComments(element) if element.kind_of?(Array)
         end
      end

   end


   #
   # Returns the functor for the specified name.  Test with
   # functorDefined? first, or you get an undetailed Error exception.

   def getFunctor( name )

      functor = nil
      functor = @functors.get(name) if functorDefined?(name)

      return functor

   end


   #
   # Tests if the named functor already exists

   def functorDefined?( name )
      return @functors.defined?(name)
   end


   #
   # Registers a new functor.  Test with functorDefined?
   # first, or you get an undetailed Error exception.

   def registerFunctor( name, functor )
      @functors.set( name, functor, false )
#
# TEST NOTE: we are allowing function overriding, for now...
#      @functors.define( name, functor )

   end


   #
   # Returns the usage for the named functor, or nil

   def getUsage( name )

      usage = nil
      if functorDefined?( name ) then
         usage = getFunctor(name).getUsage( name )
      end

      return usage

   end



   #---------------------------------------------------------------------------
   # ERROR HANDLING METHODS


   #
   # Generates a function related error (ie. invalid arity).

   def createFunctionError( details, callDescriptor, error="syntax error" )

      function = callDescriptor[0]

      data = {}
      data["details" ] = details
      data["function"] = function
      data["usage"   ] = getUsage(function)
      data["token"   ] = callDescriptor

      return Tapestry::Error( error, data )

   end


   #
   # Generates a general token error 

   def createTokenError( error, details, token, usageFor=nil )

      usage = getUsage( usageFor )

      data = {}
      data["details"] = details
      data["token"  ] = token
      data["usage"  ] = usage unless usage.nil?

      return Tapestry::Error( error, data )

   end


   #
   # Adds token information to an existing tags object, if missing

   def augmentError( error, token, usageFor=nil )

      usage = getUsage( usageFor )

      unless error.member?("token")
         error.set( "token", token )
         error.set( "usage", usage ) unless usage.nil?
      end

      return error

   end


   

   #---------------------------------------------------------------------------
   # METHOD OVERRIDES


   def to_s()
      return @instructions.to_s()
   end



end  # Interpreter



end  # Interpreter
end  # Build
end  # Tapestry




#
# Test the Program, if invoked directly.

if $0 == __FILE__

   program = Tapestry::Build::Interpreter::Interpreter.new( nil, File.open(ARGV[0]) )
   puts( program )

end


