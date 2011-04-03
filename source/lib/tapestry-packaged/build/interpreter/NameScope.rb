#!/usr/bin/ruby
#
# Encapsulates a Hash to provide name management for the language.
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

module Tapestry
module Build
module Interpreter


#
# The interpreter arranges its variables into scopes.  VariableScope provides 
# the storage and name lookup facilities for accessing variables.  

class NameScope

   @hash = nil             # A hash of name/value pairs
   @requireDefine = false  # If true, you must define variables before using them

   def initialize( requireDefine = false )
      @hash = Hash.new()
      @requireDefine = requireDefine
   end


   #
   # Creates the name and sets its value.  If definition is not required,
   # define() is equivalent to set().  requireDefine set to true or false
   # overrides the default behaviour.

   def define( name, value, requireDefine=@requireDefine )

      if not requireDefine then
         set( name, value, requireDefine )
      else
         if self.defined?(name) then
            raise Tapestry::Error( "runtime error", \
               { "details" => "variable redefinition attempted" \
               , "name"    => name                              } )
         else
            @hash[name] = value
         end
      end

   end


   #
   # Returns true if the named variable is in this scope.

   def defined?( name )
      return @hash.member?(name)
   end


   #
   # Returns the value for the name, or raises Error.  If definition is
   # not required, and the name is not in use, "" is returned.

   def get( name, requireDefine=@requireDefine, default="" )

      if self.defined?(name) then
         return @hash[name]
      else
         if requireDefine then
            raise Tapestry::Error( "runtime error", \
               { "details" => "variable undefined" \
               , "name"    => name                 } )
         else
            return default
         end
      end

   end


   #
   # Sets the value for the named entry.  The name must already exist if
   # definition is required.  Raises Error otherwise.

   def set( name, value, requireDefine=@requireDefine )

      if (not requireDefine) or self.defined?(name) then
         @hash[name] = value
      else
         raise Tapestry::Error( "runtime error", \
            { "details" => "variable undefined" \
            , "name"    => name                 } )
      end

   end


   #
   # Provides the list of names defined in this scope

   def names()
      return @hash.keys
   end


   def to_s()
      return @hash.to_s()
   end

   def to_h()
      return @hash
   end


end  # NameScope



end  # Interpreter
end  # Build
end  # Tapestry




#
# Test the NameScope, if invoked directly.

if $0 == __FILE__

   scope = Tapestry::Build::Interpreter::NameScope.new( )
   puts( "defining x=1: " + scope.define("x", "1").to_s() )
   puts( "defining y=2: " + scope.define("y", "2").to_s() )
   puts( "is defined x? " + scope.defined?("x").to_s()    )
   puts( "is defined y? " + scope.defined?("y").to_s()    )
   puts( "is defined z? " + scope.defined?("z").to_s()    )
   puts( "setting x=3:  " + scope.set("x", "3").to_s()    )

   begin
      puts( "setting z=4:  " + scope.set("z", "4").to_s()    )
   rescue Tapestry::Error
      puts( "setting z=4 raised an exception" )
   end

   puts( "getting x:    " + scope.get("x").to_s()         )
   puts( "getting y:    " + scope.get("y").to_s()         )

   begin
      puts( "getting z:    " + scope.get("z").to_s()         )
   rescue Tapestry::Error
      puts( "setting z=4 raised an exception" )
   end


end


