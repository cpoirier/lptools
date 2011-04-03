#!/usr/bin/ruby
#
# This class represents a function, and provides the interface to call it.
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

require 'tapestry-packaged/Error.rb'
require 'tapestry-packaged/build/interpreter/Tokenizer.rb'
require 'tapestry-packaged/build/interpreter/Interpreter.rb'


module Tapestry
module Build
module Interpreter

MAXIMUM_ARITY = 1000000

#
# Provides the common machinery need by functors.

class Function

   #
   # The entry point to all functions from the interpreter.  DO NOT OVERRIDE!
   # Override dispatch()! 

   def call( callDescriptor, localScope, interpreter )

      function = callDescriptor[0]
      arity    = callDescriptor.length - 1

      begin
         return dispatch( callDescriptor, localScope, interpreter, function, arity )
      rescue Tapestry::Error
         raise interpreter.augmentError( $!, callDescriptor, function )
      end

   end


   #
   # Each Function must implement dispatch(), but is free to decide for itself:
   #  - whether to use it's callers local scope or replace it with its
   #    own (and when to make the switch)
   #  - how to interpret its parameter tokens

   def dispatch( callDescriptor, localScope, interpreter, function, arity )
      raise NotImplementedError.new( "Function subtype must implement dispatch()" )
   end




   #
   # The process*() functions provide automated type checking and processing.  The following
   # types are supported:
   #   literal            -- must be a scalar containing no variable references
   #   scalar             -- must be a scalar
   #   vector             -- must be a vector
   #   variable-name      -- must be a simple variable name
   #   function-call      -- must be a viable function call descriptor
   #   any                -- whatever is there is returned without any processing
   #   any-expression     -- any token, the interpretation of which will be returned
   #   literal-expression -- any token, the interpretation of which must be a literal
   #   scalar-expression  -- any token, the scalar interpretation of which will be returned
   #   vector-expression  -- any token, the list interpretation of which will be returned

   @@supportedTypes = [ "literal", "scalar", "vector", "variable-name", "function-call", "any"           \
                      , "any-expression", "literal-expression", "scalar-expression", "vector-expression" ]


   #
   # Processes a function call parameter and raises exceptions when problems are found.

   def processParameter( callDescriptor, index, allow, localScope, interpreter, testOnly = false )

      function = callDescriptor[0]
      token    = callDescriptor[index]

      return processToken( token, allow, localScope, interpreter, \
         Function.createParameterError( function, index, "", getUsage(function), token ), testOnly ) 

   end


   #
   # Implements processParameter(), but in a way that it can be used on 
   # any valid token.

   def processToken( token, allow, localScope, interpreter, tagsForError=nil, testOnly=false )

      #
      # Handle the various processing options, as denoted by allow

      processed = nil
      accepted  = false
      results   = nil

      if allow.include?("expression") then
         results = interpreter.interpret( token, localScope ) 
      end


      case allow

       when "literal"
         if interpreter.isLiteral(token) then
            processed = token 
            accepted  = true
         end


       when "scalar"
         if interpreter.isScalar(token) then
            processed = token
            accepted  = true
         end


       when "variable-name"
         name = interpreter.isSimpleVariable(token)
         unless name.nil?
            processed = name
            accepted  = true
         end


       when "vector"
         if interpreter.isVector(token) then
            processed = token 
            accepted  = true
         end


       when "function-call"
         if token.is_a?(Array) and token.length > 0 then
            processed = token 
            accepted  = true
         end


       when "any"
         processed = token
         accepted  = true


       when "any-expression"
         processed = results
         accepted  = true


       when "literal-expression"
         if results.is_a?(String) and interpreter.isLiteral(results) then
            processed = results 
            accepted  = true
         end


       when "scalar-expression"
         if results.is_a?(String) then
            processed = results 
            accepted  = true
         end


       when "vector-expression"
         if results.is_a?(Array) then
            processed = results 
            accepted  = true
         end


       else
         raise ArgumentError.new( "processParameter does not recognize allow phrase: " + allow.to_s )
      end


      #
      # Report the results or the error

      unless accepted or testOnly
         if tagsForError.nil? then
            raise interpreter.createTokenError( "type error", "expected " + allow.to_s, token )
         else
            tagsForError.set( "details", "expected " + allow.to_s + " " + tagsForError.get("details").to_s )
            raise tagsForError
         end
      end

      return processed

   end


   #
   # Calls processParameter() requesting "any-expression", and returns the result
   # as a scalar.

   def processToScalar( callDescriptor, index, localScope, interpreter )
      result = processParameter( callDescriptor, index, "any-expression", localScope, interpreter )
      return interpreter.scalarize( result )
   end


   #
   # Calls processParameter() requesting "any-expression", and returns the result
   # as a vector.

   def processToVector( callDescriptor, index, localScope, interpreter )
      result = processParameter( callDescriptor, index, "any-expression", localScope, interpreter )
      return interpreter.vectorize( result )
   end


   #
   # Calls processToScalar() and returns the result as a boolean.

   def processToBoolean( callDescriptor, index, localScope, interpreter )
      result = processToScalar( callDescriptor, index, localScope, interpreter )
      return interpreter.booleanize( result )
   end


   #
   # Calls processToScalar() and returns the result as an integer.

   def processToInteger( callDescriptor, index, localScope, interpreter )
      result = processToScalar( callDescriptor, index, localScope, interpreter )
      return interpreter.integerize( result )
   end



   #---------------------------------------------------------------------------
   # FUNCTION INFORMATION METHODS


   #
   # Provides the functor with information on its arity and usage, and 
   # returns it in a data structure (hash) for others to use.  This is really
   # constructor stuff, but we do it here to allow singleton functors with
   # multiple names.

   @descriptors = nil   # A hash of hashes.

   def describe( name, arity, usage )

      @descriptors = {} if @descriptors.nil?

      descriptor = {}
      descriptor["name"   ] = name
      descriptor["arity"  ] = arity
      descriptor["usage"  ] = usage
      descriptor["functor"] = self

      @descriptors[name] = descriptor

      return descriptor

   end

   def getUsage( name )
      return @descriptors[name]["usage"]
   end

   def getArity( name )
      return @descriptors[name]["arity"]
   end



   #---------------------------------------------------------------------------
   # ERROR HANDLING AND REPORTING METHODS


   #
   # Generates a parameter related error (ie. type invalid)

   def createParameterError( function, parameter, details, usage, token )
      return Function.createParameterError( function, parameter, details, usage, token )
   end

   def Function.createParameterError( function, parameter, details, usage, token )

      data = {}
      data["details"  ] = details
      data["function" ] = function
      data["parameter"] = parameter
      data["usage"    ] = usage
      data["token"    ] = token

      return Tapestry::Error( "parameter error", data )

   end



   #---------------------------------------------------------------------------
   # FUNCTION REGISTRATION METHODS


   #
   # Function keeps a registry of builtin functions, to minimize code changes
   # when new functions are added.  Simply call Function.addBuiltin() to 
   # register your new function.  Interpreter uses Function.getBuiltins() to 
   # get the set.

   @@builtins = {}

   def Function.addBuiltin( name, functor, arity, usage )
      if @@builtins.member?(name) then
         raise IndexError( "builtin function named [" + name + "] already exists" )
      else
         functor.describe( name, arity, usage )
         @@builtins[name] = functor
      end
   end

   def Function.getBuiltins()
      return @@builtins
   end


end  # Function

end  # Interpreter
end  # Build
end  # Tapestry


require "tapestry-packaged/build/interpreter/functions/manifest.rb"


